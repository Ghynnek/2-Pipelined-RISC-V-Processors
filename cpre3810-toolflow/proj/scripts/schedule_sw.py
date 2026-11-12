#!/usr/bin/env python3
"""Schedule this project's RV32I tests for EX redirects and no register bypass.
Expands multi-instruction pseudos before scheduling. Computes worst-case RAW
spacing over a conservative CFG (indirect jumps may reach address-taken labels
and every call continuation). Preserves instruction and memory operation order.
Not a general RISC-V compiler: unknown syntax/opcodes fail rather than guessing.
"""
from pathlib import Path
import re
ALIASES=dict(zip('zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6'.split(),range(32)))
ALIASES['fp']=8
ALIASES.update({f'x{i}':i for i in range(32)})
BR={'beq','bne','blt','bge','bltu','bgeu'}
LD={'lb','lh','lw','lbu','lhu'}
ST={'sb','sh','sw'}
RR={'add','sub','and','or','xor','sll','srl','sra','slt','sltu'}
RI={'addi','andi','ori','xori','slli','srli','srai','slti','sltiu'}
def args(s): return re.split(r'\s*,\s*|\s+',s.strip())
def expand(s):
 a=args(s);op=a[0];p=a[1:]
 if op=='li':
  v=int(p[1],0);v=(v+2**31)%2**32-2**31
  if -2048<=v<=2047:return [f'addi {p[0]}, x0, {v}']
  hi=((v+2048)>>12)&0xfffff;lo=((v+2048)&4095)-2048
  return [f'lui {p[0]}, {hi}',f'addi {p[0]}, {p[0]}, {lo}']
 if op=='la':return [f'lui {p[0]}, %hi({p[1]})',f'addi {p[0]}, {p[0]}, %lo({p[1]})']
 if op in LD and len(p)==2 and '(' not in p[1]:
  return [f'lui {p[0]}, %hi({p[1]})',f'{op} {p[0]}, %lo({p[1]})({p[0]})']
 if op=='mv':return [f'add {p[0]}, x0, {p[1]}']
 if op=='neg':return [f'sub {p[0]}, x0, {p[1]}']
 if op=='j':return [f'jal x0, {p[0]}']
 if op=='jr':return [f'jalr x0, 0({p[0]})']
 if op=='ret':return ['jalr x0, 0(ra)']
 if op=='nop':return ['addi x0, x0, 0']
 if op=='jal' and len(p)==1:return [f'jal ra, {p[0]}']
 return [s]
def describe(s):
 a=args(s);op=a[0];p=a[1:];r=lambda x:ALIASES[x]
 if op in RR:return {r(p[1]),r(p[2])},r(p[0])
 if op in RI:return {r(p[1])},r(p[0])
 if op in LD|ST or op=='jalr':
  base=re.search(r'\((\w+)\)$',p[-1])
  if base is None:raise ValueError(s)
  reads={r(base[1])}
  if op in ST:reads.add(r(p[0]));return reads,0
  return reads,r(p[0])
 if op in BR:return {r(p[0]),r(p[1])},0
 if op in {'lui','auipc','jal'}:return set(),r(p[0])
 if op in {'wfi','ebreak'}:return set(),0
 raise ValueError('Unsupported instruction: '+s)
