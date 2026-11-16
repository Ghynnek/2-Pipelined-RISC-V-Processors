# Questa GUI: cd to cpre3810-toolflow/proj, then:
#   set program proj1_mergesort_sw
#   do test/demo_sw.do
# program may also be proj1_base_test_sw, proj1_cf_test_sw, or grendel_sw.
if {![info exists program]} {set program proj1_mergesort_sw}
do test/compile_sw.do
vsim -voptargs=+acc -wlf ${program}.wlf work.tb_sw_demo
log -r /*
set cpu sim:/tb_sw_demo/MyRiscv
add wave -group Clock $cpu/iCLK $cpu/iRST
add wave -hex -group IF $cpu/s_PC $cpu/s_Inst
add wave -hex -group ID $cpu/d_pc $cpu/d_inst $cpu/d_reg_read1 $cpu/d_reg_read2
add wave -hex -group EX $cpu/e_pc $cpu/e_imm $cpu/e_reg_read1 $cpu/e_reg_read2 $cpu/x_alu_result
add wave -group EX $cpu/e_branch $cpu/e_jump $cpu/e_jump_reg
add wave -hex -group MEM $cpu/s_DMemWr $cpu/s_DMemAddr $cpu/s_DMemData $cpu/s_DMemBE
add wave -hex -group WB $cpu/s_RegWr $cpu/s_RegWrAddr $cpu/s_RegWrData $cpu/s_Halt
mem load -infile validation/$program/imem.hex -format hex $cpu/IMem
if {[file size validation/$program/dmem.hex] > 0} {
  mem load -infile validation/$program/dmem.hex -format hex $cpu/DMem
}
run 10 ms
wave zoom full
# Simulation halts at WFI in WB. The .wlf remains in the proj directory.
