-------------------------------------------------------------------------
-- barrel_shifter.vhd
-- 32-Bit Structural Barrel Shifter built from 1-bit 2:1 Multiplexers
-- Supports SLL (shift_right='0'), SRL (shift_right='1', arithmetic='0'),
-- and SRA (shift_right='1', arithmetic='1') via input/output bit-reversal
-- and a 5-stage right-shift multiplexer network.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

-- =========================================================================
-- Helper Component: 1-Bit 2-to-1 Multiplexer (Gate-Level)
-- =========================================================================
entity bs_mux2t1 is
  port (
    i_d0  : in  std_logic;
    i_d1  : in  std_logic;
    i_sel : in  std_logic;
    o_y   : out std_logic
  );
end entity bs_mux2t1;

architecture gate_level of bs_mux2t1 is
begin
  o_y <= (i_d0 and (not i_sel)) or (i_d1 and i_sel);
end architecture gate_level;


-- =========================================================================
-- Main Entity: 32-Bit Structural Barrel Shifter
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity barrel_shifter is
  port (
    data_in     : in  std_logic_vector(31 downto 0);
    shamt       : in  std_logic_vector(4 downto 0);
    shift_right : in  std_logic;
    arithmetic  : in  std_logic;
    data_out    : out std_logic_vector(31 downto 0)
  );
end entity barrel_shifter;

architecture structural of barrel_shifter is

  component bs_mux2t1 is
    port (
      i_d0  : in  std_logic;
      i_d1  : in  std_logic;
      i_sel : in  std_logic;
      o_y   : out std_logic
    );
  end component;

  -- Fill-bit signals for logical ('0') vs. arithmetic (data_in(31)) right shift
  signal s_arith_fill : std_logic;
  signal s_sign_fill  : std_logic;

  -- Intermediate 32-bit buses between MUX stages
  signal s_in_oriented : std_logic_vector(31 downto 0);
  signal s_stage0      : std_logic_vector(31 downto 0); -- Shift by 1  (shamt[0])
  signal s_stage1      : std_logic_vector(31 downto 0); -- Shift by 2  (shamt[1])
  signal s_stage2      : std_logic_vector(31 downto 0); -- Shift by 4  (shamt[2])
  signal s_stage3      : std_logic_vector(31 downto 0); -- Shift by 8  (shamt[3])
  signal s_stage4      : std_logic_vector(31 downto 0); -- Shift by 16 (shamt[4])

