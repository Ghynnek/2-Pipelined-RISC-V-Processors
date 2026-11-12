-------------------------------------------------------------------------
-- pipeline_regs.vhd
-- Individual IF/ID, ID/EX, EX/MEM, and MEM/WB Pipeline Registers
-- Supports asynchronous reset (i_rst), synchronous flush, and stall.
-- Software-scheduled integration ties i_stall and i_flush low.
-- When i_flush = '1' or iRST = '1', control signals clear to '0' (NOP).
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

-- =========================================================================
-- 1. IF/ID Pipeline Register
-- =========================================================================
entity reg_IF_ID is
  port (
    i_clk      : in  std_logic;
    i_rst      : in  std_logic;
    i_stall    : in  std_logic;
    i_flush    : in  std_logic;
    i_pc       : in  std_logic_vector(31 downto 0);
    i_pc_plus4 : in  std_logic_vector(31 downto 0);
    i_inst     : in  std_logic_vector(31 downto 0);
    o_pc       : out std_logic_vector(31 downto 0);
    o_pc_plus4 : out std_logic_vector(31 downto 0);
    o_inst     : out std_logic_vector(31 downto 0)
  );
end entity reg_IF_ID;

architecture behavioral of reg_IF_ID is
  signal r_pc       : std_logic_vector(31 downto 0) := (others => '0');
  signal r_pc_plus4 : std_logic_vector(31 downto 0) := (others => '0');
  signal r_inst     : std_logic_vector(31 downto 0) := x"00000013"; -- NOP (addi x0, x0, 0)
begin
  process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_pc       <= (others => '0');
      r_pc_plus4 <= (others => '0');
      r_inst     <= x"00000013";
    elsif rising_edge(i_clk) then
      if i_flush = '1' then
        r_pc       <= (others => '0');
        r_pc_plus4 <= (others => '0');
        r_inst     <= x"00000013";
      elsif i_stall = '0' then
        r_pc       <= i_pc;
        r_pc_plus4 <= i_pc_plus4;
        r_inst     <= i_inst;
      end if;
    end if;
  end process;

  o_pc       <= r_pc;
  o_pc_plus4 <= r_pc_plus4;
  o_inst     <= r_inst;
end architecture behavioral;


-- =========================================================================
-- 2. ID/EX Pipeline Register
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity reg_ID_EX is
  port (
    i_clk        : in  std_logic;
    i_rst        : in  std_logic;
    i_stall      : in  std_logic;
    i_flush      : in  std_logic;
    -- Control inputs
    i_reg_write  : in  std_logic;
    i_alu_src    : in  std_logic;
    i_auipc      : in  std_logic;
    i_mem_write  : in  std_logic;
    i_mem_to_reg : in  std_logic;
    i_branch     : in  std_logic;
    i_jump       : in  std_logic;
    i_jump_reg   : in  std_logic;
    i_lui        : in  std_logic;
    i_halt       : in  std_logic;
    i_alu_ctrl   : in  std_logic_vector(3 downto 0);
    -- Datapath inputs
    i_pc         : in  std_logic_vector(31 downto 0);
    i_pc_plus4   : in  std_logic_vector(31 downto 0);
    i_reg_read1  : in  std_logic_vector(31 downto 0);
    i_reg_read2  : in  std_logic_vector(31 downto 0);
    i_imm        : in  std_logic_vector(31 downto 0);
    i_funct3     : in  std_logic_vector(2 downto 0);
    i_rs1        : in  std_logic_vector(4 downto 0);
    i_rs2        : in  std_logic_vector(4 downto 0);
    i_rd         : in  std_logic_vector(4 downto 0);
    -- Control outputs
    o_reg_write  : out std_logic;
    o_alu_src    : out std_logic;
    o_auipc      : out std_logic;
    o_mem_write  : out std_logic;
    o_mem_to_reg : out std_logic;
    o_branch     : out std_logic;
    o_jump       : out std_logic;
    o_jump_reg   : out std_logic;
    o_lui        : out std_logic;
    o_halt       : out std_logic;
    o_alu_ctrl   : out std_logic_vector(3 downto 0);
    -- Datapath outputs
    o_pc         : out std_logic_vector(31 downto 0);
    o_pc_plus4   : out std_logic_vector(31 downto 0);
    o_reg_read1  : out std_logic_vector(31 downto 0);
    o_reg_read2  : out std_logic_vector(31 downto 0);
    o_imm        : out std_logic_vector(31 downto 0);
    o_funct3     : out std_logic_vector(2 downto 0);
    o_rs1        : out std_logic_vector(4 downto 0);
    o_rs2        : out std_logic_vector(4 downto 0);
    o_rd         : out std_logic_vector(4 downto 0)
  );
end entity reg_ID_EX;

