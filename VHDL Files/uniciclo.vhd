library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.riscv_pkg.all;

entity Uniciclo is
    port (
        clockCPU : in  std_logic;
        clockMem : in  std_logic;
        reset    : in  std_logic;
        PC       : out std_logic_vector(31 downto 0);
        Instr    : out std_logic_vector(31 downto 0);
        regin    : in  std_logic_vector(4 downto 0);
        regout   : out std_logic_vector(31 downto 0)
    );
end Uniciclo;

architecture Behavioral of Uniciclo is
    component ControlUnit is
    port (
        opcode      : in  STD_LOGIC_VECTOR (6 downto 0); -- Opcode da instrução
        zero_flag   : in  STD_LOGIC; -- Flag da ULA para BEQ
        ALUOpType   : out STD_LOGIC_VECTOR(1 downto 0);
        RegWrite    : out STD_LOGIC;
        MemRead     : out STD_LOGIC;
        MemWrite    : out STD_LOGIC;
        ALUSrc      : out STD_LOGIC;
        WBDataSel   : out STD_LOGIC_VECTOR(1 downto 0); -- Write-Back Data Select: 00=ALU, 01=Mem, 10=PC+4
        BranchPCSel : out STD_LOGIC; -- Condição de Branch
        Jump        : out STD_LOGIC);
    end component;

    component xregs is
    generic (
        SIZE : natural := 32;
        ADDR : natural := 5);
    port (
        iCLK        : in  std_logic;
        iRST        : in  std_logic;
        iWREN       : in  std_logic;
        iRS1        : in  std_logic_vector(ADDR-1 downto 0);
        iRS2        : in  std_logic_vector(ADDR-1 downto 0);
        iRD     : in  std_logic_vector(ADDR-1 downto 0);
        iDATA       : in  std_logic_vector(SIZE-1 downto 0);
        oREGA   : out std_logic_vector(SIZE-1 downto 0);
        oREGB   : out std_logic_vector(SIZE-1 downto 0);
       
        iDISP       : in  std_logic_vector(ADDR-1 downto 0);
        oREGD       : out std_logic_vector(SIZE-1 downto 0));
    end component;

    component ALUControl is
    port (
        ALUOpType   : in  STD_LOGIC_VECTOR (1 downto 0); -- Sinal da unidade de controle principal
        funct3  : in  STD_LOGIC_VECTOR (2 downto 0); -- Campo da instrução
        funct7  : in  STD_LOGIC;                     -- Bit usado para distinguir add/sub (bit 30)
        ALUCtrl : out STD_LOGIC_VECTOR (4 downto 0));  -- Sinal para a ULA
    end component;

    component ALU is
    port (
        iControl : in  std_logic_vector(4 downto 0);
        iA       : in  std_logic_vector(31 downto 0);
        iB       : in  std_logic_vector(31 downto 0);
        oResult  : out std_logic_vector(31 downto 0));
    end component;

    component genImm32 is
port (
instr : in std_logic_vector(31 downto 0);
imm32 : out std_logic_vector(31 downto 0));
    end component;

    -- Sinais internos
    signal PC_internal      : std_logic_vector(31 downto 0) := x"00400000";
    signal Instr_internal   : std_logic_vector(31 downto 0) := (others => '0');
    signal regout_internal  : std_logic_vector(31 downto 0) := (others => '0');
    signal SaidaULA         : std_logic_vector(31 downto 0);
    signal ZeroFlag         : std_logic;
    signal Leitura1, Leitura2   : std_logic_vector(31 downto 0);
    signal EscreveMem       : std_logic;
    signal LeMem            : std_logic;
    signal EscreveReg       : std_logic;
    signal OrigULA          : std_logic;
    signal ALUOpType        : std_logic_vector(1 downto 0);
    signal WBDataSel        : std_logic_vector(1 downto 0);
    signal Immediate        : std_logic_vector(31 downto 0);
    signal MemData          : std_logic_vector(31 downto 0);
    signal ALUControlSig    : std_logic_vector(4 downto 0);
    signal SrcB             : std_logic_vector(31 downto 0);
    signal WBData           : std_logic_vector(31 downto 0);
    signal BranchPCSel      : std_logic;
    signal Jump             : std_logic;

    -- Instrução decodificada
    signal opcode           : std_logic_vector(6 downto 0);
    signal rs1, rs2, rd     : std_logic_vector(4 downto 0);
    signal funct3           : std_logic_vector(2 downto 0);
    signal funct7_5         : std_logic; -- instr(30)
   

