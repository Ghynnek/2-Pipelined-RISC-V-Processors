#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Offline student HDL -> native simulator launcher; Python standard library only."""
import argparse
import contextlib
import fcntl
import hashlib
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
SKIP={'test','tests','testbench','testbenches','tb','.git','.svn','.cache','build','obj','node_modules','__pycache__'}
PORTS='''
       sim_iq : in std_logic_vector(31 downto 0);
       sim_dq : in std_logic_vector(31 downto 0);
       sim_ia : out std_logic_vector(31 downto 0);
       sim_da : out std_logic_vector(31 downto 0);
       sim_dd : out std_logic_vector(31 downto 0);
       sim_be : out std_logic_vector(3 downto 0);
       sim_we : out std_logic;
       sim_halt : out std_logic;
       sim_pc : out std_logic_vector(31 downto 0);
       sim_rw : out std_logic;
       sim_rd : out std_logic_vector(4 downto 0);
       sim_rv : out std_logic_vector(31 downto 0);
'''
WIRES='''
  s_Inst <= sim_iq;
  s_DMemOut <= sim_dq;
  sim_ia <= s_IMemAddr;
  sim_da <= s_DMemAddr;
  sim_dd <= s_DMemData;
  sim_be <= s_DMemBE;
  sim_we <= s_DMemWr;
  sim_halt <= s_Halt;
  sim_pc <= s_PC;
  sim_rw <= s_RegWr;
  sim_rd <= s_RegWrAddr;
  sim_rv <= s_RegWrData;
'''
class LaunchError(Exception): pass

def scan(directory):
    result=[]
    for base,dirs,names in os.walk(directory):
        dirs[:]=sorted(d for d in dirs if d.lower() not in SKIP and not d.startswith('.'))
        for name in sorted(names):
            low=name.lower()
            if low.endswith(('.vhd','.vhdl')) and not low.startswith(('tb_','test_')) and not low.endswith(('_tb.vhd','_tb.vhdl')):
                result.append(Path(base)/name)
    return result

def locate(argument):
    directory=Path(argument).expanduser().resolve()
    if directory.is_file() and directory.name.lower()=='riscv_processor.vhd':
        top=directory;directory=top.parent
    else:
        if not directory.is_dir():raise LaunchError('HDL directory does not exist: '+str(directory))
        tops=[p for p in scan(directory) if p.name.lower()=='riscv_processor.vhd']
        if len(tops)!=1:raise LaunchError('Expected one RISCV_Processor.vhd under '+str(directory)+f'; found {len(tops)}. Pass one CPU project directory.')
        top=tops[0]
    # A direct TopLevel argument must also collect sibling components/packages.
    if top.parent.name.lower()=='toplevel' and directory==top.parent:
        directory=top.parent.parent
    files=scan(directory)
    return directory,top,[p for p in files if p!=top and p.name.lower() not in ('mem.vhd','mem.vhdl')]

def adapt(top):
    text=top.read_text()
    # Ignore comments for structural matching; original sources remain untouched.
    text=re.sub(r'"(?:""|[^"])*"|--[^\n]*',lambda m: m[0] if m[0].startswith('"') else '',text)
    text=re.sub(r'\bRISCV_Processor\b','sim_cpu',text,flags=re.I)
    match=re.search(r'\boALUOut\s*:',text,re.I)
    if not match:raise LaunchError('Template port oALUOut is missing in '+str(top))
    text=text[:match.start()]+PORTS+text[match.start():]
    for label in ('IMem','DMem'):
        pattern=r'\b'+label+r'\s*:\s*(?:entity\s+work\.)?mem(?:\s*\(\s*\w+\s*\))?\b.*?\bport\s+map\s*\(.*?\);'
        text,n=re.subn(pattern,'',text,flags=re.I|re.S)
        if n!=1:raise LaunchError(f'Expected exactly one template {label}: mem instance in {top}; found {n}.')
    # Match the architecture declaration region, not a nested process/function begin.
    architecture=re.search(r'\barchitecture\s+\w+\s+of\s+sim_cpu\s+is\b',text,re.I)
    if not architecture:raise LaunchError('Expected an architecture of RISCV_Processor.')
    tail=text[architecture.end():]
    # Architecture begin occurs at column zero in the supplied template; handle
    # indentation and nested subprograms by tracking declarations' begin/end.
    # GHDL can inject concurrent assignments just before the final architecture end,
    # avoiding any need to parse nested declaration bodies.
    end=re.search(r'\bend\s*(?:(?:architecture\s*)?(?:\w+\s*)?)?;\s*$',tail,re.I)
    if not end:raise LaunchError('Cannot find the final architecture end in '+str(top))
    at=architecture.end()+end.start()
    return text[:at]+WIRES+text[at:]

def which_tool(name):
    # Avoid EDA wrappers named python3/g++ which may depend on unavailable mounts.
    path='/usr/bin:/bin:'+os.environ.get('PATH','')
    tool=shutil.which(name,path=path)
    if not tool:raise LaunchError(f'{name} is required on this machine. Install a C++17 compiler and Make (GHDL and Verilator are bundled).')
    return tool

