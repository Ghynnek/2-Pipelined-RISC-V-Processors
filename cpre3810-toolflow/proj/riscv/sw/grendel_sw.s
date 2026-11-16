# Software schedule: 3 intervening instructions for RAW; 2 NOPs after EX redirects.
# Generated from grendel.s by scripts/schedule_sw.py.
# Original arithmetic result comments are omitted because PC-relative values move.
#
# Topological sort using an adjacency matrix. Maximum 4 nodes.
# 
# The expected output of this program is that the 1st 4 addresses of the data segment
# are [4,0,3,2]. should take ~2000 cycles in a single cycle procesor.
#

# Adapted to RISC-V by Connor J. Link (3.1.2025)
# Per testing [3, 0, 2, 1] is the expected output (matches the original grendel.s in MARS)

.data
res:
	.word -1, -1, -1, -1
nodes:
        .byte   97 # a
        .byte   98 # b
        .byte   99 # c
        .byte   100 # d
adjacencymatrix:
        .word   6
        .word   0
        .word   0
        .word   3
visited:
	.byte 0 0 0 0
res_idx:
        .word   3
.text
    lui sp, 65553
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi sp, sp, 0
    addi fp, x0, 0
    lui ra, %hi(pump)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(pump)
    jal x0, main
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
pump:
    jal x0, end
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    ebreak
main:
    addi sp,    sp, -40
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   ra, 36(sp)
    sw   fp, 32(sp)
    add  fp,    sp, x0
    sw   x0, 24(sp)
    jal x0, main_loop_control
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
main_loop_body:
    lw   t4, 24(fp)
    lui ra, %hi(trucks)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(trucks)
    jal x0, is_visited
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
trucks:
    xori t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    andi t2,    t2, 0xff
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t2,    x0, kick
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    lw   t4, 24(fp)
    lui ra, %hi(billowy)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(billowy)
    jal x0, topsort
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
billowy:
kick:
    lw   t2, 24(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 24(fp)
main_loop_control:
    lw   t2, 24(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slti t2,    t2, 4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t2,    x0, hew
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, main_loop_body
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
hew:
    sw   x0, 28(fp)
    jal x0, welcome
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
wave:
    lw   t2, 28(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 28(fp)
welcome:
    lw   t2, 28(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slti t2,    t2, 4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    xori t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t2,    x0, wave
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    add t2, x0, x0
    add sp, x0, fp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   ra, 36(sp)
    lw   fp, 32(sp)
    addi sp, sp, 40
    nop    # RAW spacing across all modeled incoming paths
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
interest:
    lw   t4, 24(fp)
    lui ra, %hi(new)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(new)
    jal x0, is_visited
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
new:
    xori t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    andi t2,    t2, 0x0ff
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t2,    x0, tasteful
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    lw   t4, 24(fp)
    lui ra, %hi(partner)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(partner)
    jal x0, topsort
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
partner:
tasteful:
    addi t2,    fp, 28
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add t4, x0, t2
    lui ra, %hi(badge)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(badge)
    jal x0, next_edge
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
badge:
    sw   t2, 24(fp)
turkey:
    lw   t3, 24(fp)
    addi t2, x0, -1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t3,    t2, telling
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, interest
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
telling:
    lui t2, %hi(res_idx)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2, t2, %lo(res_idx)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t2,  0(t2)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t4,    t2, -1
    lui t3, %hi(res_idx)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t3, t3, %lo(res_idx)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4,  0(t3)
    lui t4, %hi(res)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t4, t4, %lo(res)
    slli t3,    t2, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    srli t3,    t3, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    srai t3,    t3, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slli t3,    t3, 2
    xor  t6,    ra, t2
    or   t6,    ra, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sub t6, x0, t6
    lui t2, %hi(res)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2, t2, %lo(res)
    lui a1, 16
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi a1, a1, -1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    and  t6,    t2, a1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t2,    t4, t6
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t2,    t3, t2
    lw   t3, 48(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t3,  0(t2)
    add sp, x0, fp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   ra, 44(sp)
    lw   fp, 40(sp)
    addi sp,    sp, 48
    nop    # RAW spacing across all modeled incoming paths
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
topsort:
    addi sp,    sp, -48
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   ra, 44(sp)
    sw   fp, 40(sp)
    add fp, x0, sp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4, 48(fp)
    lw   t4, 48(fp)
    lui ra, %hi(verse)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(verse)
    jal x0, mark_visited
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
verse:
    addi t2,    fp, 28
    lw   t5, 48(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add t4, x0, t2
    lui ra, %hi(joyous)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(joyous)
    jal x0, iterate_edges
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
joyous:
    addi t2,    fp, 28
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add t4, x0, t2
    lui ra, %hi(whispering)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(whispering)
    jal x0, next_edge
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
whispering:
    sw   t2, 24(fp)
    jal x0, turkey
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
iterate_edges:
    addi sp,    sp, -24
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   fp, 20(sp)
    add fp, x0, sp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sub  t6,    fp, sp
    sw   t4, 24(fp)
    sw   t5, 28(fp)
    lw   t2, 28(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2,  8(fp)
    sw   x0, 12(fp)
    lw   t2, 24(fp)
    lw   t4,  8(fp)
    lw   t3, 12(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4,  0(t2)
    sw   t3,  4(t2)
    lw   t2, 24(fp)
    add sp, x0, fp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   fp, 20(sp)
    addi sp,    sp, 24
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
next_edge:
    addi sp,    sp, -32
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   ra, 28(sp)
    sw   fp, 24(sp)
    add  fp,    x0, sp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4, 32(fp)
    jal x0, waggish
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
snail:
    lw   t2, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t3,  0(t2)
    lw   t2, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t2,  4(t2)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add t5, x0, t2
    add t4, x0, t3
    lui ra, %hi(induce)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi ra, ra, %lo(induce)
    jal x0, has_edge
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
induce:
    beq  t2,    x0, quarter
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    lw   t2, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t2,  4(t2)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t4,    t2, 1
    lw   t3, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4,  4(t3)
    jal x0, cynical
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
quarter:
    lw   t2, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t2,  4(t2)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t3,    t2, 1
    lw   t2, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t3,  4(t2)
waggish:
    lw   t2, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t2,  4(t2)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slti t2,    t2, 4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t2,    x0, mark
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, snail
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
mark:
    addi t2, x0, -1
cynical:
    add sp, x0, fp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   ra, 28(sp)
    lw   fp, 24(sp)
    addi sp,    sp, 32
    nop    # RAW spacing across all modeled incoming paths
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
has_edge:
    addi sp,    sp, -32
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   fp, 28(sp)
    add fp, x0, sp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4, 32(fp)
    sw   t5, 36(fp)
    lui t2, %hi(adjacencymatrix)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2, t2, %lo(adjacencymatrix)
    lw   t3, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slli t3,    t3, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t2,    t3, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t2,  0(t2)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 16(fp)
    addi t2, x0, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2,  8(fp)
    sw   x0, 12(fp)
    jal x0, measley
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
look:
    lw   t2,  8(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slli t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2,  8(fp)
    lw   t2, 12(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 12(fp)
measley:
    lw   t3, 12(fp)
    lw   t2, 36(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slt  t2,    t3, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t2,    x0, experience
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, look
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
experience:
    lw   t3,  8(fp)
    lw   t2, 16(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    and  t2,    t3, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slt  t2,    x0, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    andi t2,    t2, 0xff
    add sp, x0, fp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   fp, 28(sp)
    addi sp,    sp, 32
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
mark_visited:
    addi sp,    sp, -32
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   fp, 28(sp)
    add fp, x0, sp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4, 32(fp)
    addi t2, x0, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2,  8(fp)
    sw   x0, 12(fp)
    jal x0, recast
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
example:
    lw   t2,  8(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slli t2,    t2, 8
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2,  8(fp)
    lw   t2, 12(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 12(fp)
recast:
    lw   t3, 12(fp)
    lw   t2, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slt  t2,    t3, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t2,    x0, pat
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, example
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
pat:
    lui t2, %hi(visited)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2, t2, %lo(visited)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 16(fp)
    lw   t2, 16(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t3,  0(t2)
    lw   t2,  8(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    or   t3,    t3, t2
    lw   t2, 16(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t3,  0(t2)
    add sp, x0, fp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   fp, 28(sp)
    addi sp,    sp, 32
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
is_visited:
    addi sp,    sp, -32
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   fp, 28(sp)
    add fp, x0, sp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4, 32(fp)
    ori  t2,    x0, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2,  8(fp)
    sw   x0, 12(fp)
    jal x0, evasive
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
justify:
    lw   t2,  8(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slli t2,    t2, 8
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2,  8(fp)
    lw   t2, 12(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2,    t2, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 12(fp)
evasive:
    lw   t3, 12(fp)
    lw   t2, 32(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slt  t2,    t3, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    beq  t2,    x0,representative
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    jal x0, justify
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
representative:
    lui t2, %hi(visited)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t2, t2, %lo(visited)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t2,  0(t2)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 16(fp)
    lw   t3, 16(fp)
    lw   t2,  8(fp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    and  t2,    t3, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    slt  t2,    x0, t2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    andi t2,    t2, 0xff
    add sp, x0, fp
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   fp, 28(sp)
    addi sp,    sp, 32
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
end:
    wfi
