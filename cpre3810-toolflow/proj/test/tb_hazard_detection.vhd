-------------------------------------------------------------------------
-- tb_hazard_detection.vhd
-- Project Part 2, step 2(b)v / 2(c): test the hazard detection unit by itself.
--
-- Load-use hazard  -> stall PC, stall IF/ID, flush ID/EX (bubble)
-- Branch/jump taken -> flush IF/ID, flush ID/EX (throw away wrong path)
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_hazard_detection is
end tb_hazard_detection;

architecture behavior of tb_hazard_detection is

  component hazard_detection is
    port (
      i_id_rs1      : in  std_logic_vector(4 downto 0);
      i_id_rs2      : in  std_logic_vector(4 downto 0);
      i_ex_rd       : in  std_logic_vector(4 downto 0);
      i_ex_mem_read : in  std_logic;
      i_pc_redirect : in  std_logic;
      o_pc_stall    : out std_logic;
      o_ifid_stall  : out std_logic;
      o_ifid_flush  : out std_logic;
      o_idex_flush  : out std_logic
    );
  end component;

  signal s_rs1, s_rs2, s_ex_rd : std_logic_vector(4 downto 0) := "00000";
  signal s_load, s_redirect : std_logic := '0';
  signal s_pc_stall, s_ifid_stall, s_ifid_flush, s_idex_flush : std_logic;

begin

  DUT: hazard_detection port map(
    i_id_rs1 => s_rs1, i_id_rs2 => s_rs2, i_ex_rd => s_ex_rd,
    i_ex_mem_read => s_load, i_pc_redirect => s_redirect,
    o_pc_stall => s_pc_stall, o_ifid_stall => s_ifid_stall,
    o_ifid_flush => s_ifid_flush, o_idex_flush => s_idex_flush);

  P_TEST: process
    variable v_errors : integer := 0;

    -- set inputs, then check the 4 outputs:
    --   exp = (pc_stall, ifid_stall, ifid_flush, idex_flush)
    procedure run(constant name : in string;
                  constant rs1, rs2, ex_rd : in std_logic_vector(4 downto 0);
                  constant load, redirect : in std_logic;
                  constant exp : in std_logic_vector(3 downto 0)) is
      variable got : std_logic_vector(3 downto 0);
    begin
      s_rs1 <= rs1; s_rs2 <= rs2; s_ex_rd <= ex_rd;
      s_load <= load; s_redirect <= redirect;
      wait for 10 ns;
      got := s_pc_stall & s_ifid_stall & s_ifid_flush & s_idex_flush;
      if got /= exp then
        report "FAIL: " & name &
               "  got pc_stall=" & std_logic'image(s_pc_stall) &
               " ifid_stall=" & std_logic'image(s_ifid_stall) &
               " ifid_flush=" & std_logic'image(s_ifid_flush) &
               " idex_flush=" & std_logic'image(s_idex_flush) severity error;
        v_errors := v_errors + 1;
      else
        report "pass: " & name;
      end if;
    end procedure;

  begin
    --  name                                         rs1      rs2      ex_rd    load redir  expected (pcS,ifidS,ifidF,idexF)
    run("1. no hazard",                             "00001", "00010", "00011", '0', '0',  "0000");
    run("2. EX is ALU op, reg matches: no stall",   "00011", "00010", "00011", '0', '0',  "0000");
    run("3. load-use on rs1",                       "00101", "00010", "00101", '1', '0',  "1101");
    run("4. load-use on rs2",                       "00001", "00101", "00101", '1', '0',  "1101");
    run("5. load-use on both rs1 and rs2",          "00101", "00101", "00101", '1', '0',  "1101");
    run("6. load but no reg match",                 "00001", "00010", "00101", '1', '0',  "0000");
    run("7. load into x0: never stall",             "00000", "00000", "00000", '1', '0',  "0000");
    run("8. branch taken / jump",                   "00001", "00010", "00011", '0', '1',  "0011");
    run("9. jump + load-use: flush wins, no stall", "00101", "00010", "00101", '1', '1',  "0011");

    if v_errors = 0 then
      report "ALL HAZARD DETECTION TESTS PASSED";
    else
      report integer'image(v_errors) & " TEST(S) FAILED" severity error;
    end if;
    wait;
  end process;

end behavior;
