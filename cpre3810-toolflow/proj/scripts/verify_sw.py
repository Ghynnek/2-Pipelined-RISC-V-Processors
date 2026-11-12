#!/usr/bin/env python3
"""Reproducible GHDL/RARS regression, using simulation-only copies of the DUT.
The only additions to copies are a passive trace monitor and RAM initialization
from the RARS data image. Actual datapath, registers and memory writes are intact.
Requires ghdl, Java, and the course RARS jar (RARS_JAR environment override).
"""
from pathlib import Path
import os, re, shutil, subprocess, sys, json
ROOT=Path(__file__).resolve().parents[1]
TF=ROOT.parent
GHDL=os.environ.get('GHDL','ghdl')
JAR=Path(os.environ.get('RARS_JAR',str(TF/'internal/Rars/RARS_CPRE3810.jar'))).resolve()
BUILD=ROOT/'build_sw'
MONITOR='''
  -- Passive test instrumentation, generated only in build_sw.
  trace: process(iCLK)
    file f : text open write_mode is "actual.trace";
    variable l : line;
    variable cycle : natural := 0;
  begin
    if rising_edge(iCLK) and s_reset = '0' then
      if s_RegWr = '1' then
        write(l, string'("In clock cycle: ")); write(l, cycle); writeline(f,l);
        write(l, string'("Register Write to Reg: 0x")); hwrite(l,s_RegWrAddr);
        write(l, string'(" Val: 0x")); hwrite(l,s_RegWrData); writeline(f,l);
      end if;
      if s_DMemWr = '1' then
        write(l, string'("In clock cycle: ")); write(l, cycle); writeline(f,l);
        write(l, string'("Memory Write to Addr: 0x")); hwrite(l,s_DMemAddr);
        write(l, string'(" Val: 0x")); hwrite(l,s_DMemData);
        write(l, string'(" BE: ")); write(l,s_DMemBE); writeline(f,l);
      end if;
      if s_Halt = '1' then
        write(l, string'("Execution is stopping! Clock Cycle: "));
        write(l,cycle); writeline(f,l); file_close(f); std.env.stop;
      end if;
      cycle := cycle + 1;
      assert cycle < 200000 severity failure;
    end if;
  end process;
'''
TB='''
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
use ieee.std_logic_textio.all; use std.textio.all;
entity tb_sw is end;
architecture test of tb_sw is
 signal clk : std_logic := '0';
 signal rst,ld : std_logic := '1';
 signal addr,ins,outv : std_logic_vector(31 downto 0) := (others=>'0');
begin
 clk <= not clk after 10 ns;
 dut: entity work.RISCV_Processor port map(clk,rst,ld,addr,ins,outv);
 process
  file f : text open read_mode is "imem.hex";
  variable l : line; variable word : std_logic_vector(31 downto 0);
  variable i : natural := 0;
 begin
  while not endfile(f) loop
   readline(f,l); hread(l,word); ins<=word;
   addr<=std_logic_vector(to_unsigned(i*4,32));
   wait until falling_edge(clk); i:=i+1;
  end loop;
  ld<='0'; wait until falling_edge(clk); rst<='0'; wait;
 end process;
end;
'''
def run(cmd,cwd,timeout=90):
 p=subprocess.run([str(x) for x in cmd],cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout)
 if p.returncode or re.search(r'^Error',p.stdout,re.M):raise RuntimeError(' '.join(map(str,cmd))+'\n'+p.stdout[-6000:])
 return p.stdout