def environment(verilator_root=None):
    env=os.environ.copy();env['PATH']='/usr/bin:/bin:'+env.get('PATH','')
    env.pop('GHDL_PREFIX',None)
    if verilator_root:env['VERILATOR_ROOT']=str(verilator_root)
    return env

def command(args,log,cwd,env,output=None):
    log.write(('\n$ '+' '.join(map(str,args))+'\n').encode());log.flush()
    result=subprocess.run(list(map(str,args)),cwd=cwd,env=env,stdout=output or log,stderr=log)
    if result.returncode:
        log.flush()
        tail=Path(log.name).read_text(errors='replace').splitlines()[-18:]
        print('\n'.join(tail),file=sys.stderr)
        raise LaunchError(f'Build step failed ({Path(str(args[0])).name}). See {log.name}')

def compiler_id(compiler):
    result=subprocess.run([compiler,'--version'],capture_output=True,env=environment())
    if result.returncode:raise LaunchError('Cannot execute C++ compiler '+compiler)
    return result.stdout

def cache_root(argument, source_directory):
    candidate=Path(argument).expanduser() if argument else Path(os.environ.get('XDG_CACHE_HOME',str(Path.home()/'.cache')))/'doom-hdl'
    candidate=candidate.resolve()
    if any(c.isspace() for c in str(candidate)):
        if argument:raise LaunchError('--cache-dir must not contain whitespace (native Make limitation).')
        candidate=Path(tempfile.gettempdir())/f'doom-hdl-{os.getuid()}'
    if candidate == source_directory or source_directory in candidate.parents:
        raise LaunchError('The build cache must be outside the student processor directory. Choose another --cache-dir.')
    candidate.mkdir(parents=True,exist_ok=True,mode=0o700)
    return candidate