begin

  -- =======================================================================
  -- 1. Sign-Fill Selection via 2:1 MUXes
  --    s_sign_fill = data_in(31) when (arithmetic='1' and shift_right='1') else '0'
  -- =======================================================================
  U_ARITH_MUX: bs_mux2t1
    port map (
      i_d0  => '0',
      i_d1  => data_in(31),
      i_sel => arithmetic,
      o_y   => s_arith_fill
    );

  U_RIGHT_FILL_MUX: bs_mux2t1
    port map (
      i_d0  => '0',
      i_d1  => s_arith_fill,
      i_sel => shift_right,
      o_y   => s_sign_fill
    );

  -- =======================================================================
  -- 2. Input Bit-Reversal MUX Stage (Part 3.3.1.c Left-Shift Enhancement)
  --    When shift_right = '0' (SLL), reverses bit order: s_in_oriented(i) = data_in(31-i)
  --    When shift_right = '1' (SRL/SRA), keeps bit order: s_in_oriented(i) = data_in(i)
  -- =======================================================================
  G_IN_REVERSE: for i in 0 to 31 generate
    U_IN_REV_MUX: bs_mux2t1
      port map (
        i_d0  => data_in(31 - i),
        i_d1  => data_in(i),
        i_sel => shift_right,
        o_y   => s_in_oriented(i)
      );
  end generate G_IN_REVERSE;

  -- =======================================================================
  -- 3. Stage 0: Shift Right by 1 Bit (controlled by shamt(0))
  -- =======================================================================
  G_STAGE0_LOW: for i in 0 to 30 generate
    U_S0_MUX: bs_mux2t1
      port map (
        i_d0  => s_in_oriented(i),
        i_d1  => s_in_oriented(i + 1),
        i_sel => shamt(0),
        o_y   => s_stage0(i)
      );
  end generate G_STAGE0_LOW;

  U_S0_MSB: bs_mux2t1
    port map (
      i_d0  => s_in_oriented(31),
      i_d1  => s_sign_fill,
      i_sel => shamt(0),
      o_y   => s_stage0(31)
    );

  -- =======================================================================
  -- 4. Stage 1: Shift Right by 2 Bits (controlled by shamt(1))
  -- =======================================================================
  G_STAGE1_LOW: for i in 0 to 29 generate
    U_S1_MUX: bs_mux2t1
      port map (
        i_d0  => s_stage0(i),
        i_d1  => s_stage0(i + 2),
        i_sel => shamt(1),
        o_y   => s_stage1(i)
      );
  end generate G_STAGE1_LOW;

  G_STAGE1_HIGH: for i in 30 to 31 generate
    U_S1_FILL: bs_mux2t1
      port map (
        i_d0  => s_stage0(i),
        i_d1  => s_sign_fill,
        i_sel => shamt(1),
        o_y   => s_stage1(i)
      );
  end generate G_STAGE1_HIGH;

  -- =======================================================================
  -- 5. Stage 2: Shift Right by 4 Bits (controlled by shamt(2))
  -- =======================================================================
  G_STAGE2_LOW: for i in 0 to 27 generate
    U_S2_MUX: bs_mux2t1
      port map (
        i_d0  => s_stage1(i),
        i_d1  => s_stage1(i + 4),
        i_sel => shamt(2),
        o_y   => s_stage2(i)
      );
  end generate G_STAGE2_LOW;

  G_STAGE2_HIGH: for i in 28 to 31 generate
    U_S2_FILL: bs_mux2t1
      port map (
        i_d0  => s_stage1(i),
        i_d1  => s_sign_fill,
        i_sel => shamt(2),
        o_y   => s_stage2(i)
      );
  end generate G_STAGE2_HIGH;

  -- =======================================================================
  -- 6. Stage 3: Shift Right by 8 Bits (controlled by shamt(3))
  -- =======================================================================
  G_STAGE3_LOW: for i in 0 to 23 generate
    U_S3_MUX: bs_mux2t1
      port map (
        i_d0  => s_stage2(i),
        i_d1  => s_stage2(i + 8),
        i_sel => shamt(3),
        o_y   => s_stage3(i)
      );
  end generate G_STAGE3_LOW;

  G_STAGE3_HIGH: for i in 24 to 31 generate
    U_S3_FILL: bs_mux2t1
      port map (
        i_d0  => s_stage2(i),
        i_d1  => s_sign_fill,
        i_sel => shamt(3),
        o_y   => s_stage3(i)
      );
  end generate G_STAGE3_HIGH;

  -- =======================================================================
  -- 7. Stage 4: Shift Right by 16 Bits (controlled by shamt(4))
  -- =======================================================================
  G_STAGE4_LOW: for i in 0 to 15 generate
    U_S4_MUX: bs_mux2t1
      port map (
        i_d0  => s_stage3(i),
        i_d1  => s_stage3(i + 16),
        i_sel => shamt(4),
        o_y   => s_stage4(i)
      );
  end generate G_STAGE4_LOW;

  G_STAGE4_HIGH: for i in 16 to 31 generate
    U_S4_FILL: bs_mux2t1
      port map (
        i_d0  => s_stage3(i),
        i_d1  => s_sign_fill,
        i_sel => shamt(4),
        o_y   => s_stage4(i)
      );
  end generate G_STAGE4_HIGH;

  -- =======================================================================
  -- 8. Output Bit-Reversal MUX Stage
  --    When shift_right = '0' (SLL), reverses bits back to restore left-shifted order
  --    When shift_right = '1' (SRL/SRA), passes right-shifted result directly
  -- =======================================================================
  G_OUT_REVERSE: for i in 0 to 31 generate
    U_OUT_REV_MUX: bs_mux2t1
      port map (
        i_d0  => s_stage4(31 - i),
        i_d1  => s_stage4(i),
        i_sel => shift_right,
        o_y   => data_out(i)
      );
  end generate G_OUT_REVERSE;

end architecture structural;