architecture behavioral of reg_ID_EX is
  signal r_reg_write  : std_logic := '0';
  signal r_alu_src    : std_logic := '0';
  signal r_auipc      : std_logic := '0';
  signal r_mem_write  : std_logic := '0';
  signal r_mem_to_reg : std_logic := '0';
  signal r_branch     : std_logic := '0';
  signal r_jump       : std_logic := '0';
  signal r_jump_reg   : std_logic := '0';
  signal r_lui        : std_logic := '0';
  signal r_halt       : std_logic := '0';
  signal r_alu_ctrl   : std_logic_vector(3 downto 0) := (others => '0');
  signal r_pc         : std_logic_vector(31 downto 0) := (others => '0');
  signal r_pc_plus4   : std_logic_vector(31 downto 0) := (others => '0');
  signal r_reg_read1  : std_logic_vector(31 downto 0) := (others => '0');
  signal r_reg_read2  : std_logic_vector(31 downto 0) := (others => '0');
  signal r_imm        : std_logic_vector(31 downto 0) := (others => '0');
  signal r_funct3     : std_logic_vector(2 downto 0) := (others => '0');
  signal r_rs1        : std_logic_vector(4 downto 0) := (others => '0');
  signal r_rs2        : std_logic_vector(4 downto 0) := (others => '0');
  signal r_rd         : std_logic_vector(4 downto 0) := (others => '0');
begin
  process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_reg_write  <= '0';
      r_alu_src    <= '0';
      r_auipc      <= '0';
      r_mem_write  <= '0';
      r_mem_to_reg <= '0';
      r_branch     <= '0';
      r_jump       <= '0';
      r_jump_reg   <= '0';
      r_lui        <= '0';
      r_halt       <= '0';
      r_alu_ctrl   <= (others => '0');
      r_pc         <= (others => '0');
      r_pc_plus4   <= (others => '0');
      r_reg_read1  <= (others => '0');
      r_reg_read2  <= (others => '0');
      r_imm        <= (others => '0');
      r_funct3     <= (others => '0');
      r_rs1        <= (others => '0');
      r_rs2        <= (others => '0');
      r_rd         <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_flush = '1' then
        r_reg_write  <= '0';
        r_alu_src    <= '0';
        r_auipc      <= '0';
        r_mem_write  <= '0';
        r_mem_to_reg <= '0';
        r_branch     <= '0';
        r_jump       <= '0';
        r_jump_reg   <= '0';
        r_lui        <= '0';
        r_halt       <= '0';
        r_alu_ctrl   <= (others => '0');
        r_pc         <= (others => '0');
        r_pc_plus4   <= (others => '0');
        r_reg_read1  <= (others => '0');
        r_reg_read2  <= (others => '0');
        r_imm        <= (others => '0');
        r_funct3     <= (others => '0');
        r_rs1        <= (others => '0');
        r_rs2        <= (others => '0');
        r_rd         <= (others => '0');
      elsif i_stall = '0' then
        r_reg_write  <= i_reg_write;
        r_alu_src    <= i_alu_src;
        r_auipc      <= i_auipc;
        r_mem_write  <= i_mem_write;
        r_mem_to_reg <= i_mem_to_reg;
        r_branch     <= i_branch;
        r_jump       <= i_jump;
        r_jump_reg   <= i_jump_reg;
        r_lui        <= i_lui;
        r_halt       <= i_halt;
        r_alu_ctrl   <= i_alu_ctrl;
        r_pc         <= i_pc;
        r_pc_plus4   <= i_pc_plus4;
        r_reg_read1  <= i_reg_read1;
        r_reg_read2  <= i_reg_read2;
        r_imm        <= i_imm;
        r_funct3     <= i_funct3;
        r_rs1        <= i_rs1;
        r_rs2        <= i_rs2;
        r_rd         <= i_rd;
      end if;
    end if;
  end process;

  o_reg_write  <= r_reg_write;
  o_alu_src    <= r_alu_src;
  o_auipc      <= r_auipc;
  o_mem_write  <= r_mem_write;
  o_mem_to_reg <= r_mem_to_reg;
  o_branch     <= r_branch;
  o_jump       <= r_jump;
  o_jump_reg   <= r_jump_reg;
  o_lui        <= r_lui;
  o_halt       <= r_halt;
  o_alu_ctrl   <= r_alu_ctrl;
  o_pc         <= r_pc;
  o_pc_plus4   <= r_pc_plus4;
  o_reg_read1  <= r_reg_read1;
  o_reg_read2  <= r_reg_read2;
  o_imm        <= r_imm;
  o_funct3     <= r_funct3;
  o_rs1        <= r_rs1;
  o_rs2        <= r_rs2;
  o_rd         <= r_rd;
