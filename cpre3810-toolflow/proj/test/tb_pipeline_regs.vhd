-------------------------------------------------------------------------
-- tb_pipeline_regs.vhd
-- Project Part 2, Hardware-Scheduled Pipeline, step 2(a)iii
--
-- Chains IF/ID -> ID/EX -> EX/MEM -> MEM/WB into one design.
-- A value is pushed into IF/ID (on pc_plus4) and carried through all
-- four registers. reg_write is set to '1' going into ID/EX and carried
-- the rest of the way, so a flush (which clears control to '0') shows up.
--
-- Tests:
--   1. A value entering IF/ID comes out of MEM/WB four cycles later.
--   2. A new value can be inserted every cycle.
--   3. Each register can be stalled on its own (holds its value).
--   4. Each register can be flushed on its own (clears to 0 / NOP).
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_pipeline_regs is
end tb_pipeline_regs;

architecture behavior of tb_pipeline_regs is

  constant cCLK_PER : time := 20 ns;

  signal s_clk, s_rst : std_logic := '0';

  -- stall / flush for each register
  signal s_stall_ifid, s_flush_ifid : std_logic := '0';
  signal s_stall_idex, s_flush_idex : std_logic := '0';
  signal s_stall_exmem, s_flush_exmem : std_logic := '0';
  signal s_stall_memwb, s_flush_memwb : std_logic := '0';

  -- value pushed into IF/ID
  signal s_in : std_logic_vector(31 downto 0) := (others => '0');

  -- outputs of each register (the value being carried)
  signal s_ifid_out, s_idex_out, s_exmem_out, s_memwb_out : std_logic_vector(31 downto 0);
  signal s_ifid_inst : std_logic_vector(31 downto 0);
  -- reg_write carried from ID/EX onward
  signal s_idex_rw, s_exmem_rw, s_memwb_rw : std_logic;

  -- unused outputs
  signal u32_a, u32_b, u32_c, u32_d, u32_e, u32_f, u32_g, u32_h, u32_i, u32_j, u32_k : std_logic_vector(31 downto 0);
  signal u5_a, u5_b, u5_c, u5_d, u5_e : std_logic_vector(4 downto 0);
  signal u3_a, u3_b, u3_c : std_logic_vector(2 downto 0);
  signal u4_a : std_logic_vector(3 downto 0);
  signal u1 : std_logic_vector(0 to 19);

  component reg_IF_ID is
    port (i_clk, i_rst, i_stall, i_flush : in std_logic;
          i_pc, i_pc_plus4, i_inst : in std_logic_vector(31 downto 0);
          o_pc, o_pc_plus4, o_inst : out std_logic_vector(31 downto 0));
  end component;

  component reg_ID_EX is
    port (i_clk, i_rst, i_stall, i_flush : in std_logic;
          i_reg_write, i_alu_src, i_auipc, i_mem_write, i_mem_to_reg,
          i_branch, i_jump, i_jump_reg, i_lui, i_halt : in std_logic;
          i_alu_ctrl : in std_logic_vector(3 downto 0);
          i_pc, i_pc_plus4, i_reg_read1, i_reg_read2, i_imm : in std_logic_vector(31 downto 0);
          i_funct3 : in std_logic_vector(2 downto 0);
          i_rs1, i_rs2, i_rd : in std_logic_vector(4 downto 0);
          o_reg_write, o_alu_src, o_auipc, o_mem_write, o_mem_to_reg,
          o_branch, o_jump, o_jump_reg, o_lui, o_halt : out std_logic;
          o_alu_ctrl : out std_logic_vector(3 downto 0);
          o_pc, o_pc_plus4, o_reg_read1, o_reg_read2, o_imm : out std_logic_vector(31 downto 0);
          o_funct3 : out std_logic_vector(2 downto 0);
          o_rs1, o_rs2, o_rd : out std_logic_vector(4 downto 0));
  end component;

  component reg_EX_MEM is
    port (i_clk, i_rst, i_stall, i_flush : in std_logic;
          i_reg_write, i_mem_write, i_mem_to_reg, i_jump, i_jump_reg, i_lui, i_halt : in std_logic;
          i_pc_plus4, i_alu_result, i_reg_read2, i_imm : in std_logic_vector(31 downto 0);
          i_funct3 : in std_logic_vector(2 downto 0);
          i_rd : in std_logic_vector(4 downto 0);
          o_reg_write, o_mem_write, o_mem_to_reg, o_jump, o_jump_reg, o_lui, o_halt : out std_logic;
          o_pc_plus4, o_alu_result, o_reg_read2, o_imm : out std_logic_vector(31 downto 0);
          o_funct3 : out std_logic_vector(2 downto 0);
          o_rd : out std_logic_vector(4 downto 0));
  end component;

  component reg_MEM_WB is
    port (i_clk, i_rst, i_stall, i_flush : in std_logic;
          i_reg_write, i_mem_to_reg, i_jump, i_jump_reg, i_lui, i_halt : in std_logic;
          i_pc_plus4, i_alu_result, i_dmem_out, i_imm : in std_logic_vector(31 downto 0);
          i_funct3 : in std_logic_vector(2 downto 0);
          i_rd : in std_logic_vector(4 downto 0);
          o_reg_write, o_mem_to_reg, o_jump, o_jump_reg, o_lui, o_halt : out std_logic;
          o_pc_plus4, o_alu_result, o_dmem_out, o_imm : out std_logic_vector(31 downto 0);
          o_funct3 : out std_logic_vector(2 downto 0);
          o_rd : out std_logic_vector(4 downto 0));
  end component;

