-----------------------------------------------------------------------
-- E80 256x8bit RAM
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Depends on a WORDx256-typed array for RAM storage.
-- Outputs [PC] and [PC+1] to instruction parts Instr1 and Instr2
-- Outputs [MemAddr] to Mem
-- Writes MemNext to MemAddr if MemWriteEn = 1.
-- Loads the machine code from Firmware.vhd to the RAM on synchronous reset.
-- Outputs the entire RAM content for display through the .MONITOR directive.
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL, work.firmware.ALL;
ENTITY RAM IS PORT (
	CLK        : IN STD_LOGIC;
	Reset      : IN STD_LOGIC;
	PC         : IN WORD;         -- program counter
	MemAddr    : IN WORD;         -- address for Mem and MemNext
	MemWriteEn : IN STD_LOGIC;    -- MemAddr write enable
	MemNext    : IN WORD;         -- if MemWriteEn, MemNext → [MemAddr]
	Instr1     : OUT WORD;        -- [PC]
	Instr2     : OUT WORD;        -- [PC+1]
	Mem        : OUT WORD;        -- [MemAddr]
	RAM        : BUFFER WORDx256  -- RAM storage, also routed to Interface.vhd
); END;

ARCHITECTURE a1 OF RAM IS
BEGIN
	PROCESS(ALL)
		VARIABLE intPC, intMemAddr : NATURAL RANGE 0 TO 255;
	BEGIN
		intPC := int(PC);
		intMemAddr := int(MemAddr);
		Instr1 <= RAM(intPC);
		Instr2 <= RAM(intPC+1);
		Mem <= RAM(intMemAddr);
		-- Write after reading, to safeguard against returning the new value
		IF RISING_EDGE(CLK) THEN
			IF Reset = '1' THEN
				RAM <= Firmware;
			ELSIF MemWriteEn = '1' THEN
				RAM(intMemAddr) <= MemNext;
			END IF;
		END IF;
	END PROCESS;
END;