end architecture behavioral;


-- =========================================================================
-- 3. EX/MEM Pipeline Register
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity reg_EX_MEM is
  port (
    i_clk        : in  std_logic;
    i_rst        : in  std_logic;
    i_stall      : in  std_logic;
    i_flush      : in  std_logic;
    -- Control inputs
    i_reg_write  : in  std_logic;
    i_mem_write  : in  std_logic;
    i_mem_to_reg : in  std_logic;
    i_jump       : in  std_logic;
    i_jump_reg   : in  std_logic;
    i_lui        : in  std_logic;
    i_halt       : in  std_logic;
    -- Datapath inputs
    i_pc_plus4   : in  std_logic_vector(31 downto 0);
    i_alu_result : in  std_logic_vector(31 downto 0);
    i_reg_read2  : in  std_logic_vector(31 downto 0);
    i_imm        : in  std_logic_vector(31 downto 0);
    i_funct3     : in  std_logic_vector(2 downto 0);
    i_rd         : in  std_logic_vector(4 downto 0);
    -- Control outputs
    o_reg_write  : out std_logic;
    o_mem_write  : out std_logic;
    o_mem_to_reg : out std_logic;
    o_jump       : out std_logic;
    o_jump_reg   : out std_logic;
    o_lui        : out std_logic;
    o_halt       : out std_logic;
    -- Datapath outputs
    o_pc_plus4   : out std_logic_vector(31 downto 0);
    o_alu_result : out std_logic_vector(31 downto 0);
    o_reg_read2  : out std_logic_vector(31 downto 0);
    o_imm        : out std_logic_vector(31 downto 0);
    o_funct3     : out std_logic_vector(2 downto 0);
    o_rd         : out std_logic_vector(4 downto 0)
  );
end entity reg_EX_MEM;

architecture behavioral of reg_EX_MEM is
  signal r_reg_write  : std_logic := '0';
  signal r_mem_write  : std_logic := '0';
  signal r_mem_to_reg : std_logic := '0';
  signal r_jump       : std_logic := '0';
  signal r_jump_reg   : std_logic := '0';
  signal r_lui        : std_logic := '0';
  signal r_halt       : std_logic := '0';
  signal r_pc_plus4   : std_logic_vector(31 downto 0) := (others => '0');
  signal r_alu_result : std_logic_vector(31 downto 0) := (others => '0');
  signal r_reg_read2  : std_logic_vector(31 downto 0) := (others => '0');
  signal r_imm        : std_logic_vector(31 downto 0) := (others => '0');
  signal r_funct3     : std_logic_vector(2 downto 0) := (others => '0');
  signal r_rd         : std_logic_vector(4 downto 0) := (others => '0');
begin
  process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_reg_write  <= '0';
      r_mem_write  <= '0';
      r_mem_to_reg <= '0';
      r_jump       <= '0';
      r_jump_reg   <= '0';
      r_lui        <= '0';
      r_halt       <= '0';
      r_pc_plus4   <= (others => '0');
      r_alu_result <= (others => '0');
      r_reg_read2  <= (others => '0');
      r_imm        <= (others => '0');
      r_funct3     <= (others => '0');
      r_rd         <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_flush = '1' then
        r_reg_write  <= '0';
        r_mem_write  <= '0';
        r_mem_to_reg <= '0';
        r_jump       <= '0';
        r_jump_reg   <= '0';
        r_lui        <= '0';
        r_halt       <= '0';
        r_pc_plus4   <= (others => '0');
        r_alu_result <= (others => '0');
        r_reg_read2  <= (others => '0');
        r_imm        <= (others => '0');
        r_funct3     <= (others => '0');
        r_rd         <= (others => '0');
      elsif i_stall = '0' then
        r_reg_write  <= i_reg_write;
        r_mem_write  <= i_mem_write;
        r_mem_to_reg <= i_mem_to_reg;
        r_jump       <= i_jump;
        r_jump_reg   <= i_jump_reg;
        r_lui        <= i_lui;
        r_halt       <= i_halt;
        r_pc_plus4   <= i_pc_plus4;
        r_alu_result <= i_alu_result;
        r_reg_read2  <= i_reg_read2;
        r_imm        <= i_imm;
        r_funct3     <= i_funct3;
        r_rd         <= i_rd;
      end if;
    end if;
  end process;

  o_reg_write  <= r_reg_write;
  o_mem_write  <= r_mem_write;
  o_mem_to_reg <= r_mem_to_reg;
  o_jump       <= r_jump;
  o_jump_reg   <= r_jump_reg;
  o_lui        <= r_lui;
  o_halt       <= r_halt;
  o_pc_plus4   <= r_pc_plus4;
  o_alu_result <= r_alu_result;
  o_reg_read2  <= r_reg_read2;
  o_imm        <= r_imm;
  o_funct3     <= r_funct3;
  o_rd         <= r_rd;
