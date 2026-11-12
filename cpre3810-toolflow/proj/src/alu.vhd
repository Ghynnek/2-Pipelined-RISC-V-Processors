-------------------------------------------------------------------------
-- alu.vhd
-- Complete 32-Bit Structural RISC-V ALU
-- Instantiates structural submodules:
--   1. U_ADD_SUB        (alu_add_sub_32: 32-bit ripple-carry adder/subtractor)
--   2. U_SLT_UNIT       (alu_slt_unit: signed SLT & unsigned SLTU comparator)
--   3. U_BARREL_SHIFTER (barrel_shifter: 32-bit structural barrel shifter)
--   4. U_BITWISE        (alu_bitwise_32: 32-bit AND, OR, XOR gate arrays)
--   5. U_OUT_MUX        (alu_out_mux_32: structural output multiplexer)
--   6. U_ZERO_DETECT    (alu_zero_nor32: 32-input NOR zero flag detector)
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

-- =========================================================================
-- Submodule 1A: 1-Bit Full Adder
-- =========================================================================
entity alu_full_adder is
  port (
    i_a    : in  std_logic;
    i_b    : in  std_logic;
    i_cin  : in  std_logic;
    o_sum  : out std_logic;
    o_cout : out std_logic
  );
end entity alu_full_adder;

architecture gate_level of alu_full_adder is
  signal s_axorb : std_logic;
begin
  s_axorb <= i_a xor i_b;
  o_sum   <= s_axorb xor i_cin;
  o_cout  <= (i_a and i_b) or (s_axorb and i_cin);
end architecture gate_level;


-- =========================================================================
-- Submodule 1B: 32-Bit Structural Ripple-Carry Adder / Subtractor
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity alu_add_sub_32 is
  port (
    i_a    : in  std_logic_vector(31 downto 0);
    i_b    : in  std_logic_vector(31 downto 0);
    i_sub  : in  std_logic; -- '0' = ADD (a + b), '1' = SUB (a + ~b + 1)
    o_sum  : out std_logic_vector(31 downto 0);
    o_cout : out std_logic;
    o_ovfl : out std_logic
  );
end entity alu_add_sub_32;

architecture structural of alu_add_sub_32 is

  component bs_mux2t1 is
    port (
      i_d0  : in  std_logic;
      i_d1  : in  std_logic;
      i_sel : in  std_logic;
      o_y   : out std_logic
    );
  end component;

  component alu_full_adder is
    port (
      i_a    : in  std_logic;
      i_b    : in  std_logic;
      i_cin  : in  std_logic;
      o_sum  : out std_logic;
      o_cout : out std_logic
    );
  end component;

  signal s_b_inv : std_logic_vector(31 downto 0);
  signal s_b_mux : std_logic_vector(31 downto 0);
  signal s_carry : std_logic_vector(32 downto 0);

begin

  s_carry(0) <= i_sub;

  G_ADD_SUB_BITS: for i in 0 to 31 generate
    s_b_inv(i) <= not i_b(i);

    -- Select b(i) for ADD (i_sub='0') or ~b(i) for SUB/SLT/SLTU (i_sub='1')
    U_BINV_MUX: bs_mux2t1
      port map (
        i_d0  => i_b(i),
        i_d1  => s_b_inv(i),
        i_sel => i_sub,
        o_y   => s_b_mux(i)
      );

    -- 1-Bit Full Adder stage
    U_FA: alu_full_adder
      port map (
        i_a    => i_a(i),
        i_b    => s_b_mux(i),
        i_cin  => s_carry(i),
        o_sum  => o_sum(i),
        o_cout => s_carry(i + 1)
      );
  end generate G_ADD_SUB_BITS;

  o_cout <= s_carry(32);
  o_ovfl <= s_carry(31) xor s_carry(32);

end architecture structural;


-- =========================================================================
-- Submodule 2: Signed (SLT) & Unsigned (SLTU) Comparator Unit
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity alu_slt_unit is
  port (
    i_a_msb    : in  std_logic;
    i_b_msb    : in  std_logic;
    i_diff_msb : in  std_logic;
    i_cout     : in  std_logic;
    o_slt      : out std_logic_vector(31 downto 0);
    o_sltu     : out std_logic_vector(31 downto 0)
  );
end entity alu_slt_unit;