def build(directory,top,files,args):
    compiler=which_tool('g++');make=which_tool('make')
    # Include source bytes and paths: edits invalidate the cache without relying
    # on timestamps; a package rebuild or compiler change also invalidates it.
    digest=hashlib.sha256((ROOT/'MANIFEST.sha256').read_bytes()+Path(__file__).read_bytes()+compiler_id(compiler))
    snapshot=[(p,p.read_bytes()) for p in [top,*files]]
    for p,data in snapshot: digest.update(str(p.relative_to(directory)).encode());digest.update(data)
    build_dir=cache_root(args.cache_dir,directory)/digest.hexdigest()[:24]
    build_dir.mkdir(exist_ok=True)
    with (build_dir/'build.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        executable=build_dir/'obj/Vsim_cpu'
        marker=build_dir/'complete'
        if not args.rebuild and executable.is_file() and marker.is_file():
            print('Using cached processor simulator.',file=sys.stderr)
            return executable,build_dir
        marker.unlink(missing_ok=True)
        print('Building your processor (first run or HDL changed)...',file=sys.stderr)
        work=build_dir/'ghdl';work.mkdir(exist_ok=True)
        # Stage required runtime sources so makefiles never embed extraction paths
        # that might contain spaces. Student originals are only read.
        runtime=build_dir/'runtime';runtime.mkdir(exist_ok=True)
        for name in ('platform','display'):
            shutil.copytree(ROOT/'libexec/runtime'/name,runtime/name,dirs_exist_ok=True)
        verilator=build_dir/'verilator'
        shutil.copytree(ROOT/'libexec/verilator/include',verilator/'include',dirs_exist_ok=True)
        (verilator/'bin').mkdir(exist_ok=True)
        shutil.copy2(ROOT/'libexec/verilator/bin/verilator_includer',verilator/'bin/verilator_includer')
        shutil.copy2(ROOT/'libexec/verilator/bin/verilator_ccache_report',verilator/'bin/verilator_ccache_report')
        # All HDL tools consume only this private snapshot. The memory and
        # addressing adapter is applied to the copied top, never to originals.
        copied=[]
        for original,data in snapshot:
            destination=build_dir/'hdl'/original.relative_to(directory)
            destination.parent.mkdir(parents=True,exist_ok=True)
            destination.write_bytes(data)
            copied.append(destination)
        copied_top=copied[0];copied_files=copied[1:]
        generated=build_dir/'sim_cpu.vhd';generated.write_text(adapt(copied_top))
        log_path=build_dir/'build.log'
        env=environment(verilator);ghdl=ROOT/'libexec/ghdl/bin/ghdl'
        with log_path.open('wb') as log:
            print('  1/3: analyzing VHDL',file=sys.stderr)
            command([ghdl,'-i','--std=08',f'--workdir={work}',*copied_files,generated],log,build_dir,env)
            command([ghdl,'-m','--std=08',f'--workdir={work}','sim_cpu'],log,build_dir,env)
            print('  2/3: synthesizing processor',file=sys.stderr)
            with (build_dir/'cpu.v').open('wb') as out:
                command([ghdl,'--synth','--std=08',f'--workdir={work}','--out=verilog','sim_cpu'],log,build_dir,env,out)
            print('  3/3: compiling native simulator',file=sys.stderr)
            command([ROOT/'libexec/verilator/bin/verilator_bin','--cc','--exe','-O3','--no-assert','-Wno-fatal','--top-module','sim_cpu','--Mdir','obj','-CFLAGS','-O3 -DNDEBUG -flto -std=c++17','-LDFLAGS','-flto -ldl',build_dir/'cpu.v',runtime/'platform/main.cpp',runtime/'display/display.cpp'],log,build_dir,env)
            command([make,'-C','obj','-f','Vsim_cpu.mk',f'-j{args.jobs}',f'CXX={compiler}',f'LINK={compiler}','OPT_FAST=-O3','OPT_SLOW=-O2','PYTHON3='+sys.executable],log,build_dir,env)
        marker.write_text('complete\n')
        return executable,build_dir

def play(executable,build_dir,args,forward):
    # Start the first level directly; SDL with terminal fallback remains default.
    runner=[str(executable),'--elf',str(ROOT/'assets/doom.elf'),'--wad',str(ROOT/'assets/doom1.wad'),'--warp','--max-cycles','10000000000','--log',str(build_dir/'run.log'),*forward]
    print('Starting Doom. Log: '+str(build_dir/'run.log'),file=sys.stderr)
    child=subprocess.Popen(runner)
    def stop(signum,frame):
        with contextlib.suppress(ProcessLookupError):child.send_signal(signum)
    old={s:signal.signal(s,stop) for s in (signal.SIGINT,signal.SIGTERM)}
    try:return child.wait()
    finally:
        for s,handler in old.items():signal.signal(s,handler)

def main():
    parser=argparse.ArgumentParser(prog='doom3810',description='Run Doom on your template-compatible VHDL processor. Compiles locally, caches by HDL content, and needs no internet.',epilog='Display/game options: --terminal, --display auto|sdl|terminal|headless, --low-detail, --view-size 3..11, --frames N, --max-cycles N, --guest-hz Hz, --ppm FILE, --wad FILE, --elf FILE, --input FILE, --log FILE. SDL is default, terminal is the fallback.')
    parser.add_argument('directory',help='CPU project directory, TopLevel directory, or RISCV_Processor.vhd')
    parser.add_argument('--build-only',action='store_true',help='compile and print simulator path without starting Doom')
    parser.add_argument('--rebuild',action='store_true',help='recompile even if cached')
    parser.add_argument('--cache-dir',help='override ~/.cache/doom-hdl')
    parser.add_argument('--jobs',type=int,default=min(4,os.cpu_count() or 1),help='parallel compilation jobs (default: up to 4)')
    parser.add_argument('--version',action='version',version='doom3810 1.0 (GHDL 6.0.0, Verilator 5.052)')
    runner_flags=('--terminal','--warp','--low-detail')
    runner_values=('--display','--frames','--max-cycles','--guest-hz','--ppm','--wad','--elf','--input','--log','--view-size')
    for option in runner_flags:parser.add_argument(option,action='store_true',help=argparse.SUPPRESS)
    for option in runner_values:parser.add_argument(option,help=argparse.SUPPRESS)
    args=parser.parse_args()
    forward=[]
    for option in runner_flags:
        if getattr(args,option[2:].replace('-','_')):forward.append(option)
    for option in runner_values:
        value=getattr(args,option[2:].replace('-','_'))
        if value is not None:forward.extend((option,value))
    if args.jobs<1:parser.error('--jobs must be positive')
    if args.display and args.display not in ('auto','sdl','terminal','headless'):parser.error('invalid --display mode')
    for name in ('frames','max_cycles','guest_hz','view_size'):
        value=getattr(args,name)
        if value is not None:
            try:n=int(value)
            except ValueError:parser.error('--'+name.replace('_','-')+' must be an integer')
            if n<0 or (name=='guest_hz' and n==0):parser.error('--'+name.replace('_','-')+' is out of range')
            if name=='view_size' and not 3<=n<=11:parser.error('--view-size must be 3 through 11')
    if platform.system()!='Linux' or platform.machine() not in ('x86_64','amd64'):raise LaunchError('This package requires x86-64 Linux.')
    directory,top,files=locate(args.directory)
    # Output options must not turn this launcher into a writer of the inputs.
    protected={p.resolve() for p in scan(directory)}
    for option in ('log','ppm'):
        value=getattr(args,option)
        if value:
            output=Path(value).expanduser().resolve()
            if output==directory or directory in output.parents or output in protected:
                raise LaunchError('--'+option+' output must be outside the student processor directory and its HDL files.')
    exe,build_dir=build(directory,top,files,args)
    if args.build_only:print(exe);return 0
    return play(exe,build_dir,args,forward)

if __name__=='__main__':
    try:sys.exit(main())
    except LaunchError as e:print('doom3810: '+str(e),file=sys.stderr);sys.exit(2)
    except KeyboardInterrupt:print('\nBuild interrupted.',file=sys.stderr);sys.exit(130)
    except OSError as e:print('doom3810: '+str(e),file=sys.stderr);sys.exit(2)
