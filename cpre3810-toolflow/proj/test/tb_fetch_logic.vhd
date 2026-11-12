-------------------------------------------------------------------------
-- tb_fetch_logic.vhd
-- Testbench for fetch_logic.vhd (Part 3.2.c)
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity tb_fetch_logic is
end tb_fetch_logic;

architecture behavior of tb_fetch_logic is

  component fetch_logic is
    port (
      clk, reset            : in  std_logic;
      imm                   : in  std_logic_vector(31 downto 0);
      alu_result            : in  std_logic_vector(31 downto 0);
      zero                  : in  std_logic;
      funct3                : in  std_logic_vector(2 downto 0);
      Branch, Jump, JumpReg : in  std_logic;
      pc                    : out std_logic_vector(31 downto 0);
      pc_plus4              : out std_logic_vector(31 downto 0)
    );
  end component;

  signal s_clk        : std_logic := '0';
  signal s_reset      : std_logic := '1';
  signal s_imm        : std_logic_vector(31 downto 0) := (others => '0');
  signal s_alu_result : std_logic_vector(31 downto 0) := (others => '0');
  signal s_zero       : std_logic := '0';
  signal s_funct3     : std_logic_vector(2 downto 0) := "000";
  signal s_Branch     : std_logic := '0';
  signal s_Jump       : std_logic := '0';
  signal s_JumpReg    : std_logic := '0';
  signal s_pc         : std_logic_vector(31 downto 0);
  signal s_pc_plus4   : std_logic_vector(31 downto 0);

  constant c_CLK_PERIOD : time := 10 ns;

begin

  DUT: fetch_logic
    port map (
      clk        => s_clk,
      reset      => s_reset,
      imm        => s_imm,
      alu_result => s_alu_result,
      zero       => s_zero,
      funct3     => s_funct3,
      Branch     => s_Branch,
      Jump       => s_Jump,
      JumpReg    => s_JumpReg,
      pc         => s_pc,
      pc_plus4   => s_pc_plus4
    );

  p_clk: process
  begin
    s_clk <= '0';
    wait for c_CLK_PERIOD / 2;
    s_clk <= '1';
    wait for c_CLK_PERIOD / 2;
  end process;

  p_stim: process
  begin
    -- 1. Hardware Reset (PC initializes to 0x00400000)
    s_reset <= '1';
    wait for c_CLK_PERIOD;
    s_reset <= '0';

    -- 2. Sequential PC + 4 execution (3 cycles: 0x00400004, 0x00400008, 0x0040000C)
    wait for c_CLK_PERIOD * 3;

    -- 3. Conditional Branch BEQ Not Taken (zero = '0', PC increments by 4)
    s_Branch <= '1';
    s_funct3 <= "000"; -- BEQ
    s_zero   <= '0';
    s_imm    <= x"00000020"; -- +32 offset
    wait for c_CLK_PERIOD;

    -- 4. Conditional Branch BEQ Taken (zero = '1', PC jumps by +0x20)
    s_zero   <= '1';
    wait for c_CLK_PERIOD;

    -- 5. Conditional Branch BNE Taken (funct3 = 001, zero = '0', PC jumps by +0x10)
    s_funct3 <= "001"; -- BNE
    s_zero   <= '0';
    s_imm    <= x"00000010";
    wait for c_CLK_PERIOD;

    -- 6. Conditional Branch BLT Taken (funct3 = 100, alu_result(0) = '1')
    s_funct3     <= "100"; -- BLT
    s_alu_result <= x"00000001";
    s_imm        <= x"00000014";
    wait for c_CLK_PERIOD;

    -- 7. Conditional Branch BGE Taken (funct3 = 101, alu_result(0) = '0')
    s_funct3     <= "101"; -- BGE
    s_alu_result <= x"00000000";
    s_imm        <= x"00000008";
    wait for c_CLK_PERIOD;

    -- 8. Unconditional JAL (Jump = '1', PC = PC + imm)
    s_Branch <= '0';
    s_Jump   <= '1';
    s_imm    <= x"00000100";
    wait for c_CLK_PERIOD;

    -- 9. Unconditional JALR (JumpReg = '1', PC = alu_result & ~1)
    s_Jump       <= '0';
    s_JumpReg    <= '1';
    s_alu_result <= x"00400051"; -- LSB '1' cleared to 0x00400050
    wait for c_CLK_PERIOD;

    -- 10. Return to sequential execution
    s_JumpReg <= '0';
    wait for c_CLK_PERIOD * 2;

    wait;
  end process;

end behavior;