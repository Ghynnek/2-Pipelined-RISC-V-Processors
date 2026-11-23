.data
.text
.globl main

# hw test 2 - MEM -> EX forwarding on rs2
# the register written by the previous instruction is used as rs2

main:
    addi x1, x0, 5      # x1 = 5
    add  x2, x0, x1     # x2 = 0 + 5 = 5.  x1 is rs2, still in MEM -> must forward
    sub  x3, x0, x2     # x3 = 0 - 5 = -5 (0xfffffffb).  x2 is rs2, still in MEM
    sub  x4, x0, x3     # x4 = 0 - (-5) = 5.  x3 is rs2, still in MEM
    and  x5, x1, x4     # x5 = 5 AND 5 = 5.  x4 is rs2, still in MEM

    wfi
