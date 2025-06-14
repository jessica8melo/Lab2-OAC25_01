library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.riscv_pkg.all;

-- Q1.6: o bloco controlador é responsável por, a partir do campo de opcode da instrução 
-- e eventualmente flags),gerar os sinais de controle para todo o datapath:
--      Sinais para a ULA (na forma de ALUOp, depois detalhada pelo iControl para a ULA);
--      Sinais de escrita/leitura de registrador;
--      Sinais de acesso à memória;
--      Sinais para seleção de imediato, para muxes, etc.

entity ControlUnit is
    Port (
        opcode      : in  STD_LOGIC_VECTOR (6 downto 0); -- Opcode da instrução
        zero_flag   : in  STD_LOGIC; -- Flag da ULA para BEQ
        ALUOpType   : out STD_LOGIC_VECTOR(1 downto 0);
        RegWrite    : out STD_LOGIC;
        MemRead     : out STD_LOGIC;
        MemWrite    : out STD_LOGIC;
        ALUSrc      : out STD_LOGIC;
        WBDataSel   : out STD_LOGIC_VECTOR(1 downto 0); -- Write-Back Data Select: 00=ALU, 01=Mem, 10=PC+4
        BranchPCSel : out STD_LOGIC; -- Condição de Branch
        Jump        : out STD_LOGIC
    );
end ControlUnit;

architecture Behavioral of ControlUnit is
   
begin
    process(opcode, zero_flag)
    begin
        -- Valores inativos padrão
        ALUOpType   <= "00";
        RegWrite    <= '0';
        MemRead     <= '0';
        MemWrite    <= '0';
        ALUSrc      <= '0';
        WBDataSel   <= WB_ALU;
        BranchPCSel <= '0';
        Jump        <= '0';

        case opcode is
         
            when OPC_RTYPE =>
                ALUOpType   <= "10";
                RegWrite    <= '1';
                ALUSrc      <= '0';
                WBDataSel   <= WB_ALU;
           
            when OPC_OPIMM =>
                ALUOpType   <= "11";
                RegWrite    <= '1';
                ALUSrc      <= '1';
                WBDataSel   <= WB_ALU;
           
            when OPC_LOAD =>
                ALUOpType   <= "00";
                RegWrite    <= '1';
                MemRead     <= '1';
                ALUSrc      <= '1';
                WBDataSel   <= WB_MEM;
           
            when OPC_STORE =>
                ALUOpType   <= "00";
                MemWrite    <= '1';
                ALUSrc      <= '1';
           
            when OPC_BRANCH =>
                ALUOpType   <= "01";
                ALUSrc      <= '0';
                BranchPCSel <= zero_flag;
           
            when OPC_JAL =>
                ALUOpType   <= "00";
                RegWrite    <= '1';
                ALUSrc      <= '1';
                WBDataSel   <= WB_PC4;
                Jump        <= '1';
           
            when OPC_JALR =>
                ALUOpType   <= "00";
                RegWrite    <= '1';
                ALUSrc      <= '1';
                WBDataSel   <= WB_PC4;
                Jump        <= '1';
            when others =>
                null;
        end case;
    end process;
end Behavioral;