end architecture behavioral;


-- =========================================================================
-- 4. MEM/WB Pipeline Register
-- =========================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity reg_MEM_WB is
  port (
    i_clk        : in  std_logic;
    i_rst        : in  std_logic;
    i_stall      : in  std_logic;
    i_flush      : in  std_logic;
    -- Control inputs
    i_reg_write  : in  std_logic;
    i_mem_to_reg : in  std_logic;
    i_jump       : in  std_logic;
    i_jump_reg   : in  std_logic;
    i_lui        : in  std_logic;
    i_halt       : in  std_logic;
    -- Datapath inputs
    i_pc_plus4   : in  std_logic_vector(31 downto 0);
    i_alu_result : in  std_logic_vector(31 downto 0);
    i_dmem_out   : in  std_logic_vector(31 downto 0);
    i_imm        : in  std_logic_vector(31 downto 0);
    i_funct3     : in  std_logic_vector(2 downto 0);
    i_rd         : in  std_logic_vector(4 downto 0);
    -- Control outputs
    o_reg_write  : out std_logic;
    o_mem_to_reg : out std_logic;
    o_jump       : out std_logic;
    o_jump_reg   : out std_logic;
    o_lui        : out std_logic;
    o_halt       : out std_logic;
    -- Datapath outputs
    o_pc_plus4   : out std_logic_vector(31 downto 0);
    o_alu_result : out std_logic_vector(31 downto 0);
    o_dmem_out   : out std_logic_vector(31 downto 0);
    o_imm        : out std_logic_vector(31 downto 0);
    o_funct3     : out std_logic_vector(2 downto 0);
    o_rd         : out std_logic_vector(4 downto 0)
  );
end entity reg_MEM_WB;

architecture behavioral of reg_MEM_WB is
  signal r_reg_write  : std_logic := '0';
  signal r_mem_to_reg : std_logic := '0';
  signal r_jump       : std_logic := '0';
  signal r_jump_reg   : std_logic := '0';
  signal r_lui        : std_logic := '0';
  signal r_halt       : std_logic := '0';
  signal r_pc_plus4   : std_logic_vector(31 downto 0) := (others => '0');
  signal r_alu_result : std_logic_vector(31 downto 0) := (others => '0');
  signal r_dmem_out   : std_logic_vector(31 downto 0) := (others => '0');
  signal r_imm        : std_logic_vector(31 downto 0) := (others => '0');
  signal r_funct3     : std_logic_vector(2 downto 0) := (others => '0');
  signal r_rd         : std_logic_vector(4 downto 0) := (others => '0');
begin
  process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_reg_write  <= '0';
      r_mem_to_reg <= '0';
      r_jump       <= '0';
      r_jump_reg   <= '0';
      r_lui        <= '0';
      r_halt       <= '0';
      r_pc_plus4   <= (others => '0');
      r_alu_result <= (others => '0');
      r_dmem_out   <= (others => '0');
      r_imm        <= (others => '0');
      r_funct3     <= (others => '0');
      r_rd         <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_flush = '1' then
        r_reg_write  <= '0';
        r_mem_to_reg <= '0';
        r_jump       <= '0';
        r_jump_reg   <= '0';
        r_lui        <= '0';
        r_halt       <= '0';
        r_pc_plus4   <= (others => '0');
        r_alu_result <= (others => '0');
        r_dmem_out   <= (others => '0');
        r_imm        <= (others => '0');
        r_funct3     <= (others => '0');
        r_rd         <= (others => '0');
      elsif i_stall = '0' then
        r_reg_write  <= i_reg_write;
        r_mem_to_reg <= i_mem_to_reg;
        r_jump       <= i_jump;
        r_jump_reg   <= i_jump_reg;
        r_lui        <= i_lui;
        r_halt       <= i_halt;
        r_pc_plus4   <= i_pc_plus4;
        r_alu_result <= i_alu_result;
        r_dmem_out   <= i_dmem_out;
        r_imm        <= i_imm;
        r_funct3     <= i_funct3;
        r_rd         <= i_rd;
      end if;
    end if;
  end process;

  o_reg_write  <= r_reg_write;
  o_mem_to_reg <= r_mem_to_reg;
  o_jump       <= r_jump;
  o_jump_reg   <= r_jump_reg;
  o_lui        <= r_lui;
  o_halt       <= r_halt;
  o_pc_plus4   <= r_pc_plus4;
  o_alu_result <= r_alu_result;
  o_dmem_out   <= r_dmem_out;
  o_imm        <= r_imm;
  o_funct3     <= r_funct3;
  o_rd         <= r_rd;
end architecture behavioral;