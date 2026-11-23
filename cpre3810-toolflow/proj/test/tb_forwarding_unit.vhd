-------------------------------------------------------------------------
-- tb_forwarding_unit.vhd
-- Project Part 2, step 2(b)v: test the forwarding unit by itself.
--
-- Select encoding being checked:
--   "00" = no forward (use register file value)
--   "01" = forward from WB  (MEM/WB)
--   "10" = forward from MEM (EX/MEM)
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_forwarding_unit is
end tb_forwarding_unit;

architecture behavior of tb_forwarding_unit is

  component forwarding_unit is
    port (
      i_ex_rs1        : in  std_logic_vector(4 downto 0);
      i_ex_rs2        : in  std_logic_vector(4 downto 0);
      i_mem_rd        : in  std_logic_vector(4 downto 0);
      i_mem_reg_write : in  std_logic;
      i_wb_rd         : in  std_logic_vector(4 downto 0);
      i_wb_reg_write  : in  std_logic;
      o_fwd_a         : out std_logic_vector(1 downto 0);
      o_fwd_b         : out std_logic_vector(1 downto 0)
    );
  end component;

  signal s_rs1, s_rs2, s_mem_rd, s_wb_rd : std_logic_vector(4 downto 0) := "00000";
  signal s_mem_rw, s_wb_rw : std_logic := '0';
  signal s_fwd_a, s_fwd_b : std_logic_vector(1 downto 0);

begin

  DUT: forwarding_unit port map(
    i_ex_rs1 => s_rs1, i_ex_rs2 => s_rs2,
    i_mem_rd => s_mem_rd, i_mem_reg_write => s_mem_rw,
    i_wb_rd  => s_wb_rd,  i_wb_reg_write  => s_wb_rw,
    o_fwd_a  => s_fwd_a,  o_fwd_b => s_fwd_b);

  P_TEST: process
    variable v_errors : integer := 0;

    -- set inputs: rs1, rs2, mem_rd, mem_rw, wb_rd, wb_rw
    -- then check expected fwd_a and fwd_b
    procedure run(constant name : in string;
                  constant rs1, rs2, mrd : in integer; constant mrw : in std_logic;
                  constant wrd : in integer; constant wrw : in std_logic;
                  constant exp_a, exp_b : in std_logic_vector(1 downto 0)) is
      function v5(n : integer) return std_logic_vector is
        variable r : std_logic_vector(4 downto 0);
        variable x : integer := n;
      begin
        for i in 0 to 4 loop
          if (x mod 2) = 1 then r(i) := '1'; else r(i) := '0'; end if;
          x := x / 2;
        end loop;
        return r;
      end function;
    begin
      s_rs1 <= v5(rs1); s_rs2 <= v5(rs2);
      s_mem_rd <= v5(mrd); s_mem_rw <= mrw;
      s_wb_rd <= v5(wrd);  s_wb_rw <= wrw;
      wait for 10 ns;
      if s_fwd_a /= exp_a or s_fwd_b /= exp_b then
        report "FAIL: " & name & "  got A=" & to_string(s_fwd_a) & " B=" & to_string(s_fwd_b) &
               "  expected A=" & to_string(exp_a) & " B=" & to_string(exp_b) severity error;
        v_errors := v_errors + 1;
      else
        report "pass: " & name;
      end if;
    end procedure;

  begin
    --   name                                    rs1 rs2 mrd mrw  wrd wrw  A     B
    run("1. no hazard (nothing matches)",          1,  2,  3, '1',  4, '1', "00", "00");
    run("2. MEM -> rs1",                           5,  2,  5, '1',  4, '1', "10", "00");
    run("3. MEM -> rs2",                           1,  5,  5, '1',  4, '1', "00", "10");
    run("4. WB  -> rs1",                           6,  2,  3, '1',  6, '1', "01", "00");
    run("5. WB  -> rs2",                           1,  6,  3, '1',  6, '1', "00", "01");
    run("6. MEM -> both rs1 and rs2",              7,  7,  7, '1',  4, '1', "10", "10");
    run("7. MEM -> rs1, WB -> rs2",                8,  9,  8, '1',  9, '1', "10", "01");
    run("8. MEM and WB same reg: MEM wins",       10, 10, 10, '1', 10, '1', "10", "10");
    run("9. MEM match but reg_write=0",           11,  2, 11, '0',  4, '1', "00", "00");
    run("10. WB match but reg_write=0",           12,  2,  3, '1', 12, '0', "00", "00");
    run("11. MEM no write, WB match: WB",         13,  2, 13, '0', 13, '1', "01", "00");
    run("12. rd = x0 in MEM: never forward",       0,  0,  0, '1',  4, '1', "00", "00");
    run("13. rd = x0 in WB: never forward",        0,  0,  3, '1',  0, '1', "00", "00");

    if v_errors = 0 then
      report "ALL FORWARDING UNIT TESTS PASSED";
    else
      report integer'image(v_errors) & " TEST(S) FAILED" severity error;
    end if;
    wait;
  end process;

end behavior;
