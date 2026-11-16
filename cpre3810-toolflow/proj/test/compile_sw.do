# Run from cpre3810-toolflow/proj, not the repository root.
# Only compile src; src_sw is an archival copy with the same entity names.
onerror {abort all}
if {![file isdirectory work]} {vlib work}
vmap work work
vcom -2008 src/RISCV_types.vhd
vcom -2008 src/Adder_Files/andg2.vhd
vcom -2008 src/Adder_Files/org2.vhd
vcom -2008 src/Adder_Files/xorg2.vhd
vcom -2008 src/Adder_Files/FullAdder.vhd
vcom -2008 src/Adder_Files/Adder_n.vhd
vcom -2008 src/dffg.vhd
vcom -2008 src/dffg_set.vhd
vcom -2008 src/reg_n.vhd
vcom -2008 src/decoder.vhd
vcom -2008 src/32to1mux.vhd
vcom -2008 src/reg_file.vhd
vcom -2008 src/mux2_32.vhd
vcom -2008 src/mux4_32.vhd
vcom -2008 src/barrel_shifter.vhd
vcom -2008 src/alu.vhd
vcom -2008 src/imm_gen.vhd
vcom -2008 src/fetch_logic.vhd
vcom -2008 src/fetch_logic_sw.vhd
vcom -2008 src/Control_Unit.vhd
vcom -2008 src/writeback_select.vhd
vcom -2008 src/pipeline_regs.vhd
vcom -2008 src/TopLevel/mem.vhd
vcom -2008 src/TopLevel/RISCV_Processor.vhd
vcom -2008 test/tb_sw_demo.vhd
