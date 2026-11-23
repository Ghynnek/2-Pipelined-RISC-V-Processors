-------------------------------------------------------------------------
-- hazard_detection.vhd
-- Hardware-scheduled pipeline: decides when to stall and when to flush.
--
-- Load-use hazard: the instruction in EX is a load, and the instruction
--   in ID reads the register it loads into. The data isn't out of memory
--   yet, so forwarding can't help.
--   -> hold PC and IF/ID for one cycle, turn ID/EX into a bubble (NOP).
--
-- Control hazard: a branch is taken or a jump happens in EX. The two
--   instructions behind it (in IF and ID) are the wrong path.
--   -> flush IF/ID and ID/EX.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity hazard_detection is
  port (
    i_id_rs1      : in  std_logic_vector(4 downto 0);  -- d_inst(19 downto 15)
    i_id_rs2      : in  std_logic_vector(4 downto 0);  -- d_inst(24 downto 20)
    i_ex_rd       : in  std_logic_vector(4 downto 0);  -- e_rd
    i_ex_mem_read : in  std_logic;                     -- e_mem_to_reg ('1' = EX is a load)
    i_pc_redirect : in  std_logic;                     -- '1' = branch taken or jump in EX
    o_pc_stall    : out std_logic;
    o_ifid_stall  : out std_logic;
    o_ifid_flush  : out std_logic;
    o_idex_flush  : out std_logic
  );
end entity;

architecture dataflow of hazard_detection is
  signal s_load_use : std_logic;
begin

    s_load_use <= '1' when (i_ex_mem_read = '1' and i_ex_rd /= "00000" and (i_ex_rd = i_id_rs1 or i_ex_rd = i_id_rs2))else
    '0';

 
  o_pc_stall   <= s_load_use and not i_pc_redirect;
  o_ifid_stall <= s_load_use and not i_pc_redirect;
  o_ifid_flush <= i_pc_redirect;
  o_idex_flush <= s_load_use or i_pc_redirect;

end architecture;