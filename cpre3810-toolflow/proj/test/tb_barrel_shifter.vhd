-------------------------------------------------------------------------
-- tb_barrel_shifter.vhd
-- Testbench for your exact barrel_shifter.vhd implementation (Part 3.3.1.d)
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity tb_barrel_shifter is
end tb_barrel_shifter;

architecture behavior of tb_barrel_shifter is

  component barrel_shifter is
    port (
      data_in     : in  std_logic_vector(31 downto 0);
      shamt       : in  std_logic_vector(4 downto 0);
      shift_right : in  std_logic;
      arithmetic  : in  std_logic;
      data_out    : out std_logic_vector(31 downto 0)
    );
  end component;

  signal s_data_in     : std_logic_vector(31 downto 0) := (others => '0');
  signal s_shamt       : std_logic_vector(4 downto 0)  := (others => '0');
  signal s_shift_right : std_logic := '0';
  signal s_arithmetic  : std_logic := '0';
  signal s_data_out    : std_logic_vector(31 downto 0);

begin

  DUT: barrel_shifter
    port map (
      data_in     => s_data_in,
      shamt       => s_shamt,
      shift_right => s_shift_right,
      arithmetic  => s_arithmetic,
      data_out    => s_data_out
    );

  process
  begin
    -- =======================================================================
    -- 1. Logical Left Shift (SLL: shift_right = '0', arithmetic = '0')
    -- =======================================================================
    s_shift_right <= '0';
    s_arithmetic  <= '0';
    s_data_in     <= x"00000001";

    s_shamt <= "00000"; -- Shift left by 0  -> 0x00000001
    wait for 10 ns;

    s_shamt <= "00100"; -- Shift left by 4  -> 0x00000010
    wait for 10 ns;

    s_shamt <= "10000"; -- Shift left by 16 -> 0x00010000
    wait for 10 ns;

    s_shamt <= "11111"; -- Shift left by 31 -> 0x80000000
    wait for 10 ns;

    s_data_in <= x"12345678";
    s_shamt   <= "01000"; -- Shift left by 8  -> 0x34567800
    wait for 10 ns;

    -- =======================================================================
    -- 2. Logical Right Shift (SRL: shift_right = '1', arithmetic = '0')
    -- =======================================================================
    s_shift_right <= '1';
    s_arithmetic  <= '0';
    s_data_in     <= x"F0F0F0F0";

    s_shamt <= "00000"; -- Shift right by 0  -> 0xF0F0F0F0
    wait for 10 ns;

    s_shamt <= "00001"; -- Shift right by 1  -> 0x78787878 (filled with '0')
    wait for 10 ns;

    s_shamt <= "00100"; -- Shift right by 4  -> 0x0F0F0F0F (filled with '0')
    wait for 10 ns;

    s_shamt <= "10000"; -- Shift right by 16 -> 0x0000F0F0
    wait for 10 ns;

    s_shamt <= "11111"; -- Shift right by 31 -> 0x00000001
    wait for 10 ns;

    -- =======================================================================
    -- 3. Arithmetic Right Shift (SRA: shift_right = '1', arithmetic = '1')
    -- =======================================================================
    s_shift_right <= '1';
    s_arithmetic  <= '1';

    -- Negative operand (MSB = '1'): fills upper vacated bits with '1's
    s_data_in <= x"F0F0F0F0";
    s_shamt   <= "00100"; -- Shift right by 4 -> 0xFF0F0F0F (sign-extended)
    wait for 10 ns;

    s_data_in <= x"80000000";
    s_shamt   <= "11111"; -- Shift right by 31 -> 0xFFFFFFFF
    wait for 10 ns;

    -- Positive operand (MSB = '0'): fills upper vacated bits with '0's
    s_data_in <= x"70F0F0F0";
    s_shamt   <= "00100"; -- Shift right by 4 -> 0x070F0F0F
    wait for 10 ns;

    wait;
  end process;

end behavior;