begin
    -- Atribuição das saí­das
    PC     <= PC_internal;
    Instr  <= Instr_internal;
    regout <= regout_internal;
   
    -- Processo para atualização do PC
    process(clockCPU, reset)
    begin
        if reset = '1' then
            PC_internal <= x"00400000";
        elsif rising_edge(clockCPU) then
            if Jump = '1' then
                if opcode = "1100111" then -- JALR
                    PC_internal <= std_logic_vector((unsigned(Leitura1) + unsigned(Immediate)) and x"FFFFFFFE");
                else -- JAL
                    PC_internal <= std_logic_vector(unsigned(PC_internal) + unsigned(Immediate));
                end if;
            elsif BranchPCSel = '1' then
                PC_internal <= std_logic_vector(unsigned(PC_internal) + unsigned(Immediate));
            else
                PC_internal <= std_logic_vector(unsigned(PC_internal) + 4);
            end if;
        end if;
    end process;
   
    -- Instanciação da memória de instruções
    MemC : ramI
        port map (
            address => PC_internal(11 downto 2),
            clock   => clockMem,
            data    => (others => '0'),
            wren    => '0',
            q       => Instr_internal
        );
   
    -- Instanciação da memória de dados
    MemD : ramD
        port map (
            address => SaidaULA(11 downto 2),
            clock   => clockMem,
            data    => Leitura2,
            wren    => EscreveMem,
            q       => MemData
        );

    -- Campos decodificados
    opcode    <= Instr_internal(6 downto 0);
    rd        <= Instr_internal(11 downto 7);
    funct3    <= Instr_internal(14 downto 12);
    rs1       <= Instr_internal(19 downto 15);
    rs2       <= Instr_internal(24 downto 20);
    funct7_5  <= Instr_internal(30);

    -- Immediate generator
    ImmGen1 : genImm32
        port map (
            instr    => Instr_internal,
            imm32  => Immediate
        );

    -- Unidade de Controle
    CU1 : ControlUnit
        port map (
            opcode      => opcode,
            zero_flag   => ZeroFlag,
            ALUOpType   => ALUOpType,
            RegWrite    => EscreveReg,
            MemRead     => LeMem,
            MemWrite    => EscreveMem,
            ALUSrc      => OrigULA,
            WBDataSel   => WBDataSel,
            BranchPCSel => BranchPCSel,
            Jump        => Jump
        );

    -- Banco de Registradores
    Regs1 : xregs
        port map (
            iCLK     => clockCPU,
            iRST     => reset,
            iWREN    => EscreveReg,
            iRS1     => rs1,
            iRS2     => rs2,
            iRD      => rd,
            iDATA    => WBData,
            oREGA    => Leitura1,
            oREGB    => Leitura2,
            iDISP    => regin,
            oREGD    => regout_internal
        );

    -- ALU Control
    ALUCtrl1 : ALUControl
        port map (
            ALUOpType => ALUOpType,
            funct3    => funct3,
            funct7    => funct7_5,
            ALUCtrl   => ALUControlSig
        );

    -- MUX seleciona operandos da ULA (registrador ou imediato)
    SrcB <= Immediate when OrigULA = '1' else Leitura2;

    -- ULA
    ALU1 : ALU
        port map (
            iA        => Leitura1,
            iB        => SrcB,
            iControl  => ALUControlSig,
            oResult   => SaidaULA
        );

    -- Mux Write Back: seleciona o dado a ser escrito no banco de registradores
    WBData <=
        SaidaULA    when WBDataSel = "00" else
        MemData     when WBDataSel = "01" else
        std_logic_vector(unsigned(PC_internal) + 4) when WBDataSel = "10" else
        (others => '0');
   
end Behavioral;