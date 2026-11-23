.data
.text
.globl main

# hw test 1 - MEM -> EX forwarding on rs1
# each instruction uses the result of the one right before it (no gap)

main:
    addi x1, x0, 5      # x1 = 5
    addi x2, x1, 3      # x2 = 5 + 3 = 8.  x1 is still in MEM -> must forward
    addi x3, x2, 1      # x3 = 8 + 1 = 9.  forward again (chain)
    add  x4, x3, x0     # x4 = 9.          forward into an R-type
    sub  x5, x4, x1     # x5 = 9 - 5 = 4.  rs1 from MEM, rs2 (x1) is old, read normally

    wfi
