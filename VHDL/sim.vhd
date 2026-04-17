-- E80 Computer simulation test bench
LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL, work.firmware.ALL;
ENTITY sim IS END;
ARCHITECTURE a1 OF sim IS
	SIGNAL CLK      : STD_LOGIC := '1';
	SIGNAL Reset    : STD_LOGIC := '1';
	SIGNAL DIPinput : WORD := SIMDIP_directive;
	SIGNAL PC       : WORD;
	SIGNAL Instr1   : WORD;
	SIGNAL Instr2   : WORD;
	SIGNAL R        : WORDx8;
	SIGNAL RAM      : WORDx256;
	SIGNAL Halt     : STD_LOGIC;
BEGIN
	Halt <= R(6)(3);
	-- if Halt=1, CLK stops pulsing ⇒ GHDL simulation ends
	CLK <= '0' AFTER 50 ps WHEN CLK OR Halt ELSE '1' AFTER 50 ps;
	Reset <= '0' AFTER 120 ps;
	Computer: ENTITY work.Computer PORT MAP(
		CLK,
		Reset,
		DIPinput,
		PC,
		Instr1,
		Instr2,
		R,
		RAM);
END;