-----------------------------------------------------------------------
-- E80 256x8bit multiport RAM
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Declares a 256-word RAM array for storage.
-- Loads the machine code from Program.vhd to the RAM on synchronous reset.
-- Reads two adjacent instruction words at PC and PC+1.
-- Reads or writes a data word at MemAddr.
-- Outputs the entire RAM array for LED display per the .MONITOR directive.
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL, work.program.ALL;
ENTITY RAM IS PORT (
	CLK        : IN STD_LOGIC;
	Reset      : IN STD_LOGIC; -- resets the Program data
	PC         : IN WORD;      -- program counter pointing to Instr1
	MemAddr    : IN WORD;      -- address for Mem and MemNext
	MemWriteEn : IN STD_LOGIC; -- MemAddr write enable
	MemNext    : IN WORD;      -- if MemWriteEn, MemNext → [MemAddr]
	Instr1     : OUT WORD;     -- [PC]
	Instr2     : OUT WORD;     -- [PC+1]
	Mem        : OUT WORD;     -- [MemAddr]
	RAM        : OUT WORDx256  -- RAM storage (+ LED display)
); END;
ARCHITECTURE a1 OF RAM IS
	SIGNAL intPC, intMemAddr : NATURAL RANGE 0 TO 255;
BEGIN
	intPC <= int(PC);
	intMemAddr <= int(MemAddr);
	Instr1 <= RAM(intPC);
	Instr2 <= RAM(intPC+1);
	Mem <= RAM(intMemAddr);
	PROCESS(CLK) BEGIN
		IF RISING_EDGE(CLK) THEN
			IF Reset = '1' THEN
				RAM <= Program;
			ELSIF MemWriteEn = '1' THEN
				RAM(intMemAddr) <= MemNext;
			END IF;
		END IF;
	END PROCESS;
END;