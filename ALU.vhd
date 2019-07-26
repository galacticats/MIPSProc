-- Student name: Bianca Tang
-- Student ID number: 38478644

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use work.Glob_dcls.all;
USE IEEE.numeric_std.all;

entity ALU is 
  PORT( op_code  : in ALU_opcode;
        in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount	
        ALUout   : out word; --word: std_logic_vector (31 DOWNTO 0)
        Zero     : out std_logic); --generates 1 when ALUout = '0'
end ALU;

architecture ALU_arch of ALU is
-- signal declaration
SIGNAL resultBuffer : word;
SIGNAL shiftBuffer : word;

begin
  --Set the zero flag here as a concurrent statement
  Zero <= '1' WHEN resultBuffer = "00000000000000000000000000000000" ELSE '0';

  ALUout <= resultBuffer;

  ALUProc: PROCESS (in0, in1, C, op_code)
  VARIABLE shiftTemp : std_logic_vector (31 DOWNTO 0);
  BEGIN
    CASE op_code IS
      WHEN "000" => --ADD: out, in0, in1 -> out = in0 + in1
        resultBuffer <= in0 + in1;
      WHEN "001" => --SUB: out, in0, in1 -> out = in0 - in1
        resultBuffer <= in0 - in1;
      WHEN "010" => --SLL: out, in0, C -> out = in0 << C
        resultBuffer <= std_logic_vector(signed(in0) sll to_integer(unsigned(C)));
      WHEN "011" => --SRL: out, in0, C -> out = in0 >> C
	resultBuffer <= std_logic_vector(signed(in0) srl to_integer(unsigned(C)));
      WHEN "100" => --AND: out, in0, in1 -> out = in0 & in1 (bitwise and)
	resultBuffer <= in0 AND in1;
      WHEN "101" => --OR: out, in0, in1 -> out = in0 | in1 (bitwise or)
	resultBuffer <= in0 OR in1;
      WHEN "110" => --XOR: out, in0, in1 -> out = in0 ^ in1 (bitwise xor)
	resultBuffer <= in0 XOR in1;
      WHEN "111" => --NOR: out, in0, in1 -> out = ~(in0|in1)
	resultBuffer <= NOT(in0 OR in1);
      WHEN OTHERS => 
      --Take into account X, U, etc as possible values
        null;
    END CASE;
  END PROCESS ALUProc;
end ALU_arch;
