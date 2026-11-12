-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- RISCV_Processor.vhd
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0));
end RISCV_Processor;


architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic;
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0);
  signal s_DMemData     : std_logic_vector(N-1 downto 0);
  signal s_DMemBE       : std_logic_vector(3 downto 0);
  signal s_DMemOut      : std_logic_vector(N-1 downto 0);
 
  -- Required register file signals 
  signal s_RegWr        : std_logic;
  signal s_RegWrAddr    : std_logic_vector(4 downto 0);
  signal s_RegWrData    : std_logic_vector(N-1 downto 0);

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_PC instead
  signal s_PC           : std_logic_vector(N-1 downto 0);
  signal s_Inst         : std_logic_vector(N-1 downto 0);

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;

  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
          data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
          be           : in std_logic_vector(3 downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
  end component;

  -- =========================================================================
  -- Submodule Component Declarations
  -- =========================================================================
  component fetch_logic_sw is
    port (
      clk, reset            : in  std_logic;
      branch_pc             : in std_logic_vector(31 downto 0);
      imm                   : in  std_logic_vector(31 downto 0);
      alu_result            : in  std_logic_vector(31 downto 0);
      zero                  : in  std_logic;
      funct3                : in  std_logic_vector(2 downto 0);
      Branch, Jump, JumpReg : in  std_logic;
      pc                    : out std_logic_vector(31 downto 0);
      pc_plus4              : out std_logic_vector(31 downto 0)
    );
  end component;

  component control_unit is
    port (
      instruction : in  std_logic_vector(31 downto 0);
      RegWrite    : out std_logic;
      MemWrite    : out std_logic;
      MemRead     : out std_logic;
      ALUSrc      : out std_logic;
      MemToReg    : out std_logic;
      Branch      : out std_logic;
      Jump        : out std_logic;
      JumpReg     : out std_logic;
      LUI         : out std_logic;
      AUIPC       : out std_logic;
      ImmSrc      : out std_logic_vector(2 downto 0);
      ALUControl  : out std_logic_vector(3 downto 0)
    );
  end component;

  component reg_file is
    port (
      i_clk    : in  std_logic;
      i_rst    : in  std_logic;
      i_we     : in  std_logic;
      i_rd     : in  std_logic_vector(4 downto 0);
      i_wdata  : in  std_logic_vector(31 downto 0);
      i_rs1    : in  std_logic_vector(4 downto 0);
      i_rs2    : in  std_logic_vector(4 downto 0);
      o_rdata1 : out std_logic_vector(31 downto 0);
      o_rdata2 : out std_logic_vector(31 downto 0)
    );
  end component;

  component imm_gen is
    port (
      instruction : in  std_logic_vector(31 downto 0);
      ImmSrc      : in  std_logic_vector(2 downto 0);
      imm         : out std_logic_vector(31 downto 0)
    );
  end component;

  component mux2_32 is
    port (
      d0 : in  std_logic_vector(31 downto 0);
      d1 : in  std_logic_vector(31 downto 0);
      s  : in  std_logic;
      y  : out std_logic_vector(31 downto 0)
    );
  end component;

  component alu is
    port (
      a          : in  std_logic_vector(31 downto 0);
      b          : in  std_logic_vector(31 downto 0);
      ALUControl : in  std_logic_vector(3 downto 0);
      result     : out std_logic_vector(31 downto 0);
      zero       : out std_logic
    );
  end component;

  component writeback_select is
    port (
      alu_result : in  std_logic_vector(31 downto 0);
      mem_data   : in  std_logic_vector(31 downto 0);
      imm        : in  std_logic_vector(31 downto 0);
      funct3     : in  std_logic_vector(2 downto 0);
      MemToReg   : in  std_logic;
      LUI        : in  std_logic;
      pc_plus4   : in  std_logic_vector(31 downto 0);
      Jump       : in  std_logic;
      JumpReg    : in  std_logic;
      wb_data    : out std_logic_vector(31 downto 0)
    );
  end component;


 component reg_IF_ID is
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
end component;

 component reg_ID_EX is
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
end component;

 component reg_EX_MEM is
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
end component;

 component reg_MEM_WB is
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
end component;

signal s_reset : std_logic;
signal d_pc : std_logic_vector(31 downto 0);
signal d_pc_plus4 : std_logic_vector(31 downto 0);
signal d_inst : std_logic_vector(31 downto 0);
signal d_reg_write : std_logic;
signal d_mem_write : std_logic;
signal d_mem_read : std_logic;
signal d_alu_src : std_logic;
signal d_mem_to_reg : std_logic;
signal d_branch : std_logic;
signal d_jump : std_logic;
signal d_jump_reg : std_logic;
signal d_lui : std_logic;
signal d_auipc : std_logic;
signal d_imm_src : std_logic_vector(2 downto 0);
signal d_alu_ctrl : std_logic_vector(3 downto 0);
signal d_reg_read1 : std_logic_vector(31 downto 0);
signal d_reg_read2 : std_logic_vector(31 downto 0);
signal d_imm : std_logic_vector(31 downto 0);
signal d_halt : std_logic;
signal e_reg_write : std_logic;
signal e_alu_src : std_logic;
signal e_auipc : std_logic;
signal e_mem_write : std_logic;
signal e_mem_to_reg : std_logic;
signal e_branch : std_logic;
signal e_jump : std_logic;
signal e_jump_reg : std_logic;
signal e_lui : std_logic;
signal e_halt : std_logic;
signal e_alu_ctrl : std_logic_vector(3 downto 0);
signal e_pc : std_logic_vector(31 downto 0);
signal e_pc_plus4 : std_logic_vector(31 downto 0);
signal e_reg_read1 : std_logic_vector(31 downto 0);
signal e_reg_read2 : std_logic_vector(31 downto 0);
signal e_imm : std_logic_vector(31 downto 0);
signal e_funct3 : std_logic_vector(2 downto 0);
signal e_rs1 : std_logic_vector(4 downto 0);
signal e_rs2 : std_logic_vector(4 downto 0);
signal e_rd : std_logic_vector(4 downto 0);
signal m_reg_write : std_logic;
signal m_mem_write : std_logic;
signal m_mem_to_reg : std_logic;
signal m_jump : std_logic;
signal m_jump_reg : std_logic;
signal m_lui : std_logic;
signal m_halt : std_logic;
signal m_pc_plus4 : std_logic_vector(31 downto 0);
signal m_alu_result : std_logic_vector(31 downto 0);
signal m_reg_read2 : std_logic_vector(31 downto 0);
signal m_imm : std_logic_vector(31 downto 0);
signal m_funct3 : std_logic_vector(2 downto 0);
signal m_rd : std_logic_vector(4 downto 0);
signal w_reg_write : std_logic;
signal w_mem_to_reg : std_logic;
signal w_jump : std_logic;
signal w_jump_reg : std_logic;
signal w_lui : std_logic;
signal w_halt : std_logic;
signal w_pc_plus4 : std_logic_vector(31 downto 0);
signal w_alu_result : std_logic_vector(31 downto 0);
signal w_dmem_out : std_logic_vector(31 downto 0);
signal w_imm : std_logic_vector(31 downto 0);
signal w_funct3 : std_logic_vector(2 downto 0);
signal w_rd : std_logic_vector(4 downto 0);
signal f_pc_plus4 : std_logic_vector(31 downto 0);
signal x_alu_a : std_logic_vector(31 downto 0);
signal x_alu_b : std_logic_vector(31 downto 0);
signal x_alu_result : std_logic_vector(31 downto 0);
signal x_zero : std_logic;
signal sb_be : std_logic_vector(3 downto 0);
signal sh_be : std_logic_vector(3 downto 0);
signal sb_data : std_logic_vector(31 downto 0);
signal sh_data : std_logic_vector(31 downto 0);
begin

  -- Five stages, rising-edge register file, NO forwarding/interlocks/flushes.
  -- EX resolves control flow: software must place TWO nops after every transfer.
  -- RAW dependencies require THREE intervening instructions (or nops).
  s_reset <= iRST or iInstLd;
  s_Ovfl <= '0';
  s_IMemAddr <= iInstAddr when iInstLd = '1' else s_PC;
  IMem: mem generic map(ADDR_WIDTH => ADDR_WIDTH, DATA_WIDTH => N)
    port map(iCLK, s_IMemAddr(11 downto 2), iInstExt, "1111", iInstLd, s_Inst);
  DMem: mem generic map(ADDR_WIDTH => ADDR_WIDTH, DATA_WIDTH => N)
    port map(iCLK, s_DMemAddr(11 downto 2), s_DMemData, s_DMemBE, s_DMemWr, s_DMemOut);
  U_FETCH: fetch_logic_sw port map(
    clk => iCLK, reset => s_reset, branch_pc => e_pc, imm => e_imm,
    alu_result => x_alu_result, zero => x_zero, funct3 => e_funct3,
    Branch => e_branch, Jump => e_jump, JumpReg => e_jump_reg,
    pc => s_PC, pc_plus4 => f_pc_plus4);
  U_IF_ID: reg_IF_ID port map(i_clk => iCLK, i_rst => s_reset,
    i_stall => '0', i_flush => '0', i_pc => s_PC, i_pc_plus4 => f_pc_plus4,
    i_inst => s_Inst, o_pc => d_pc, o_pc_plus4 => d_pc_plus4, o_inst => d_inst);
  U_CONTROL: control_unit port map(
    instruction => d_inst, RegWrite => d_reg_write, MemWrite => d_mem_write,
    MemRead => d_mem_read, ALUSrc => d_alu_src, MemToReg => d_mem_to_reg,
    Branch => d_branch, Jump => d_jump, JumpReg => d_jump_reg, LUI => d_lui,
    AUIPC => d_auipc, ImmSrc => d_imm_src, ALUControl => d_alu_ctrl);
  U_REGFILE: reg_file port map(iCLK, s_reset, s_RegWr, s_RegWrAddr,
    s_RegWrData, d_inst(19 downto 15), d_inst(24 downto 20), d_reg_read1, d_reg_read2);
  U_IMMGEN: imm_gen port map(d_inst, d_imm_src, d_imm);
  d_halt <= '1' when d_inst = x"10500073" else '0';
  U_ID_EX: reg_ID_EX port map(
    i_clk => iCLK,
    i_rst => s_reset,
    i_stall => '0',
    i_flush => '0',
    i_reg_write => d_reg_write,
    i_alu_src => d_alu_src,
    i_auipc => d_auipc,
    i_mem_write => d_mem_write,
    i_mem_to_reg => d_mem_to_reg,
    i_branch => d_branch,
    i_jump => d_jump,
    i_jump_reg => d_jump_reg,
    i_lui => d_lui,
    i_halt => d_halt,
    i_alu_ctrl => d_alu_ctrl,
    i_pc => d_pc,
    i_pc_plus4 => d_pc_plus4,
    i_reg_read1 => d_reg_read1,
    i_reg_read2 => d_reg_read2,
    i_imm => d_imm,
    i_funct3 => d_inst(14 downto 12),
    i_rs1 => d_inst(19 downto 15),
    i_rs2 => d_inst(24 downto 20),
    i_rd => d_inst(11 downto 7),
    o_reg_write => e_reg_write,
    o_alu_src => e_alu_src,
    o_auipc => e_auipc,
    o_mem_write => e_mem_write,
    o_mem_to_reg => e_mem_to_reg,
    o_branch => e_branch,
    o_jump => e_jump,
    o_jump_reg => e_jump_reg,
    o_lui => e_lui,
    o_halt => e_halt,
    o_alu_ctrl => e_alu_ctrl,
    o_pc => e_pc,
    o_pc_plus4 => e_pc_plus4,
    o_reg_read1 => e_reg_read1,
    o_reg_read2 => e_reg_read2,
    o_imm => e_imm,
    o_funct3 => e_funct3,
    o_rs1 => e_rs1,
    o_rs2 => e_rs2,
    o_rd => e_rd);
  U_EX_MEM: reg_EX_MEM port map(
    i_clk => iCLK,
    i_rst => s_reset,
    i_stall => '0',
    i_flush => '0',
    i_reg_write => e_reg_write,
    i_mem_write => e_mem_write,
    i_mem_to_reg => e_mem_to_reg,
    i_jump => e_jump,
    i_jump_reg => e_jump_reg,
    i_lui => e_lui,
    i_halt => e_halt,
    i_pc_plus4 => e_pc_plus4,
    i_alu_result => x_alu_result,
    i_reg_read2 => e_reg_read2,
    i_imm => e_imm,
    i_funct3 => e_funct3,
    i_rd => e_rd,
    o_reg_write => m_reg_write,
    o_mem_write => m_mem_write,
    o_mem_to_reg => m_mem_to_reg,
    o_jump => m_jump,
    o_jump_reg => m_jump_reg,
    o_lui => m_lui,
    o_halt => m_halt,
    o_pc_plus4 => m_pc_plus4,
    o_alu_result => m_alu_result,
    o_reg_read2 => m_reg_read2,
    o_imm => m_imm,
    o_funct3 => m_funct3,
    o_rd => m_rd);
  U_MEM_WB: reg_MEM_WB port map(
    i_clk => iCLK,
    i_rst => s_reset,
    i_stall => '0',
    i_flush => '0',
    i_reg_write => m_reg_write,
    i_mem_to_reg => m_mem_to_reg,
    i_jump => m_jump,
    i_jump_reg => m_jump_reg,
    i_lui => m_lui,
    i_halt => m_halt,
    i_pc_plus4 => m_pc_plus4,
    i_alu_result => m_alu_result,
    i_dmem_out => s_DMemOut,
    i_imm => m_imm,
    i_funct3 => m_funct3,
    i_rd => m_rd,
    o_reg_write => w_reg_write,
    o_mem_to_reg => w_mem_to_reg,
    o_jump => w_jump,
    o_jump_reg => w_jump_reg,
    o_lui => w_lui,
    o_halt => w_halt,
    o_pc_plus4 => w_pc_plus4,
    o_alu_result => w_alu_result,
    o_dmem_out => w_dmem_out,
    o_imm => w_imm,
    o_funct3 => w_funct3,
    o_rd => w_rd);

  U_ALUA: mux2_32 port map(e_reg_read1, e_pc, e_auipc, x_alu_a);
  U_ALUB: mux2_32 port map(e_reg_read2, e_imm, e_alu_src, x_alu_b);
  U_ALU: alu port map(x_alu_a, x_alu_b, e_alu_ctrl, x_alu_result, x_zero);
  oALUOut <= x_alu_result;
  -- Store address, width and data must all come from MEM, not current decode.
  s_DMemAddr <= m_alu_result;
  s_DMemWr <= m_mem_write and not s_reset;
  with m_alu_result(1 downto 0) select
    sb_be <= "0001" when "00", "0010" when "01", "0100" when "10", "1000" when others;
  sh_be <= "0011" when m_alu_result(1) = '0' else "1100";
  with m_funct3 select
    s_DMemBE <= sb_be when "000", sh_be when "001", "1111" when others;
  with m_alu_result(1 downto 0) select
    sb_data <= x"000000" & m_reg_read2(7 downto 0) when "00",
               x"0000" & m_reg_read2(7 downto 0) & x"00" when "01",
               x"00" & m_reg_read2(7 downto 0) & x"0000" when "10",
               m_reg_read2(7 downto 0) & x"000000" when others;
  sh_data <= x"0000" & m_reg_read2(15 downto 0) when m_alu_result(1) = '0' else
             m_reg_read2(15 downto 0) & x"0000";
  with m_funct3 select
    s_DMemData <= sb_data when "000", sh_data when "001", m_reg_read2 when others;
  U_WB_SELECT: writeback_select port map(
    w_alu_result, w_dmem_out, w_imm, w_funct3, w_mem_to_reg, w_lui,
    w_pc_plus4, w_jump, w_jump_reg, s_RegWrData);
  s_RegWr <= w_reg_write and not s_reset;
  s_RegWrAddr <= w_rd;
  s_Halt <= w_halt and not s_reset;
end structure;