def schedule(source,dest):
 text=source.read_text()
 # The original +8 target depends on two adjacent instructions. Padding changes
 # their size, so name the actual function instead of retaining that assumption.
 if source.name=='proj1_cf_test.s':
  text=re.sub(r'la\s+t6,\s*JalrBase', 'la t6, JalrFunc',text)
  text=re.sub(r'jalr\s+ra,\s*8\(t6\)', 'jalr ra, 0(t6)',text)
 if source.name=='grendel.s':text=text.replace('.word -1-1-1-1','.word -1, -1, -1, -1')
 prefix=[];nodes=[];labels={};pending=[];intext=False;taken=set()
 for raw in text.splitlines():
  line=raw.split('#')[0].strip()
  if line=='.text':intext=True;prefix.append('.text');continue
  if not intext:prefix.append(raw);continue
  if not line:continue
  if ':' in line:
   label,line=line.split(':',1);pending.append(label.strip());line=line.strip()
  if not line:continue
  if line.startswith('.'):
   if line.startswith('.globl'):continue
   raise ValueError(line)
  a=args(line)
  if a[0]=='la':taken.add(a[2])
  for ins in expand(line):
   i=len(nodes)
   for label in pending:labels[label]=i
   reads,rd=describe(ins)
   nodes.append(dict(ins=ins,labels=pending,reads=reads-{0},rd=rd,pad=0))
   pending=[]
 n=len(nodes)
 for label in pending:labels[label]=n
 returns={i+1 for i,x in enumerate(nodes) if args(x['ins'])[0] in {'jal','jalr'} and x['rd'] and i+1<n}
 targets={labels[x] for x in taken if x in labels}|returns
 for i,x in enumerate(nodes):
  a=args(x['ins']);op=a[0];x['delay']=2 if op in BR|{'jal','jalr'} else 0
  if op in BR:x['succ']=[labels[a[-1]],i+1]
  elif op=='jal':x['succ']=[labels[a[-1]]]
  elif op=='jalr':x['succ']=sorted(targets)
  elif op=='wfi':x['succ']=[]
  else:x['succ']=[i+1]
  x['succ']=[j for j in x['succ'] if j<n]
 def flow():
  ages=[None]*n;ages[0]=[4]*32;todo=[0]
  while todo:
   i=todo.pop();x=nodes[i];out=[min(4,a+x['pad']+1+x['delay']) for a in ages[i]]
   if x['rd']:out[x['rd']]=1+x['delay']
   for j in x['succ']:
    new=out.copy() if ages[j] is None else [min(a,b) for a,b in zip(ages[j],out)]
    if new!=ages[j]:ages[j]=new;todo.append(j)
  return ages
 def safe(ages):
  return all(ages[i] is None or all(ages[i][r]+x['pad']>=4 for r in x['reads']) for i,x in enumerate(nodes))
 # Establish safety, then remove redundant padding introduced by simultaneous
 # insertion. At completion no single remaining RAW NOP can be removed under
 # this conservative CFG without exposing a dependency.
 for outer in range(100):
  ages=flow();changed=False
  for i,x in enumerate(nodes):
   if ages[i] is None:continue
   need=max([0]+[4-ages[i][r] for r in x['reads']])
   if need>x['pad']:x['pad']=need;changed=True
  if not changed:break
 else:raise RuntimeError('Scheduling did not converge')
 for x in nodes:
  while x['pad']:
   x['pad']-=1
   if not safe(flow()):x['pad']+=1;break
 assert safe(flow())
 output=['# Software schedule: 3 intervening instructions for RAW; 2 NOPs after EX redirects.',
 '# Generated from '+source.name+' by scripts/schedule_sw.py.',
 '# Original arithmetic result comments are omitted because PC-relative values move.']+prefix
 for x in nodes:
  output += [s+':' for s in x['labels']]
  output += ['    nop    # RAW spacing across all modeled incoming paths']*x['pad']
  output += ['    '+x['ins']]
  output += ['    nop    # EX control-transfer spacing']*x['delay']
 dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text('\n'.join(output)+'\n')
 print(f'{dest.name}: {n} expanded instructions + {sum(x["pad"]+x["delay"] for x in nodes)} NOPs')
if __name__=='__main__':
 root=Path(__file__).resolve().parents[1]
 for name in ['proj1_base_test','proj1_cf_test','proj1_mergesort','proj1_extrasort','grendel']:
  schedule(root/'riscv'/f'{name}.s',root/'riscv/sw'/f'{name}_sw.s')
