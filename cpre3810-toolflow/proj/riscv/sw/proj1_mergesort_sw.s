# Software schedule: 3 intervening instructions for RAW; 2 NOPs after EX redirects.
# Generated from proj1_mergesort.s by scripts/schedule_sw.py.
# Original arithmetic result comments are omitted because PC-relative values move.
# Proj1_mergesort.s
# Author: Alex Anderson (Team E_08)
# Built from Proj_sort_template.s (Tyler Bibus).
# Top-down recursive merge sort (ascending, signed, stable).
# The sorted values are written back into the original array.

# Note: You MUST put the sorted array back in the SAME memory location as the original array.
#       During grading we will insert our own array and corresponding array_size for testing.
#       The max size will be 512 elements.
.data
    array_size: .word 12
    array: .word 65, 12, 10, 89, 11, 70, 67, 5, 9, 45, 90, 7
    # Scratch buffer for merging. Only the left half of a merge is copied
    # here, so 256 words covers the 512-element maximum. Keeping it small
    # matters: data memory is 1024 words and the stack shares it.
    MergeTemp: .space 1024
.text
main:
    lui sp, 0x7FFFF
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi sp, sp, -4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi sp, sp, -4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw ra, 0(sp)
    lui a0, %hi(array)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi a0, a0, %lo(array)
    lui a1, %hi(array_size)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw a1, %lo(array_size)(a1)
    jal ra, sort
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    lw ra, 0(sp)
    addi sp, sp, 4
    jal x0, Exit
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
sort:
    addi sp, sp, -4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   ra, 0(sp)
    addi t0, x0, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    blt  a1, t0, SortDone
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi a2, a1, -1
    addi a1, x0, 0
    jal  ra, Msort
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
SortDone:
    lw   ra, 0(sp)
    addi sp, sp, 4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
Msort:
    bge  a1, a2, MsortRet
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    addi sp, sp, -16
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   ra, 12(sp)
    sw   a1, 8(sp)
    sw   a2, 4(sp)
    add  t0, a1, a2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    srai t0, t0, 1
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t0, 0(sp)
    addi a2, t0, 0
    jal  ra, Msort
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    lw   a1, 0(sp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi a1, a1, 1
    lw   a2, 4(sp)
    jal  ra, Msort
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    lw   a1, 8(sp)
    lw   a2, 0(sp)
    lw   a3, 4(sp)
    jal  ra, Merge
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    lw   ra, 12(sp)
    addi sp, sp, 16
MsortRet:
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
Merge:
    lui t6, %hi(MergeTemp)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    addi t6, t6, %lo(MergeTemp)
    sub  a4, a2, a1
    addi t0, x0, 0
    slli t3, a1, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, a0, t3
MergeSave:
    blt  a4, t0, MergeStart
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    slli t4, t0, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t5, t3, t4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t5, 0(t5)
    add  t4, t6, t4
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t5, 0(t4)
    addi t0, t0, 1
    jal x0, MergeSave
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
MergeStart:
    addi t0, x0, 0
    addi t1, a2, 1
    addi t2, a1, 0
MergeLoop:
    nop    # RAW spacing across all modeled incoming paths
    blt  a4, t0, MergeDone
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    blt  a3, t1, MergeLeft
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    slli t3, t0, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, t6, t3
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t4, 0(t3)
    slli t3, t1, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, a0, t3
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t5, 0(t3)
    slli t3, t2, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, a0, t3
    blt  t5, t4, TakeRight
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    sw   t4, 0(t3)
    addi t0, t0, 1
    jal x0, MergeNext
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
TakeRight:
    sw   t5, 0(t3)
    addi t1, t1, 1
MergeNext:
    addi t2, t2, 1
    jal x0, MergeLoop
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
MergeLeft:
    blt  a4, t0, MergeDone
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    slli t3, t0, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, t6, t3
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t4, 0(t3)
    slli t3, t2, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, a0, t3
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t4, 0(t3)
    addi t0, t0, 1
    addi t2, t2, 1
    jal x0, MergeLeft
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
MergeDone:
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
Exit:
    wfi