begin

  -- clock
  s_clk <= not s_clk after cCLK_PER/2;

  -- ===================== the four registers, chained =====================
  U_IF_ID: reg_IF_ID port map(
    i_clk => s_clk, i_rst => s_rst, i_stall => s_stall_ifid, i_flush => s_flush_ifid,
    i_pc => x"00000000", i_pc_plus4 => s_in, i_inst => x"00000033",
    o_pc => u32_a, o_pc_plus4 => s_ifid_out, o_inst => s_ifid_inst);

  U_ID_EX: reg_ID_EX port map(
    i_clk => s_clk, i_rst => s_rst, i_stall => s_stall_idex, i_flush => s_flush_idex,
    i_reg_write => '1', i_alu_src => '0', i_auipc => '0', i_mem_write => '0',
    i_mem_to_reg => '0', i_branch => '0', i_jump => '0', i_jump_reg => '0',
    i_lui => '0', i_halt => '0', i_alu_ctrl => "0000",
    i_pc => x"00000000", i_pc_plus4 => s_ifid_out, i_reg_read1 => x"00000000",
    i_reg_read2 => x"00000000", i_imm => x"00000000", i_funct3 => "000",
    i_rs1 => "00000", i_rs2 => "00000", i_rd => "00000",
    o_reg_write => s_idex_rw, o_alu_src => u1(0), o_auipc => u1(1), o_mem_write => u1(2),
    o_mem_to_reg => u1(3), o_branch => u1(4), o_jump => u1(5), o_jump_reg => u1(6),
    o_lui => u1(7), o_halt => u1(8), o_alu_ctrl => u4_a,
    o_pc => u32_b, o_pc_plus4 => s_idex_out, o_reg_read1 => u32_c, o_reg_read2 => u32_d,
    o_imm => u32_e, o_funct3 => u3_a, o_rs1 => u5_a, o_rs2 => u5_b, o_rd => u5_c);

  U_EX_MEM: reg_EX_MEM port map(
    i_clk => s_clk, i_rst => s_rst, i_stall => s_stall_exmem, i_flush => s_flush_exmem,
    i_reg_write => s_idex_rw, i_mem_write => '0', i_mem_to_reg => '0', i_jump => '0',
    i_jump_reg => '0', i_lui => '0', i_halt => '0',
    i_pc_plus4 => s_idex_out, i_alu_result => x"00000000", i_reg_read2 => x"00000000",
    i_imm => x"00000000", i_funct3 => "000", i_rd => "00000",
    o_reg_write => s_exmem_rw, o_mem_write => u1(9), o_mem_to_reg => u1(10), o_jump => u1(11),
    o_jump_reg => u1(12), o_lui => u1(13), o_halt => u1(14),
    o_pc_plus4 => s_exmem_out, o_alu_result => u32_f, o_reg_read2 => u32_g, o_imm => u32_h,
    o_funct3 => u3_b, o_rd => u5_d);

  U_MEM_WB: reg_MEM_WB port map(
    i_clk => s_clk, i_rst => s_rst, i_stall => s_stall_memwb, i_flush => s_flush_memwb,
    i_reg_write => s_exmem_rw, i_mem_to_reg => '0', i_jump => '0', i_jump_reg => '0',
    i_lui => '0', i_halt => '0',
    i_pc_plus4 => s_exmem_out, i_alu_result => x"00000000", i_dmem_out => x"00000000",
    i_imm => x"00000000", i_funct3 => "000", i_rd => "00000",
    o_reg_write => s_memwb_rw, o_mem_to_reg => u1(15), o_jump => u1(16), o_jump_reg => u1(17),
    o_lui => u1(18), o_halt => u1(19),
    o_pc_plus4 => s_memwb_out, o_alu_result => u32_i, o_dmem_out => u32_j, o_imm => u32_k,
    o_funct3 => u3_c, o_rd => u5_e);

  -- ============================== tests ==============================
  P_TEST: process
    variable v_errors : integer := 0;

    -- push a new value into IF/ID, then wait one clock edge
    procedure clock_in(constant val : in integer) is
    begin
      s_in <= std_logic_vector(to_unsigned(val, 32));
      wait until rising_edge(s_clk);
      wait for 1 ns;  -- let outputs settle
    end procedure;

    procedure check(constant name : in string;
                    constant got  : in std_logic_vector(31 downto 0);
                    constant exp  : in integer) is
    begin
      if got /= std_logic_vector(to_unsigned(exp, 32)) then
        report "FAIL: " & name & " = " & integer'image(to_integer(unsigned(got))) &
               " expected " & integer'image(exp) severity error;
        v_errors := v_errors + 1;
      end if;
    end procedure;

    procedure check_bit(constant name : in string;
                        constant got  : in std_logic;
                        constant exp  : in std_logic) is
    begin
      if got /= exp then
        report "FAIL: " & name & " = " & std_logic'image(got) &
               " expected " & std_logic'image(exp) severity error;
        v_errors := v_errors + 1;
      end if;
    end procedure;

  begin
    -- reset everything
    s_rst <= '1';
    wait for cCLK_PER * 2;
    s_rst <= '0';
    wait until falling_edge(s_clk);

    -- ------------------------------------------------------------------
    -- TEST 1 + 2: new value every cycle (1,2,3,...), each one comes out
    -- of MEM/WB four cycles after it went into IF/ID.
    -- ------------------------------------------------------------------
    report "TEST 1/2: value every cycle, 4-cycle latency";
    for i in 1 to 8 loop
      clock_in(i);
      check("IF/ID out", s_ifid_out, i);
      if i >= 2 then check("ID/EX out",  s_idex_out,  i-1); end if;
      if i >= 3 then check("EX/MEM out", s_exmem_out, i-2); end if;
      if i >= 4 then check("MEM/WB out", s_memwb_out, i-3); end if;
    end loop;
    -- now: IF/ID=8, ID/EX=7, EX/MEM=6, MEM/WB=5

    -- ------------------------------------------------------------------
    -- TEST 3: stall each register by itself for one cycle.
    -- The stalled register holds. Registers before it keep moving
    -- (the value they would have handed over is lost / overwritten).
    -- Registers after it receive the held value again.
    -- ------------------------------------------------------------------
    report "TEST 3a: stall IF/ID";
    s_stall_ifid <= '1';
    clock_in(9);                        -- 9 is NOT captured
    s_stall_ifid <= '0';
    check("IF/ID held", s_ifid_out, 8);
    check("ID/EX moved", s_idex_out, 8);
    check("EX/MEM moved", s_exmem_out, 7);
    check("MEM/WB moved", s_memwb_out, 6);

    report "TEST 3b: stall ID/EX";
    s_stall_idex <= '1';
    clock_in(10);
    s_stall_idex <= '0';
    check("IF/ID moved", s_ifid_out, 10);
    check("ID/EX held", s_idex_out, 8);
    check("EX/MEM moved", s_exmem_out, 8);
    check("MEM/WB moved", s_memwb_out, 7);

    report "TEST 3c: stall EX/MEM";
    s_stall_exmem <= '1';
    clock_in(11);
    s_stall_exmem <= '0';
    check("IF/ID moved", s_ifid_out, 11);
    check("ID/EX moved", s_idex_out, 10);
    check("EX/MEM held", s_exmem_out, 8);
    check("MEM/WB moved", s_memwb_out, 8);

    report "TEST 3d: stall MEM/WB";
    s_stall_memwb <= '1';
    clock_in(12);
    s_stall_memwb <= '0';
    check("IF/ID moved", s_ifid_out, 12);
    check("ID/EX moved", s_idex_out, 11);
    check("EX/MEM moved", s_exmem_out, 10);
    check("MEM/WB held", s_memwb_out, 8);

    -- refill the pipe with clean values
    for i in 13 to 16 loop clock_in(i); end loop;
    -- now: IF/ID=16, ID/EX=15, EX/MEM=14, MEM/WB=13

    -- ------------------------------------------------------------------
    -- TEST 4: flush each register by itself for one cycle.
    -- The flushed register becomes a NOP: value 0, reg_write 0,
    -- IF/ID instruction becomes addi x0,x0,0 (0x00000013).
    -- The others keep moving normally.
    -- ------------------------------------------------------------------
    report "TEST 4a: flush IF/ID";
    s_flush_ifid <= '1';
    clock_in(17);
    s_flush_ifid <= '0';
    check("IF/ID flushed", s_ifid_out, 0);
    check("IF/ID inst = NOP", s_ifid_inst, 16#13#);
    check("ID/EX moved", s_idex_out, 16);
    check("EX/MEM moved", s_exmem_out, 15);
    check("MEM/WB moved", s_memwb_out, 14);

    report "TEST 4b: flush ID/EX";
    s_flush_idex <= '1';
    clock_in(18);
    s_flush_idex <= '0';
    check("IF/ID moved", s_ifid_out, 18);
    check("ID/EX flushed", s_idex_out, 0);
    check_bit("ID/EX reg_write", s_idex_rw, '0');
    check("EX/MEM moved", s_exmem_out, 16);
    check("MEM/WB moved", s_memwb_out, 15);

    report "TEST 4c: flush EX/MEM";
    s_flush_exmem <= '1';
    clock_in(19);
    s_flush_exmem <= '0';
    check("IF/ID moved", s_ifid_out, 19);
    check("ID/EX moved", s_idex_out, 18);
    check("EX/MEM flushed", s_exmem_out, 0);
    check_bit("EX/MEM reg_write", s_exmem_rw, '0');
    check("MEM/WB moved", s_memwb_out, 16);

    report "TEST 4d: flush MEM/WB";
    s_flush_memwb <= '1';
    clock_in(20);
    s_flush_memwb <= '0';
    check("IF/ID moved", s_ifid_out, 20);
    check("ID/EX moved", s_idex_out, 19);
    check("EX/MEM moved", s_exmem_out, 18);
    check("MEM/WB flushed", s_memwb_out, 0);
    check_bit("MEM/WB reg_write", s_memwb_rw, '0');

    if v_errors = 0 then
      report "ALL PIPELINE REGISTER TESTS PASSED";
    else
      report integer'image(v_errors) & " TEST(S) FAILED" severity error;
    end if;
    wait;
  end process;

end behavior;
