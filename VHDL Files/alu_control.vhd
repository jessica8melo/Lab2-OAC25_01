library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALUControl is
    Port (
        ALUOp   : in  STD_LOGIC_VECTOR (1 downto 0); -- Sinal da unidade de controle principal
        funct3  : in  STD_LOGIC_VECTOR (2 downto 0); -- Campo da instrução
        funct7  : in  STD_LOGIC;                     -- Bit usado para distinguir add/sub (bit 30)
        ALUCtrl : out STD_LOGIC_VECTOR (2 downto 0)  -- Sinal para a ULA
    );
end ALUControl;

architecture Behavioral of ALUControl is
    constant ALU_ADD : STD_LOGIC_VECTOR(2 downto 0) := "000";
    constant ALU_SUB : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant ALU_AND : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant ALU_OR  : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant ALU_SLT : STD_LOGIC_VECTOR(2 downto 0) := "100";
begin

    process (ALUOp, funct3, funct7)
    begin
        case ALUOp is
            when "00" => -- LW / SW sempre ADD
                ALUCtrl <= ALU_ADD;
            when "01" => -- BEQ usa SUB
                ALUCtrl <= ALU_SUB;
            when "10" => -- R-type (depende do funct3, funct7)
                case funct3 is
                    when "000" => -- ADD ou SUB
                        if funct7 = '1' then
                            ALUCtrl <= ALU_SUB; -- SUB
                        else
                            ALUCtrl <= ALU_ADD; -- ADD
                        end if;
                    when "010" => -- SLT
                        ALUCtrl <= ALU_SLT;
                    when "110" => -- OR
                        ALUCtrl <= ALU_OR;
                    when "111" => -- AND
                        ALUCtrl <= ALU_AND;
                    when others =>
                        ALUCtrl <= ALU_ADD; -- padrão seguro
                end case;
            when "11" => -- I-type aritmético (ADDI, SLTI, ANDI, ORI)
                case funct3 is
                    when "000" => ALUCtrl <= ALU_ADD; -- ADDI
                    when "010" => ALUCtrl <= ALU_SLT; -- SLTI
                    when "110" => ALUCtrl <= ALU_OR;  -- ORI
                    when "111" => ALUCtrl <= ALU_AND; -- ANDI
                    when others => ALUCtrl <= ALU_ADD;
                end case;
            when others => -- padrão seguro
                ALUCtrl <= ALU_ADD;
        end case;
    end process;

end Behavioral;