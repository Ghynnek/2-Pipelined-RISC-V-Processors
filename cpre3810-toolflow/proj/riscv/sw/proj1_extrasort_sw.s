# Software schedule: 3 intervening instructions for RAW; 2 NOPs after EX redirects.
# Generated from proj1_extrasort.s by scripts/schedule_sw.py.
# Original arithmetic result comments are omitted because PC-relative values move.
# Proj1_extrasort.s
# Author: Alex Anderson (Team E_08)
# Built from Proj_sort_template.s (Tyler Bibus).
# Insertion sort (ascending, signed). Required extra algorithm for teams of 3
# (not Bubble Sort or Merge Sort). It sorts in place, so it needs no scratch
# memory and no recursion, which keeps it safe for the 512-element maximum.

# Note: You MUST put the sorted array back in the SAME memory location as the original array.
#       During grading we will insert our own array and corresponding array_size for testing.
#       The max size will be 512 elements.
.data
    array_size: .word 12
    array: .word 65, 12, 10, 89, 11, 70, 67, 5, 9, 45, 90, 7
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
    addi t0, x0, 1
OuterLoop:
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    bge  t0, a1, SortDone
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    slli t3, t0, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, a0, t3
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t2, 0(t3)
    addi t1, t0, -1
InnerLoop:
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    blt  t1, x0, Insert
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    slli t3, t1, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, a0, t3
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    lw   t4, 0(t3)
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    bge  t2, t4, Insert
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
    sw   t4, 4(t3)
    addi t1, t1, -1
    jal x0, InnerLoop
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
Insert:
    slli t3, t1, 2
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    add  t3, a0, t3
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    nop    # RAW spacing across all modeled incoming paths
    sw   t2, 4(t3)
    addi t0, t0, 1
    jal x0, OuterLoop
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
SortDone:
    jalr x0, 0(ra)
    nop    # EX control-transfer spacing
    nop    # EX control-transfer spacing
Exit:
    wfi