architecture structural of alu_slt_unit is

  component bs_mux2t1 is
    port (
      i_d0  : in  std_logic;
      i_d1  : in  std_logic;
      i_sel : in  std_logic;
      o_y   : out std_logic
    );
  end component;

  signal s_signs_diff : std_logic;
  signal s_slt_bit    : std_logic;
  signal s_sltu_bit   : std_logic;

begin

  -- When signs of a and b differ (a[31] xor b[31] = '1'), a <s b iff a[31] = '1'.
  -- When signs of a and b are equal, overflow cannot occur and a <s b iff diff[31] = '1'.
  s_signs_diff <= i_a_msb xor i_b_msb;

  U_SLT_MUX: bs_mux2t1
    port map (
      i_d0  => i_diff_msb,
      i_d1  => i_a_msb,
      i_sel => s_signs_diff,
      o_y   => s_slt_bit
    );

  -- For unsigned subtraction a + ~b + 1, a <u b iff carry-out is '0' (borrow occurred)
  s_sltu_bit <= not i_cout;

  o_slt(0)           <= s_slt_bit;
  o_slt(31 downto 1) <= (others => '0');

  o_sltu(0)           <= s_sltu_bit;
  o_sltu(31 downto 1) <= (others => '0');

end architecture structural;


-- =========================================================================
-- Submodule 4: 32-Bit Bitwise Logic Unit (AND / OR / XOR Gate Arrays)
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity alu_bitwise_32 is
  port (
    i_a   : in  std_logic_vector(31 downto 0);
    i_b   : in  std_logic_vector(31 downto 0);
    o_and : out std_logic_vector(31 downto 0);
    o_or  : out std_logic_vector(31 downto 0);
    o_xor : out std_logic_vector(31 downto 0)
  );
end entity alu_bitwise_32;

architecture structural of alu_bitwise_32 is
begin
  G_BITWISE: for i in 0 to 31 generate
    o_and(i) <= i_a(i) and i_b(i);
    o_or(i)  <= i_a(i) or  i_b(i);
    o_xor(i) <= i_a(i) xor i_b(i);
  end generate G_BITWISE;
end architecture structural;


-- =========================================================================
-- Submodule 5: 32-Bit Structural Output Multiplexer Tree
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity alu_out_mux_32 is
  port (
    i_add_sub : in  std_logic_vector(31 downto 0); -- 0000 (ADD), 0001 (SUB)
    i_and     : in  std_logic_vector(31 downto 0); -- 0010 (AND)
    i_or      : in  std_logic_vector(31 downto 0); -- 0011 (OR)
    i_xor     : in  std_logic_vector(31 downto 0); -- 0100 (XOR)
    i_shift   : in  std_logic_vector(31 downto 0); -- 0101 (SLL), 0110 (SRL), 0111 (SRA)
    i_slt     : in  std_logic_vector(31 downto 0); -- 1000 (SLT)
    i_sltu    : in  std_logic_vector(31 downto 0); -- 1001 (SLTU)
    i_sel     : in  std_logic_vector(3 downto 0);  -- ALUControl[3:0]
    o_result  : out std_logic_vector(31 downto 0)
  );
end entity alu_out_mux_32;

architecture structural of alu_out_mux_32 is

  component bs_mux2t1 is
    port (
      i_d0  : in  std_logic;
      i_d1  : in  std_logic;
      i_sel : in  std_logic;
      o_y   : out std_logic
    );
  end component;

  signal s_and_or    : std_logic_vector(31 downto 0);
  signal s_low_pair  : std_logic_vector(31 downto 0); -- 00xx: add_sub vs and/or
  signal s_mid_pair  : std_logic_vector(31 downto 0); -- 01xx: xor vs shift
  signal s_slt_pair  : std_logic_vector(31 downto 0); -- 10xx: slt vs sltu
  signal s_upper_0   : std_logic_vector(31 downto 0); -- 0xxx: low_pair vs mid_pair
  signal s_is_xor    : std_logic;