def events(s, reference=False):
 out=[]; regs=[0]*32; regs[2]=0x7fffeffc; regs[3]=0x10008000
 for line in s.splitlines():
  m=re.search(r'Register Write to Reg: 0x([0-9A-Fa-f]+) Val: 0x([0-9A-Fa-f]+)',line)
  if m:
   r,v=map(lambda x:int(x,16),m.groups())
   if r:out.append(('reg',r,v)); regs[r]=v
  m=re.search(r'Memory Write to Addr: 0x([0-9A-Fa-f]+) Val: 0x([0-9A-Fa-f]+)(?: BE: ([01]+))?',line)
  if m and not reference:
   a,v=int(m[1],16),int(m[2],16)
   # RARS gives exact access address and unshifted store value; derive width
   # from its preceding instruction. GHDL gives lane-aligned data and BE.
   be=m[3]
   if be:
    for lane in range(4):
     if int(be,2)&(1<<lane):out.append(('mem',(a&~3)+lane,(v>>(8*lane))&255))
   else:
    for lane in range(width):out.append(('mem',a+lane,(v>>(8*lane))&255))
  if re.search(r'\[inst #\d+\]',line):
   op=line.split(']')[1].strip().split()[0]
   width={'sb':1,'sh':2,'sw':4}.get(op,4)
   if reference and op in {'sb','sh','sw'}:
    store=re.search(r's[bhw] x(\d+),(-?\d+)\(x(\d+)\)',line)
    assert store,line
    rs,offset,base=map(int,store.groups()); a=(regs[base]+offset)&0xffffffff;v=regs[rs]
    for lane in range(width):out.append(('mem',a+lane,(v>>(8*lane))&255))
 return out
def main():
 BUILD.mkdir(exist_ok=True)
 design=BUILD/'design';design.mkdir(exist_ok=True)
 for p in (ROOT/'src_sw').rglob('*.vhd'):
  text=p.read_text()
  if p.name=='RISCV_Processor.vhd':
   text=text.replace('use IEEE.std_logic_1164.all;', 'use IEEE.std_logic_1164.all;\nuse ieee.std_logic_textio.all; use std.textio.all;',1)
   text=text.replace('end structure;',MONITOR+'\nend structure;')
  if p.name=='mem.vhd':
   text=text.replace('use ieee.numeric_std.all;', 'use ieee.numeric_std.all;\nuse ieee.std_logic_textio.all; use std.textio.all;')
   text=text.replace('signal ram : memory_t;', '''impure function init return memory_t is
      file f : text open read_mode is "dmem.hex";
      variable l : line; variable a : memory_t := (others => (others => '0'));
      variable i : natural := 0;
    begin
      while not endfile(f) loop
        readline(f,l); hread(l,a(i)); i := i+1;
      end loop;
      return a;
    end function;
    signal ram : memory_t := init;''')
  (design/p.name).write_text(text)
 (design/'tb_sw.vhd').write_text(TB)
 work=BUILD/'work';work.mkdir(exist_ok=True)
 run([GHDL,'-i','--std=08',f'--workdir={work}',*sorted(design.glob('*.vhd'))],BUILD)
 run([GHDL,'-m','--std=08',f'--workdir={work}','tb_sw'],BUILD)
 results=[]
 programs=list(sorted((ROOT/'riscv/sw').glob('*.s')))
 for asm in programs:
  case=BUILD/asm.stem;case.mkdir(exist_ok=True)
  for seg,name in [('.text','imem.hex'),('.data','dmem.hex')]:
   (case/name).write_text('')
   run(['java','-jar',JAR,'nc','a','dump',seg,'HexText',case/name,asm],case)
  words=len((case/'imem.hex').read_text().splitlines())
  assert words<=1024,(asm.name,words,'exceeds instruction RAM')
  ref=run(['java','-jar',JAR,'nc','200000',asm],case)
  assert 'maximum step limit' not in ref.lower(),asm.name
  (case/'rars.trace').write_text(ref)
  log=run([GHDL,'-r','--std=08',f'--workdir={work}','tb_sw','--assert-level=error','--ieee-asserts=disable',f'--vcd={case}/wave.vcd'],case)
  (case/'simulation.log').write_text(log)
  actual=(case/'actual.trace').read_text()
  assert 'Execution is stopping!' in actual,asm.name
  expected,got=events(ref,reference=True),events(actual)
  for i,(a,b) in enumerate(zip(expected,got)):
   assert a==b,(asm.name,i,a,b)
  assert len(expected)==len(got),(asm.name,len(expected),len(got))
  cycles=int(re.search(r'Execution is stopping! Clock Cycle: (\d+)',actual)[1])+1
  row={'test':asm.name,'words':words,'cycles':cycles,'architectural_events':len(got),'result':'PASS'}
  results.append(row);print(row,flush=True)
 (BUILD/'results.json').write_text(json.dumps(results,indent=2)+'\n')
if __name__=='__main__':main()
