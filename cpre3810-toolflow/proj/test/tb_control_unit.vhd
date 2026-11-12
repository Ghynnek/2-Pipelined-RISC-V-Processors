library IEEE;
use IEEE.std_logic_1164.all;

entity tb_control_unit is
end tb_control_unit;

architecture behavior of tb_control_unit is

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


  signal s_instruction : std_logic_vector(31 downto 0) := (others => '0');
  signal s_RegWrite    : std_logic;
  signal s_MemWrite    : std_logic;
  signal s_MemRead     : std_logic;
  signal s_ALUSrc      : std_logic;
  signal s_MemToReg    : std_logic;
  signal s_Branch      : std_logic;
  signal s_Jump        : std_logic;
  signal s_JumpReg     : std_logic;
  signal s_LUI         : std_logic;
  signal s_AUIPC       : std_logic;
  signal s_ImmSrc      : std_logic_vector(2 downto 0);
  signal s_ALUControl  : std_logic_vector(3 downto 0);

begin

  DUT: control_unit
    port map (
      instruction => s_instruction,
      RegWrite    => s_RegWrite,
      MemWrite    => s_MemWrite,
      MemRead     => s_MemRead,
      ALUSrc      => s_ALUSrc,
      MemToReg    => s_MemToReg,
      Branch      => s_Branch,
      Jump        => s_Jump,
      JumpReg     => s_JumpReg,
      LUI         => s_LUI,
      AUIPC       => s_AUIPC,
      ImmSrc      => s_ImmSrc,
      ALUControl  => s_ALUControl
    );

  process
  begin
    -- 1. R-Type: add x1, x2, x3 (opcode=0110011, funct3=000, funct7=0000000) -> ALUCtrl=0000
    s_instruction <= "0000000" & "00011" & "00010" & "000" & "00001" & "0110011";
    wait for 10 ns;

    -- 2. R-Type: sub x1, x2, x3 (opcode=0110011, funct3=000, funct7=0100000) -> ALUCtrl=0001
    s_instruction <= "0100000" & "00011" & "00010" & "000" & "00001" & "0110011";
    wait for 10 ns;

    -- 3. R-Type: and x1, x2, x3 (funct3=111) -> ALUCtrl=0010
    s_instruction <= "0000000" & "00011" & "00010" & "111" & "00001" & "0110011";
    wait for 10 ns;

    -- 4. R-Type: or x1, x2, x3 (funct3=110) -> ALUCtrl=0011
    s_instruction <= "0000000" & "00011" & "00010" & "110" & "00001" & "0110011";
    wait for 10 ns;

    -- 5. R-Type: xor x1, x2, x3 (funct3=100) -> ALUCtrl=0100
    s_instruction <= "0000000" & "00011" & "00010" & "100" & "00001" & "0110011";
    wait for 10 ns;

    -- 6. R-Type: sll x1, x2, x3 (funct3=001) -> ALUCtrl=0101
    s_instruction <= "0000000" & "00011" & "00010" & "001" & "00001" & "0110011";
    wait for 10 ns;

    -- 7. R-Type: srl x1, x2, x3 (funct3=101, funct7=0000000) -> ALUCtrl=0110
    s_instruction <= "0000000" & "00011" & "00010" & "101" & "00001" & "0110011";
    wait for 10 ns;

    -- 8. R-Type: sra x1, x2, x3 (funct3=101, funct7=0100000) -> ALUCtrl=0111
    s_instruction <= "0100000" & "00011" & "00010" & "101" & "00001" & "0110011";
    wait for 10 ns;

    -- 9. R-Type: slt x1, x2, x3 (funct3=010) -> ALUCtrl=1000
    s_instruction <= "0000000" & "00011" & "00010" & "010" & "00001" & "0110011";
    wait for 10 ns;

    -- 10. I-Type: addi x1, x2, 16 (opcode=0010011, funct3=000) -> ALUSrc=1, ImmSrc=000, ALUCtrl=0000
    s_instruction <= "000000010000" & "00010" & "000" & "00001" & "0010011";
    wait for 10 ns;

    -- 11. I-Type: sltiu x1, x2, 5 (opcode=0010011, funct3=011) -> ALUSrc=1, ALUCtrl=1001
    s_instruction <= "000000000101" & "00010" & "011" & "00001" & "0010011";
    wait for 10 ns;

    -- 12. Load: lw x1, 0(x2) (opcode=0000011, funct3=010) -> RegWrite=1, MemRead=1, MemToReg=1, ALUSrc=1
    s_instruction <= "000000000000" & "00010" & "010" & "00001" & "0000011";
    wait for 10 ns;

    -- 13. Store: sw x3, 4(x2) (opcode=0100011, funct3=010) -> RegWrite=0, MemWrite=1, ImmSrc=001
    s_instruction <= "0000000" & "00011" & "00010" & "010" & "00100" & "0100011";
    wait for 10 ns;

    -- 14. Branch: beq x1, x2, offset (opcode=1100011, funct3=000) -> Branch=1, ImmSrc=010, ALUCtrl=0001
    s_instruction <= "0000000" & "00010" & "00001" & "000" & "01000" & "1100011";
    wait for 10 ns;

    -- 15. Branch: blt x1, x2, offset (opcode=1100011, funct3=100) -> Branch=1, ImmSrc=010, ALUCtrl=1000
    s_instruction <= "0000000" & "00010" & "00001" & "100" & "01000" & "1100011";
    wait for 10 ns;

    -- 16. Branch: bltu x1, x2, offset (opcode=1100011, funct3=110) -> Branch=1, ImmSrc=010, ALUCtrl=1001
    s_instruction <= "0000000" & "00010" & "00001" & "110" & "01000" & "1100011";
    wait for 10 ns;

    -- 17. U-Type: lui x1, 0x10010 (opcode=0110111) -> LUI=1, RegWrite=1, ImmSrc=011
    s_instruction <= x"10010" & "00001" & "0110111";
    wait for 10 ns;

    -- 18. U-Type: auipc x1, 0x00001 (opcode=0010111) -> AUIPC=1, RegWrite=1, ALUSrc=1, ImmSrc=011
    s_instruction <= x"00001" & "00001" & "0010111";
    wait for 10 ns;

    -- 19. J-Type: jal x1, offset (opcode=1101111) -> Jump=1, RegWrite=1, ImmSrc=100
    s_instruction <= x"00008" & "00001" & "1101111";
    wait for 10 ns;

    -- 20. I-Jump: jalr x1, 0(x2) (opcode=1100111) -> JumpReg=1, RegWrite=1, ALUSrc=1, ImmSrc=000
    s_instruction <= "000000000000" & "00010" & "000" & "00001" & "1100111";
    wait for 10 ns;

    wait;
  end process;

end behavior;
