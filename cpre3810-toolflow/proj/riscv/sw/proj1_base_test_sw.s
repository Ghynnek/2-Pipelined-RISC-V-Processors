# Software schedule: 3 intervening instructions for RAW; 2 NOPs after EX redirects.
# Generated from proj1_base_test.s by scripts/schedule_sw.py.
# Original arithmetic result comments are omitted because PC-relative values move.
# Proj1_base_test.s
# Author: Alex Anderson (Team E_08)
# Uses every required arithmetic/logical instruction at least once:
#   add, addi, and, andi, lui, xor, xori, or, ori, slt, slti, sltiu, sltu,
#   sll, srl, sra, slli, srli, srai, sub, auipc
# followed by the memory instructions:
#   sw, lw, lb, lh, lbu, lhu, sb, sh
# Instructions run back-to-back, one per cycle, and most results are read
# by the very next instruction, so a wrong register write shows up quickly.
# Expected results are in the comments next to each instruction.
# Sections are ordered from basic to more advanced so the first mismatch
# reported by the toolflow points at the part of the datapath that broke.

.data
BaseWord0: .word 0x12345678        # bytes (LE): 78 56 34 12
BaseWord1: .word 0xFFFF8080        # bytes (LE): 80 80 FF FF
BaseStore: .word 0                 # sw target
BaseSub:   .word 0                 # sb / sh target

.text
main:
    lui   s0, 0x12345
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi  s0, s0, 0x678
    addi  t0, x0, -1
    addi  t1, x0, 7
    addi  t2, x0, 2047
    addi  t3, x0, -2048
    addi  t4, x0, 1024
    lui   t5, 0xFFFFF
    andi  a0, s0, 0x0FF
    andi  a1, s0, -16
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    ori   a2, a0, 0x700
    ori   a3, x0, -1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    xori  a4, a2, -1
    xori  a5, s0, 0x0F0
    slti  a6, t3, 0
    slti  a7, t2, -1
    slti  s1, t1, 7
    sltiu s2, t1, -1
    sltiu s3, t0, 5
    sltiu s4, x0, 1
    slli  s5, t1, 4
    slli  s6, t0, 31
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    srli  s7, s6, 31
    srai  s8, s6, 31
    srai  s9, s0, 4
    srli  s10, t0, 0
    srai  s11, t5, 12
    srli  s11, t5, 12
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slli  s11, s11, 1
    add   a0, s0, t1
    add   a1, t0, t1
    lui   a2, 0x80000
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi  a2, a2, -1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add   a3, a2, s7
    sub   a4, t1, s0
    sub   a5, x0, t1
    sub   a6, s0, s0
    nop    # RAW spacing across all modeled incoming paths
    and   a7, s0, a4
    or    s1, s5, a0
    or    s2, a3, t1
    xor   s3, s0, t0
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    xor   s4, s3, s3
    slt   s5, t3, t1
    slt   s6, t1, t3
    slt   s7, a3, a2
    sltu  s8, t1, t3
    sltu  s9, t3, t1
    sltu  s10, a2, a3
    slt   s11, t1, t1
    addi  t2, x0, 33
    sll   t4, s0, t1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sll   t4, s0, t2
    srl   t5, a4, t1
    sra   t6, a4, t1
    sra   t6, s0, t1
    addi  t2, x0, 31
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sra   a0, a3, t2
    srl   a1, a3, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sll   a1, a1, t2
    lui   s0, 0x10010
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw    t0, 0(s0)
    lw    t1, 4(s0)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add   t2, t0, t1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw    t2, 8(s0)
    lw    t3, 8(s0)
    addi  s1, s0, 12
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw    t1, -4(s1)
    lw    t4, -4(s1)
    lb    a0, 0(s0)
    lb    a1, 1(s0)
    lb    a2, 2(s0)
    lb    a3, 3(s0)
    lb    a4, 4(s0)
    lbu   a5, 4(s0)
    lb    a6, 7(s0)
    lbu   a7, 7(s0)
    lh    s2, 0(s0)
    lh    s3, 2(s0)
    lh    s4, 4(s0)
    lhu   s5, 4(s0)
    lh    s6, 6(s0)
    lhu   s7, 6(s0)
    sw    x0, 0(s1)
    addi  t0, x0, 0x0AB
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sb    t0, 0(s1)
    addi  t0, x0, 0x0CD
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sb    t0, 3(s1)
    lui   t0, 0x12345
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi  t0, t0, -273
    lw    s8, 0(s1)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sh    t0, 2(s1)
    lw    s9, 0(s1)
    sh    t0, 0(s1)
    lw    s9, 0(s1)
    auipc s10, 0
    auipc s11, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sub   s11, s11, s10
    wfi
