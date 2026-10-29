// SPDX-License-Identifier: GPL-2.0-only
#include "display.hpp"
#include <algorithm>
#include <array>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <dlfcn.h>
#include <fcntl.h>
#include <iostream>
#include <stdexcept>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

namespace display {
namespace {
using Clock = std::chrono::steady_clock;
constexpr uint8_t up=0xad, down=0xaf, left=0xac, right=0xae, fire=0xa3, use=0xa2;
void dimensions(const uint32_t* p, int w, int h) {
    if (!p || w<=0 || h<=0 || w>8192 || h>8192) throw std::runtime_error("Invalid framebuffer dimensions");
}
class Headless final : public Backend {
public:
    void present(const uint32_t* p,int w,int h) override { dimensions(p,w,h); }
    std::vector<KeyEvent> poll() override { return {}; }
    bool closed() const override { return false; }
};
class Terminal final : public Backend {
    termios saved{};
    bool stop=false;
    std::array<Clock::time_point,256> until{};
    std::array<bool,256> held{};
    std::string pending;
    std::string hud="WASD/arrows move; space fires; E uses; Enter/Esc menus; Q quits";
    Clock::time_point last{}, escape_since{};
public:
    Terminal() {
        if (!isatty(STDIN_FILENO)||!isatty(STDOUT_FILENO))
            throw std::runtime_error("Terminal display needs a TTY on stdin and stdout");
        if (tcgetattr(STDIN_FILENO,&saved)<0)
            throw std::runtime_error("Cannot read terminal settings");
        auto raw=saved;
        raw.c_lflag &= ~(ICANON|ECHO); // keep ISIG so Ctrl-C is handled normally
        raw.c_cc[VMIN]=0; raw.c_cc[VTIME]=0;
        if (tcsetattr(STDIN_FILENO,TCSANOW,&raw)<0) throw std::runtime_error("Cannot set terminal mode");
        std::cout << "\033[?1049h\033[?25l\033[2J" << std::flush;
    }
    ~Terminal() override {
        tcsetattr(STDIN_FILENO,TCSANOW,&saved);
        std::cout << "\033[0m\033[?25h\033[?1049l" << std::flush;
    }
    void present(const uint32_t* p,int w,int h) override {
        dimensions(p,w,h);
        auto now=Clock::now();
        if (last.time_since_epoch().count() && now-last<std::chrono::milliseconds(67)) return;
        last=now;
        winsize size{};
        ioctl(STDOUT_FILENO,TIOCGWINSZ,&size);
        int cols=std::min(160,size.ws_col ? int(size.ws_col):80);
        int rows=std::min(50,size.ws_row>1 ? int(size.ws_row)-1:24);
        // A cell is approximately twice as tall as wide, with two vertical pixels.
        cols=std::max(1,std::min(cols,rows*2*w/h));
        rows=std::max(1,std::min(rows,cols*h/(2*w)));
        std::string out="\033[H";
        out.reserve(size_t(cols)*rows*50);
        char seq[100];
        for(int y=0;y<rows;++y) {
            for(int x=0;x<cols;++x) {
                auto a=p[(size_t(2*y)*h/(2*rows))*w+size_t(x)*w/cols];
                auto b=p[(size_t(2*y+1)*h/(2*rows))*w+size_t(x)*w/cols];
                int n=std::snprintf(seq,sizeof(seq),"\033[38;2;%u;%u;%um\033[48;2;%u;%u;%um▀",
                    (a>>16)&255,(a>>8)&255,a&255,(b>>16)&255,(b>>8)&255,b&255);
                out.append(seq,size_t(n));
            }
            out += "\033[0m\033[K\r\n";
        }
        out += "\033[0m" + hud.substr(0,size_t(size.ws_col ? size.ws_col:80)-1) + "\033[K";
        std::cout << out << std::flush;
    }
    std::vector<KeyEvent> poll() override {
        std::vector<KeyEvent> result;
        char buf[256]; ssize_t n;
        while((n=read(STDIN_FILENO,buf,sizeof(buf)))>0) pending.append(buf,size_t(n));
        auto now=Clock::now();
        while(!pending.empty()) {
            unsigned char c=pending[0]; int key=-1; size_t used=1;
            if(c==27) {
                if(pending.size()==1 || (pending.size()==2 && pending[1]=='[')) {
                    if(!escape_since.time_since_epoch().count()) escape_since=now;
                    if(now-escape_since<std::chrono::milliseconds(40)) break;
                } else if(pending[1]=='[' && pending.size()>=3) {
                    switch(pending[2]) {case 'A':key=up;break;case 'B':key=down;break;case 'C':key=right;break;case 'D':key=left;break;}
                    used=3;
                }
                if(key<0) key=27;
            } else {
                switch(c) {
                    case 'w':case 'W':key=up;break;case 's':case 'S':key=down;break;
                    case 'a':case 'A':key=left;break;case 'd':case 'D':key=right;break;
                    case ' ':key=fire;break;case 'e':case 'E':key=use;break;
                    case '\n':case '\r':key=13;break;case 'q':case 'Q':stop=true;break;
                    default:break;
                }
            }
            pending.erase(0,used); escape_since={};
            if(key>=0) {
                if(!held[key]) {held[key]=true;result.push_back({true,uint8_t(key)});}
                until[key]=now+std::chrono::milliseconds(180);
            }
        }
        for(size_t k=0;k<held.size();++k) if(held[k] && now>=until[k]) {
            held[k]=false; result.push_back({false,uint8_t(k)});
        }
        return result;
    }
    void status(const std::string& text) override {hud=text;}
    bool closed() const override {return stop;}
};

// Load the stable SDL2 C ABI at runtime. All object pointers are opaque; no SDL
// structs/events are recreated here. This avoids requiring SDL2-devel on Linux.
class Sdl final : public Backend {
    void* library=nullptr; void* window=nullptr; void* renderer=nullptr; void* texture=nullptr;
    int width=0,height=0; bool initialized=false,stop=false;
    std::array<bool,256> held{};
    template<class T> T symbol(const char* name) {
        auto p=dlsym(library,name);
        if(!p) throw std::runtime_error(std::string("Missing SDL2 symbol: ")+name);
        return reinterpret_cast<T>(p);
    }
#define API(ret,name,args) using name##Fn=ret(*)args; name##Fn name=nullptr
    API(int,SDL_Init,(uint32_t)); API(void,SDL_Quit,()); API(const char*,SDL_GetError,());
    API(void*,SDL_CreateWindow,(const char*,int,int,int,int,uint32_t)); API(void,SDL_DestroyWindow,(void*)); API(void,SDL_SetWindowTitle,(void*,const char*));
    API(void*,SDL_CreateRenderer,(void*,int,uint32_t)); API(void,SDL_DestroyRenderer,(void*));
    API(void*,SDL_CreateTexture,(void*,uint32_t,int,int,int)); API(void,SDL_DestroyTexture,(void*));
    API(int,SDL_UpdateTexture,(void*,const void*,const void*,int));
    API(int,SDL_RenderClear,(void*)); API(int,SDL_RenderCopy,(void*,void*,const void*,const void*));
    API(void,SDL_RenderPresent,(void*)); API(int,SDL_RenderSetLogicalSize,(void*,int,int));
    API(void,SDL_PumpEvents,()); API(int,SDL_HasEvent,(uint32_t)); API(void,SDL_FlushEvents,(uint32_t,uint32_t));
    API(const uint8_t*,SDL_GetKeyboardState,(int*));
#undef API
    [[noreturn]] void fail(const char* what) {throw std::runtime_error(std::string(what)+": "+SDL_GetError());}
    void cleanup() {
        if(texture) SDL_DestroyTexture(texture);
        if(renderer) SDL_DestroyRenderer(renderer);
        if(window) SDL_DestroyWindow(window);
        if(initialized) SDL_Quit();
        if(library) dlclose(library);
    }
public:
    Sdl() {
        try {
            library=dlopen("libSDL2-2.0.so.0",RTLD_NOW|RTLD_LOCAL);
            if(!library) throw std::runtime_error(std::string("SDL2 runtime unavailable: ")+dlerror());
#define LOAD(name) name=symbol<name##Fn>(#name)
            LOAD(SDL_Init);LOAD(SDL_Quit);LOAD(SDL_GetError);LOAD(SDL_CreateWindow);LOAD(SDL_DestroyWindow);LOAD(SDL_SetWindowTitle);
            LOAD(SDL_CreateRenderer);LOAD(SDL_DestroyRenderer);LOAD(SDL_CreateTexture);LOAD(SDL_DestroyTexture);
            LOAD(SDL_UpdateTexture);LOAD(SDL_RenderClear);LOAD(SDL_RenderCopy);LOAD(SDL_RenderPresent);
            LOAD(SDL_RenderSetLogicalSize);LOAD(SDL_PumpEvents);LOAD(SDL_HasEvent);LOAD(SDL_FlushEvents);LOAD(SDL_GetKeyboardState);
#undef LOAD
            if(SDL_Init(0x20)!=0) fail("SDL_Init"); // SDL_INIT_VIDEO
            initialized=true;
            window=SDL_CreateWindow("Student CPU framebuffer",0x2fff0000,0x2fff0000,960,600,0x20); // centered, resizable
            if(!window) fail("SDL_CreateWindow");
            renderer=SDL_CreateRenderer(window,-1,2); // accelerated; fall back for dummy/headless drivers
            if(!renderer) renderer=SDL_CreateRenderer(window,-1,1);
            if(!renderer) fail("SDL_CreateRenderer");
        } catch(...) {cleanup();throw;}
    }
    ~Sdl() override {cleanup();}
    void present(const uint32_t* p,int w,int h) override {
        dimensions(p,w,h);
        if(w!=width||h!=height) {
            if(texture) {SDL_DestroyTexture(texture);texture=nullptr;}
            texture=SDL_CreateTexture(renderer,0x16362004,1,w,h); // ARGB8888, streaming
            if(!texture) fail("SDL_CreateTexture");
            width=w;height=h;
            if(SDL_RenderSetLogicalSize(renderer,w,h)!=0) fail("SDL_RenderSetLogicalSize");
        }
        if(SDL_UpdateTexture(texture,nullptr,p,w*4)!=0 || SDL_RenderClear(renderer)!=0 || SDL_RenderCopy(renderer,texture,nullptr,nullptr)!=0)
            fail("SDL framebuffer update");
        SDL_RenderPresent(renderer);
    }
    std::vector<KeyEvent> poll() override {
        SDL_PumpEvents();
        if(SDL_HasEvent(0x100)) stop=true; // SDL_QUIT
        int n=0; const auto* keys=SDL_GetKeyboardState(&n);
        std::array<bool,256> current{};
        // SDL2 scancodes, combining alternate bindings before producing transitions.
        const std::pair<int,uint8_t> bindings[]={{82,up},{26,up},{81,down},{22,down},{80,left},{4,left},{79,right},{7,right},
            {44,fire},{224,fire},{8,use},{40,13},{41,27},{225,0xb6},{229,0xb6}};
        for(auto b:bindings) if(b.first<n && keys[b.first]) current[b.second]=true;
        std::vector<KeyEvent> result;
        for(size_t k=0;k<held.size();++k) if(current[k]!=held[k]) result.push_back({current[k],uint8_t(k)});
        held=current;
        SDL_FlushEvents(0,0xffff); // keyboard state was already updated by PumpEvents
        return result;
    }
    void status(const std::string& text) override {SDL_SetWindowTitle(window,text.c_str());}
    bool closed() const override {return stop;}
};
}
std::unique_ptr<Backend> create(const std::string& mode) {
    if(mode=="auto") {
        try {
            auto set=[](const char* name) {const char* p=std::getenv(name);return p && *p;};
            // SDL may otherwise select an offscreen driver that opens no visible
            // window in an SSH session. Explicit --display sdl bypasses this check.
            if(!set("DISPLAY") && !set("WAYLAND_DISPLAY") && !set("SDL_VIDEODRIVER"))
                throw std::runtime_error("No graphical session detected");
            return std::make_unique<Sdl>();
        } catch(const std::exception& sdl_error) {
            const std::string reason=sdl_error.what();
            std::cerr << "SDL display unavailable: " << reason << "; trying terminal display.\n";
            try {return std::make_unique<Terminal>();}
            catch(const std::exception& terminal_error) {
                throw std::runtime_error(std::string("No usable display: SDL: ")+reason+
                    "; terminal: "+terminal_error.what()+". Use --display headless for unattended runs.");
            }
        }
    }
    if(mode=="terminal") return std::make_unique<Terminal>();
    if(mode=="sdl") return std::make_unique<Sdl>();
    if(mode=="headless") return std::make_unique<Headless>();
    throw std::runtime_error("Display must be auto, terminal, sdl, or headless");
}
}
