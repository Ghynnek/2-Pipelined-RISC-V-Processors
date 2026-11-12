.data
test_data: .word 0x11223344, 0x55667788

.text
main:
    lui  x5, 0x10010
    addi x5, x5, 0

    li   x6, 0xDEADBEEF
    sw   x6, 0(x5)        

    li   x7, 0x1234
    sh   x7, 0(x5)         

    li   x8, 0xAB
    sb   x8, 2(x5)          # Store byte at offset 2


    li   x10, 5
    li   x11, 10
    blt  x10, x11, branch_target  
    
    li   x12, 99
    j    end_test

branch_target:
    li   x12, 1

end_test:
    wfi
