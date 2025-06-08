library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.riscv_pkg.all;

-- Q1.5: a ULA executa operações aritméticas e faz comparações/manipulações
-- de bits sobre dados processados. Para tal, ela requer:
--      Uma entrada (iControl) que seleciona a operação da ULA a partir de seu valor correspondente;
--      Dois operandos de 32 bits (iA e iB);
--      Resultado da operação feita (oResult).

entity ALU is
    Port (
        iControl : in  std_logic_vector(4 downto 0);
        iA       : in  std_logic_vector(31 downto 0);
        iB       : in  std_logic_vector(31 downto 0);
        oResult  : out std_logic_vector(31 downto 0)
    );
end ALU;

architecture Behavioral of ALU is

    constant ZERO   : std_logic_vector(31 downto 0) := (others => '0');

    signal result_internal : std_logic_vector(31 downto 0);

signal mul, mulu : std_logic_vector(63 downto 0);

begin

mul <= std_logic_vector(signed(iA) * signed(iB));
mulu <= std_logic_vector(unsigned(iA) * unsigned(iB));

    process(iControl, iA, iB, mul, mulu)
        variable shamt : integer range 0 to 31;
    begin
 result_internal <= ZERO32;
        shamt := to_integer(unsigned(iB(4 downto 0)));
        case iControl is
            when OPAND  =>
                result_internal <= iA and iB;
            when OPOR   =>
                result_internal <= iA or iB;
            when OPXOR  =>
                result_internal <= iA xor iB;
            when OPADD  =>
                result_internal <= std_logic_vector(signed(iA) + signed(iB));
            when OPSUB  =>
                result_internal <= std_logic_vector(signed(iA) - signed(iB));
            when OPSLT  =>
                if signed(iA) < signed(iB) then
                    result_internal <= (0 => '1', others => '0');
                else
                    result_internal <= (others => '0');
                end if;
            when OPSLTU =>
                if unsigned(iA) < unsigned(iB) then
                    result_internal <= (0 => '1', others => '0');
                else
                    result_internal <= (others => '0');
                end if;
            when OPSLL  =>
                result_internal <= std_logic_vector(shift_left(signed(iA), shamt));
            when OPSRL  =>
                result_internal <= std_logic_vector(shift_right(unsigned(iA), shamt));
            when OPSRA  =>
                result_internal <= std_logic_vector(shift_right(signed(iA), shamt)); -- arithmetic shift
            when OPLUI  =>
                result_internal <= iB;
when OPMUL =>
result_internal  <= mul(31 downto 0);
when OPMULH =>
result_internal  <= mul(63 downto 32);
when OPMULHU =>
result_internal  <= mulu(63 downto 32);

            when others =>
                result_internal <= ZERO;
        end case;
    end process;

    oResult <= result_internal;

end Behavioral;