begin

  -- In 01xx group: 0100 is XOR, while 0101/0110/0111 are Shifts
  s_is_xor <= (not i_sel(1)) and (not i_sel(0));

  G_MUX_TREE: for i in 0 to 31 generate
    -- Select AND (0010) vs OR (0011) using i_sel(0)
    U_MUX_AND_OR: bs_mux2t1
      port map (
        i_d0  => i_and(i),
        i_d1  => i_or(i),
        i_sel => i_sel(0),
        o_y   => s_and_or(i)
      );

    -- Select ADD/SUB (000x) vs AND/OR (001x) using i_sel(1)
    U_MUX_00XX: bs_mux2t1
      port map (
        i_d0  => i_add_sub(i),
        i_d1  => s_and_or(i),
        i_sel => i_sel(1),
        o_y   => s_low_pair(i)
      );

    -- Select Shift (0101/0110/0111) vs XOR (0100)
    U_MUX_01XX: bs_mux2t1
      port map (
        i_d0  => i_shift(i),
        i_d1  => i_xor(i),
        i_sel => s_is_xor,
        o_y   => s_mid_pair(i)
      );

    -- Select 00xx vs 01xx using i_sel(2)
    U_MUX_0XXX: bs_mux2t1
      port map (
        i_d0  => s_low_pair(i),
        i_d1  => s_mid_pair(i),
        i_sel => i_sel(2),
        o_y   => s_upper_0(i)
      );

    -- Select SLT (1000) vs SLTU (1001) using i_sel(0)
    U_MUX_10XX: bs_mux2t1
      port map (
        i_d0  => i_slt(i),
        i_d1  => i_sltu(i),
        i_sel => i_sel(0),
        o_y   => s_slt_pair(i)
      );

    -- Final select: 0xxx vs 10xx using i_sel(3)
    U_MUX_FINAL: bs_mux2t1
      port map (
        i_d0  => s_upper_0(i),
        i_d1  => s_slt_pair(i),
        i_sel => i_sel(3),
        o_y   => o_result(i)
      );
  end generate G_MUX_TREE;

end architecture structural;


-- =========================================================================
-- Submodule 6: 32-Input NOR Zero Flag Detector
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity alu_zero_nor32 is
  port (
    i_data : in  std_logic_vector(31 downto 0);
    o_zero : out std_logic
  );
end entity alu_zero_nor32;

architecture gate_level of alu_zero_nor32 is
  signal s_or_l1 : std_logic_vector(15 downto 0);
  signal s_or_l2 : std_logic_vector(7 downto 0);
  signal s_or_l3 : std_logic_vector(3 downto 0);
  signal s_or_l4 : std_logic_vector(1 downto 0);
  signal s_any_1 : std_logic;
begin
  G_L1: for i in 0 to 15 generate
    s_or_l1(i) <= i_data(2*i) or i_data(2*i + 1);
  end generate G_L1;

  G_L2: for i in 0 to 7 generate
    s_or_l2(i) <= s_or_l1(2*i) or s_or_l1(2*i + 1);
  end generate G_L2;

  G_L3: for i in 0 to 3 generate
    s_or_l3(i) <= s_or_l2(2*i) or s_or_l2(2*i + 1);
  end generate G_L3;

  G_L4: for i in 0 to 1 generate
    s_or_l4(i) <= s_or_l3(2*i) or s_or_l3(2*i + 1);
  end generate G_L4;

  s_any_1 <= s_or_l4(0) or s_or_l4(1);
  o_zero  <= not s_any_1;
end architecture gate_level;


-- =========================================================================
-- Top-Level ALU Entity & Structural Architecture
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity alu is
  port (
    a          : in  std_logic_vector(31 downto 0);
    b          : in  std_logic_vector(31 downto 0);
    ALUControl : in  std_logic_vector(3 downto 0);
    result     : out std_logic_vector(31 downto 0);
    zero       : out std_logic
  );
end entity alu;

