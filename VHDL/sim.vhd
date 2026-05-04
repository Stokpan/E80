-----------------------------------------------------------------------
-- E80 Computer Simulation Top Unit
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Runs the E80 Computer on a simulated clock after a short reset.
-- Gates the clock to low on Halt to end simulation on GHDL.
-- Generates a .MONITOR vector to display as an ASCII row.
-- Generates a .MONITOR array to display as 8 binary rows.
-----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL, work.program.ALL;
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
	SIGNAL MonitorVector  : STD_LOGIC_VECTOR(0 TO 63);
	SIGNAL MonitorArray : WORDx8;
BEGIN
	Halt <= R(6)(3);
	CLK <= '0' AFTER 50 ps WHEN CLK OR Halt ELSE '1' AFTER 50 ps;
	Reset <= '0' AFTER 120 ps;
	Instr1 <= RAM(int(PC));
	Instr2 <= RAM(int(PC)+1);
	Computer: ENTITY work.Computer PORT MAP(
		CLK,
		Reset,
		DIPinput,
		PC,
		R,
		RAM);
	MonitorBlock: FOR i IN 0 TO 7 GENERATE
		MonitorVector(8*i TO 8*i+7) <= RAM(MONITOR_directive + i);
		MonitorArray(i) <= RAM(MONITOR_directive + i);
	END GENERATE;
END;