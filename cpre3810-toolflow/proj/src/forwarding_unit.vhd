-------------------------------------------------------------------------
-- forwarding_unit.vhd
-- Hardware-scheduled pipeline: decides where the EX stage ALU operands
-- come from, so dependent back-to-back instructions get the newest value.
--
-- o_fwd_a (for rs1) / o_fwd_b (for rs2):
--   "00" = use the register file value (from ID/EX)
--   "01" = forward from WB  (the instruction 2 ahead)
--   "10" = forward from MEM (the instruction 1 ahead) <- newest, so it wins
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity forwarding_unit is
  port (
    i_ex_rs1        : in  std_logic_vector(4 downto 0);  -- e_rs1
    i_ex_rs2        : in  std_logic_vector(4 downto 0);  -- e_rs2
    i_mem_rd        : in  std_logic_vector(4 downto 0);  -- m_rd
    i_mem_reg_write : in  std_logic;                     -- m_reg_write
    i_wb_rd         : in  std_logic_vector(4 downto 0);  -- w_rd
    i_wb_reg_write  : in  std_logic;                     -- w_reg_write
    o_fwd_a         : out std_logic_vector(1 downto 0);
    o_fwd_b         : out std_logic_vector(1 downto 0)
  );
end entity;

architecture dataflow of forwarding_unit is
begin

  -- TODO: o_fwd_a
  --   "10" when MEM writes a register, it isn't x0, and it equals rs1
  --   else "01" when WB writes a register, it isn't x0, and it equals rs1
  --   else "00"
  o_fwd_a <= "10" when (i_mem_reg_write = '1' and i_mem_rd /= "00000" and i_mem_rd = i_ex_rs1) else
           "01" when (i_wb_reg_write = '1' and i_wb_rd /= "00000" and i_wb_rd = i_ex_rs1) else
           "00";

  -- TODO: o_fwd_b  (same thing, but compare against rs2)
o_fwd_b <= "10" when (i_mem_reg_write = '1' and i_mem_rd /= "00000" and i_mem_rd = i_ex_rs2) else
           "01" when (i_wb_reg_write = '1' and i_wb_rd /= "00000" and i_wb_rd = i_ex_rs2) else
           "00";
end architecture;