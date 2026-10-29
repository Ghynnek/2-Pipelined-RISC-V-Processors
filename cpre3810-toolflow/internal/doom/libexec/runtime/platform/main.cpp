// SPDX-License-Identifier: GPL-2.0-only
#include "Vsim_cpu.h"
#include "verilated.h"
#include "../display/display.hpp"
#include "../display/frame_timing.hpp"
#include <algorithm>
#include <array>
#include <chrono>
#include <csignal>
#include <cstdint>
#include <cstring>
#include <deque>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>
namespace {
volatile std::sig_atomic_t interrupted=0;
void stop(int){interrupted=1;}
std::vector<uint8_t> file(const std::string& path) {
    std::ifstream f(path,std::ios::binary);
    if(!f)throw std::runtime_error("Cannot open "+path);
    return std::vector<uint8_t>((std::istreambuf_iterator<char>(f)),{});
}
uint32_t get32(const std::vector<uint8_t>& b,size_t p) {
    if(p>b.size() || b.size()-p<4)throw std::runtime_error("Truncated ELF");
    return uint32_t(b[p])|(uint32_t(b[p+1])<<8)|(uint32_t(b[p+2])<<16)|(uint32_t(b[p+3])<<24);
}
uint16_t get16(const std::vector<uint8_t>& b,size_t p) {
    if(p>b.size()||b.size()-p<2)throw std::runtime_error("Truncated ELF");
    return uint16_t(b[p])|(uint16_t(b[p+1])<<8);
}
struct OutputLog {
    std::ofstream stream;
    std::streambuf* previous=nullptr;
    explicit OutputLog(const std::string& path):stream(path) {
        if(!stream)throw std::runtime_error("Cannot open log "+path);
        previous=std::cerr.rdbuf(stream.rdbuf());
    }
    ~OutputLog(){std::cerr.rdbuf(previous);}
};
constexpr uint32_t ram_base=0x00400000,ram_size=64*1024*1024,wad_base=0x10000000,mmio=0x20000000;
struct Memory {
    std::vector<uint8_t> ram=std::vector<uint8_t>(ram_size),wad;
    std::deque<display::KeyEvent> keys;
    uint64_t cycles=0,frames=0,max_frames=0,frame_hash=0;
    uint32_t framebuffer=0,exit_code=0,boot_flags=0;
    bool exited=false;
    std::string ppm;
    display::Backend& screen;
    display::FrameTiming timing;
    std::chrono::steady_clock::time_point wall_last=std::chrono::steady_clock::now();
    Memory(display::Backend& s,uint64_t hz):screen(s),timing(hz){}
    void load(const std::string& path) {
        auto b=file(path);
        if(b.size()<52||std::memcmp(b.data(),"\177ELF\1\1\1",7)||get16(b,18)!=243||get16(b,16)!=2)
            throw std::runtime_error("Expected little-endian RISC-V ELF32 executable");
        if(get32(b,24)!=ram_base)throw std::runtime_error("ELF entry must match reset PC 0x00400000");
        uint32_t ph=get32(b,28);uint16_t size=get16(b,42),count=get16(b,44);
        if(size!=32 || uint64_t(ph)+uint64_t(size)*count>b.size())throw std::runtime_error("Invalid ELF program headers");
        unsigned loaded=0;
        for(unsigned i=0;i<count;++i) {
            size_t p=ph+i*size;if(get32(b,p)!=1)continue;
            uint32_t off=get32(b,p+4),addr=get32(b,p+8),fs=get32(b,p+16),ms=get32(b,p+20);
            if(fs>ms || uint64_t(off)+fs>b.size() || addr<ram_base || uint64_t(addr)-ram_base+ms>ram.size())throw std::runtime_error("ELF segment outside RAM");
            std::copy_n(b.begin()+off,fs,ram.begin()+(addr-ram_base));
            std::fill_n(ram.begin()+(addr-ram_base)+fs,ms-fs,0);++loaded;
        }
        if(!loaded)throw std::runtime_error("ELF has no loadable segments");
    }
    uint32_t read(uint32_t address,bool instruction=false) const {
        uint32_t a=address&~3u;
        const uint8_t* p=nullptr;
        if(a>=ram_base && uint64_t(a)-ram_base+4<=ram.size())p=ram.data()+a-ram_base;
        else if(a>=wad_base && uint64_t(a)-wad_base<wad.size()) {
            size_t off=a-wad_base;uint32_t v=0;
            for(unsigned i=0;i<4 && off+i<wad.size();++i)v|=uint32_t(wad[off+i])<<(8*i);
            return v;
        } else if(a>=mmio && a<mmio+64) {
            switch(a-mmio) {
                case 8:return uint32_t(timing.guest_milliseconds(cycles));
                case 20:return keys.empty()?0:0x80000000u|(uint32_t(keys.front().pressed)<<8)|keys.front().key;
                case 32:return uint32_t(wad.size());
                case 36:return boot_flags;
                default:return 0;
            }
        } else {
            if(instruction && !interrupted)throw std::runtime_error("Instruction fetch outside RAM at "+std::to_string(address));
            // Idle data port addresses do not constitute loads: no read-valid port.
            return 0;
        }
        return uint32_t(p[0])|(uint32_t(p[1])<<8)|(uint32_t(p[2])<<16)|(uint32_t(p[3])<<24);
    }
    void present() {
        constexpr unsigned w=320,h=200;
        if(framebuffer<ram_base || uint64_t(framebuffer)-ram_base+w*h*4>ram.size())throw std::runtime_error("Framebuffer outside RAM");
        std::vector<uint32_t> pixels(w*h);
        frame_hash=14695981039346656037ULL;
        for(size_t i=0;i<pixels.size();++i){pixels[i]=read(framebuffer+uint32_t(i*4));frame_hash=(frame_hash^pixels[i])*1099511628211ULL;}
        ++frames;
        auto sample=timing.submit(cycles);
        auto now=std::chrono::steady_clock::now();
        double host_fps=1.0/std::chrono::duration<double>(now-wall_last).count();wall_last=now;
        std::ostringstream hud;hud<<std::fixed<<std::setprecision(1)<<"Guest "<<sample.guest_fps<<" FPS | host "<<host_fps<<" FPS | "<<sample.cycles_per_frame<<" cyc/frame | Q quits terminal";
        screen.status(hud.str());screen.present(pixels.data(),w,h);
        std::cerr<<"frame="<<frames<<" cycles="<<cycles<<" cycles/frame="<<sample.cycles_per_frame<<" guest-fps="<<sample.guest_fps<<" checksum="<<frame_hash<<'\n';
        if(!ppm.empty()) {
            std::ofstream out(ppm,std::ios::binary);out<<"P6\n320 200\n255\n";
            for(auto p:pixels){char rgb[]={char(p>>16),char(p>>8),char(p)};out.write(rgb,3);}
            if(!out)throw std::runtime_error("Cannot save framebuffer");
        }
    }
    void write(uint32_t address,uint32_t value,uint8_t be) {
        uint32_t a=address&~3u;
        if(!be)return;
        if(a>=ram_base && uint64_t(a)-ram_base+4<=ram.size()) {
            for(unsigned i=0;i<4;++i)if(be&(1<<i))ram[a-ram_base+i]=uint8_t(value>>(8*i));
        } else if(a>=mmio && a<mmio+64) {
            if(a==mmio){if(be&1)std::cerr.put(char(value));}
            else if(a==mmio+4){exit_code=value;exited=true;}
            else if(a==mmio+12)framebuffer=value;
            else if(a==mmio+16)present();
            else if(a==mmio+20 && !keys.empty())keys.pop_front();
        } else throw std::runtime_error("Store outside RAM/devices at "+std::to_string(address));
    }
};
}
int main(int argc,char** argv) {
    try {
        std::string elf,wad,mode="auto",ppm,log,input;
        uint64_t limit=2000000000ULL,frames=0,hz=50000000;bool warp=false,low_detail=false;unsigned view_size=0;
        for(int i=1;i<argc;++i){std::string a=argv[i];
            auto value=[&](){if(i+1>=argc)throw std::runtime_error("Missing value for "+a);return std::string(argv[++i]);};
            if(a=="--elf")elf=value();else if(a=="--wad")wad=value();else if(a=="--display")mode=value();else if(a=="--terminal")mode="terminal";
            else if(a=="--warp")warp=true;
            else if(a=="--low-detail")low_detail=true;
            else if(a=="--view-size"){auto v=value();if(v.size()!=1 || v[0]<'3' || v[0]>'9'){if(v!="10" && v!="11")throw std::runtime_error("--view-size must be 3 through 11");}view_size=std::stoul(v);}
            else if(a=="--log")log=value();
            else if(a=="--input")input=value();
            else if(a=="--help"){std::cout<<"Usage: sim/doom/run [--terminal | --display sdl|terminal|headless|auto] [--warp] [--low-detail] [--view-size 3..11] [--frames N] [--max-cycles N] [--ppm file] [--guest-hz Hz] [--input file] [--log file]\n";return 0;}
            else if(a=="--max-cycles")limit=std::stoull(value());else if(a=="--frames")frames=std::stoull(value());else if(a=="--guest-hz")hz=std::stoull(value());else if(a=="--ppm")ppm=value();
            else throw std::runtime_error("Unknown argument "+a);
        }
        if(elf.empty())throw std::runtime_error("Usage: platform --elf program.elf [--wad game.wad] [--display auto|sdl|terminal|headless] [--terminal] [--frames N] [--max-cycles N] [--ppm file] [--guest-hz Hz]");
        std::signal(SIGINT,stop);std::signal(SIGTERM,stop);
        std::unique_ptr<OutputLog> logging;
        if(!log.empty())logging=std::make_unique<OutputLog>(log);
        auto backend=display::create(mode);Memory memory(*backend,hz);memory.max_frames=frames;memory.ppm=ppm;memory.boot_flags=(warp?1:0)|(low_detail?2:0)|(view_size<<8);
        if(!wad.empty())memory.wad=file(wad);
        memory.load(elf);
        struct ScheduledKey {uint64_t cycle;display::KeyEvent event;};
        std::vector<ScheduledKey> scheduled;size_t next_key=0;
        if(!input.empty()) {
            std::ifstream in(input);if(!in)throw std::runtime_error("Cannot open input recording");
            std::string line;
            while(std::getline(in,line)) {
                if(line.empty()||line[0]=='#')continue;
                std::istringstream fields(line);std::string cycle;int pressed,key;
                if(!(fields>>cycle>>pressed>>std::setbase(0)>>key) || pressed<0 || pressed>1 || key<0 || key>255)
                    throw std::runtime_error("Input lines must be: cycle pressed(0/1) key-code");
                uint64_t c=std::stoull(cycle,nullptr,0);
                if(!scheduled.empty() && c<scheduled.back().cycle)throw std::runtime_error("Input recording must be sorted by cycle");
                scheduled.push_back({c,{bool(pressed),uint8_t(key)}});
            }
        }
        VerilatedContext context;context.threads(1);Vsim_cpu cpu{&context};
        cpu.iCLK=0;cpu.iRST=1;cpu.iInstLd=0;cpu.iInstAddr=0;cpu.iInstExt=0;cpu.sim_iq=0;cpu.sim_dq=0;
        auto settle=[&](){
            for(unsigned n=0;n<12;++n){
                cpu.eval();
                uint32_t iq=memory.read(cpu.sim_ia,true),dq=memory.read(cpu.sim_da);
                if(iq==cpu.sim_iq && dq==cpu.sim_dq)return;
                cpu.sim_iq=iq;cpu.sim_dq=dq;
            }
            throw std::runtime_error("Memory combinational settling did not converge");
        };
        // The PC may be undefined before its first synchronous reset edge.
        cpu.eval();cpu.iCLK=1;cpu.eval();cpu.iCLK=0;settle();
        for(int i=0;i<4;++i){cpu.iCLK=1;settle();cpu.iCLK=0;settle();}
        while(next_key<scheduled.size() && scheduled[next_key].cycle==0)memory.keys.push_back(scheduled[next_key++].event);
        cpu.iRST=0;settle();
        std::array<uint32_t,32> regs{};
        auto start=std::chrono::steady_clock::now();memory.wall_last=start;
        while(memory.cycles<limit && !memory.exited && !interrupted && !backend->closed() && (!frames||memory.frames<frames)) {
            if(cpu.sim_halt)throw std::runtime_error("CPU halted before an exit MMIO write, fetch PC="+std::to_string(cpu.sim_pc));
            if(cpu.sim_rw && cpu.sim_rd)regs[cpu.sim_rd]=cpu.sim_rv;
            bool we=cpu.sim_we;uint32_t addr=cpu.sim_da,data=cpu.sim_dd;uint8_t be=cpu.sim_be;
            cpu.iCLK=1;cpu.eval(); // registers sample old asynchronous memory outputs
            ++memory.cycles;
            if(we)memory.write(addr,data,be); // one committed synchronous store
#ifdef SIM_SIMPLE_CORE
            // The simple core's instruction address depends only on its PC,
            // and its data address does not depend on read data. Three evals
            // per cycle suffice; generic student cores retain convergence.
            cpu.iCLK=0;cpu.sim_iq=memory.read(cpu.sim_ia,true);cpu.eval();
            cpu.sim_dq=(cpu.sim_iq&127)==3?memory.read(cpu.sim_da):0;
            cpu.eval();
#else
            settle();cpu.iCLK=0;settle();
#endif
            bool input_changed=false;
            while(next_key<scheduled.size() && scheduled[next_key].cycle<=memory.cycles) {
                if(memory.keys.size()>=256)throw std::runtime_error("Input queue overflow");
                memory.keys.push_back(scheduled[next_key++].event);input_changed=true;
            }
            if((memory.cycles&65535)==0)for(auto event:backend->poll())if(memory.keys.size()<256){memory.keys.push_back(event);input_changed=true;}
            if(input_changed)settle();
        }
        double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count();
        std::cerr<<"\ncycles="<<memory.cycles<<" seconds="<<seconds<<" cycles/s="<<memory.cycles/seconds<<" frames="<<memory.frames<<" host-fps="<<memory.frames/seconds<<" a0="<<regs[10]<<" pc=0x"<<std::hex<<cpu.sim_pc<<std::dec<<'\n';
        cpu.final();
        if(memory.exited)return memory.exit_code?1:0;
        if(frames && memory.frames>=frames)return 0;
        if(interrupted||backend->closed())return 0;
        std::cerr<<"Cycle limit reached\n";return 3;
    }catch(const std::exception& e){std::cerr<<"platform: "<<e.what()<<'\n';return 2;}
}
