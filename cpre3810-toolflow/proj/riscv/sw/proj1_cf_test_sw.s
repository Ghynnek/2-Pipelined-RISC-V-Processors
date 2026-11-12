# Software schedule: 3 intervening instructions for RAW; 2 NOPs after EX redirects.
# Generated from proj1_cf_test.s by scripts/schedule_sw.py.
# Original arithmetic result comments are omitted because PC-relative values move.
# Proj1_cf_test.s
# Author: Alex Anderson (Team E_08)
# Uses every required control-flow instruction:
#   beq, bne, blt, bge, bltu, bgeu, jal, jalr
# Each conditional branch is checked both taken and not taken, including
# the equal case and signed vs unsigned operands. A recursive function
# then builds a call chain 8 activation records deep (requirement: >= 5).
# s0 counts every check that went the right way. If the processor takes a
# wrong path it jumps to "Fail", which writes 0xFFFFFFFF into s11 - a
# register write RARS never makes, so the toolflow flags it immediately.

.data
.text
main:
    lui   sp, 0x7FFFF
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi  sp, sp, -4
    addi  s0, x0, 0
    addi  t0, x0, -5
    addi  t1, x0, 3
    addi  t2, x0, 3
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq   t1, t2, BeqTaken
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
BeqTaken:
    addi  s0, s0, 1
    beq   t0, t1, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    bne   t0, t1, BneTaken
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
BneTaken:
    addi  s0, s0, 1
    bne   t1, t2, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    blt   t0, t1, BltTaken
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
BltTaken:
    addi  s0, s0, 1
    blt   t1, t0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    blt   t1, t2, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    bge   t1, t0, BgeTaken
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
BgeTaken:
    addi  s0, s0, 1
    bge   t1, t2, BgeEq
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
BgeEq:
    addi  s0, s0, 1
    bge   t0, t1, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    bltu  t1, t0, BltuTaken
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
BltuTaken:
    addi  s0, s0, 1
    bltu  t0, t1, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    bltu  t1, t2, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    bgeu  t0, t1, BgeuTaken
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
BgeuTaken:
    addi  s0, s0, 1
    bgeu  t1, t2, BgeuEq
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
BgeuEq:
    addi  s0, s0, 1
    bgeu  t1, t0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    addi  t3, x0, 4
    addi  t4, x0, 0
Loop:
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi  t4, t4, 2
    addi  t3, t3, -1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    bne   t3, x0, Loop
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    jal   t5, JalTarget
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
JalTarget:
    addi  s0, s0, 1
    lui t6, %hi(JalrFunc)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t6, t6, %lo(JalrFunc)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    jalr ra, 0(t6)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    jal x0, CallTest
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
JalrBase:
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
JalrFunc:
    addi  s0, s0, 1
    jalr  x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
CallTest:
    addi  a0, x0, 7
    jal   ra, Rsum
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  t0, x0, 28
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    bne   a0, t0, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    lui   t1, 0x7FFFF
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi  t1, t1, -4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    bne   sp, t1, Fail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  s0, s0, 1
    jal x0, Done
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
Fail:
    addi  s11, x0, -1
    jal x0, Done
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
Rsum:
    addi  sp, sp, -8
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw    ra, 4(sp)
    sw    a0, 0(sp)
    beq   a0, x0, RsumBase
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi  a0, a0, -1
    jal   ra, Rsum
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    lw    t0, 0(sp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add   a0, a0, t0
RsumBase:
    lw    ra, 4(sp)
    addi  sp, sp, 8
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    jalr  x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
Done:
    wfi