architecture structural of alu is

  component alu_add_sub_32 is
    port (
      i_a    : in  std_logic_vector(31 downto 0);
      i_b    : in  std_logic_vector(31 downto 0);
      i_sub  : in  std_logic;
      o_sum  : out std_logic_vector(31 downto 0);
      o_cout : out std_logic;
      o_ovfl : out std_logic
    );
  end component;

  component alu_slt_unit is
    port (
      i_a_msb    : in  std_logic;
      i_b_msb    : in  std_logic;
      i_diff_msb : in  std_logic;
      i_cout     : in  std_logic;
      o_slt      : out std_logic_vector(31 downto 0);
      o_sltu     : out std_logic_vector(31 downto 0)
    );
  end component;

  component barrel_shifter is
    port (
      data_in     : in  std_logic_vector(31 downto 0);
      shamt       : in  std_logic_vector(4 downto 0);
      shift_right : in  std_logic;
      arithmetic  : in  std_logic;
      data_out    : out std_logic_vector(31 downto 0)
    );
  end component;

  component alu_bitwise_32 is
    port (
      i_a   : in  std_logic_vector(31 downto 0);
      i_b   : in  std_logic_vector(31 downto 0);
      o_and : out std_logic_vector(31 downto 0);
      o_or  : out std_logic_vector(31 downto 0);
      o_xor : out std_logic_vector(31 downto 0)
    );
  end component;

  component alu_out_mux_32 is
    port (
      i_add_sub : in  std_logic_vector(31 downto 0);
      i_and     : in  std_logic_vector(31 downto 0);
      i_or      : in  std_logic_vector(31 downto 0);
      i_xor     : in  std_logic_vector(31 downto 0);
      i_shift   : in  std_logic_vector(31 downto 0);
      i_slt     : in  std_logic_vector(31 downto 0);
      i_sltu    : in  std_logic_vector(31 downto 0);
      i_sel     : in  std_logic_vector(3 downto 0);
      o_result  : out std_logic_vector(31 downto 0)
    );
  end component;

  component alu_zero_nor32 is
    port (
      i_data : in  std_logic_vector(31 downto 0);
      o_zero : out std_logic
    );
  end component;

  -- Internal control signals decoded from ALUControl[3:0]
  signal s_sub         : std_logic;
  signal s_shift_right : std_logic;
  signal s_arithmetic  : std_logic;

  -- Internal datapath buses between functional units
  signal s_add_sub     : std_logic_vector(31 downto 0);
  signal s_cout        : std_logic;
  signal s_ovfl        : std_logic;
  signal s_slt         : std_logic_vector(31 downto 0);
  signal s_sltu        : std_logic_vector(31 downto 0);
  signal s_shift_out   : std_logic_vector(31 downto 0);
  signal s_and         : std_logic_vector(31 downto 0);
  signal s_or          : std_logic_vector(31 downto 0);
  signal s_xor         : std_logic_vector(31 downto 0);
  signal s_result      : std_logic_vector(31 downto 0);

begin

  -- =======================================================================
  -- Control Signal Decoding for Subtractor & Barrel Shifter
  --   s_sub         = '1' for SUB (0001), SLT (1000), and SLTU (1001)
  --   s_shift_right = '0' for SLL (0101), '1' for SRL (0110) and SRA (0111)
  --   s_arithmetic  = '1' for SRA (0111), '0' otherwise
  -- =======================================================================
  s_sub         <= ALUControl(3) or ((not ALUControl(2)) and (not ALUControl(1)) and ALUControl(0));
  s_shift_right <= ALUControl(1);
  s_arithmetic  <= ALUControl(1) and ALUControl(0);

  -- 1. 32-Bit Structural Ripple-Carry Adder / Subtractor
  U_ADD_SUB: alu_add_sub_32
    port map (
      i_a    => a,
      i_b    => b,
      i_sub  => s_sub,
      o_sum  => s_add_sub,
      o_cout => s_cout,
      o_ovfl => s_ovfl
    );

  -- 2. Signed (SLT) & Unsigned (SLTU) Comparator Unit
  U_SLT_UNIT: alu_slt_unit
    port map (
      i_a_msb    => a(31),
      i_b_msb    => b(31),
      i_diff_msb => s_add_sub(31),
      i_cout     => s_cout,
      o_slt      => s_slt,
      o_sltu     => s_sltu
    );

  -- 3. 32-Bit Structural Barrel Shifter
  U_BARREL_SHIFTER: barrel_shifter
    port map (
      data_in     => a,
      shamt       => b(4 downto 0),
      shift_right => s_shift_right,
      arithmetic  => s_arithmetic,
      data_out    => s_shift_out
    );

  -- 4. 32-Bit Bitwise Logic Gates (AND / OR / XOR)
  U_BITWISE: alu_bitwise_32
    port map (
      i_a   => a,
      i_b   => b,
      o_and => s_and,
      o_or  => s_or,
      o_xor => s_xor
    );

  -- 5. 32-Bit Structural Output Multiplexer Tree
  U_OUT_MUX: alu_out_mux_32
    port map (
      i_add_sub => s_add_sub,
      i_and     => s_and,
      i_or      => s_or,
      i_xor     => s_xor,
      i_shift   => s_shift_out,
      i_slt     => s_slt,
      i_sltu    => s_sltu,
      i_sel     => ALUControl,
      o_result  => s_result
    );

  -- 6. 32-Input NOR Zero Flag Detector
  U_ZERO_DETECT: alu_zero_nor32
    port map (
      i_data => s_result,
      o_zero => zero
    );

  result <= s_result;

end architecture structural;
