-- E80 ALU test bench
LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, ieee.numeric_std.ALL, work.support.ALL;
ENTITY ALU_TB IS END;
ARCHITECTURE a1 OF ALU_TB IS
	SIGNAL ALUinA  : WORD := "11000010";
	SIGNAL ALUinB  : WORD := "01111110";
	SIGNAL FlagsIn : WORD := "UUUUUUUU";
	SIGNAL ALUop : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
	SIGNAL ALUout, FlagsOut : WORD;
BEGIN
	ALUop <= STD_LOGIC_VECTOR(UNSIGNED(ALUop) + 1) AFTER 50 ps;
	ALU : ENTITY work.ALU PORT MAP(
		ALUop,
		ALUinA,
		ALUinB,
		FlagsIn,
		ALUout,
		FlagsOut);
END;