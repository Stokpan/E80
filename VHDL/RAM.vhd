-----------------------------------------------------------------------
-- E80 256x8 RAM
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Stores 256 words in 8-bit flip flops.
-- Reads a two-word instruction at PC and PC+1 addresses, and the Mem
-- word at MemAddr; updates the Mem word to MemNext if MemWriteEn=1.
-- Uploads the firmware to the RAM upon a synchronous reset.
-- Outputs two 8-word blocks for LED display on Interface.vhd
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL, work.firmware.ALL;
ENTITY RAM IS PORT (
	CLK        : IN STD_LOGIC;
	Reset      : IN STD_LOGIC;
	PC         : IN WORD;      -- current instruction address
	MemAddr    : IN WORD;      -- address for Mem and MemNext
	MemWriteEn : IN STD_LOGIC; -- write enable
	MemNext    : IN WORD;      -- if MemWriteEn, MemNext → [MemAddr]
	Instr1     : OUT WORD;     -- [PC]
	Instr2     : OUT WORD;     -- [PC+1]
	Mem        : OUT WORD;     -- [MemAddr]
	RAMdisp1   : OUT WORDx8;   -- for display of RAM addresses 200-207
	RAMdisp2   : OUT WORDx8    -- for display of RAM addresses 248-255
); END;
ARCHITECTURE a1 OF RAM IS
	SIGNAL RAMnext, RAM : WORDx256;
	SIGNAL i1, i2, a : NATURAL RANGE 0 TO 255;
BEGIN
	i1 <= int(PC);
	i2 <= i1+1;
	a <= int(MemAddr);
	DFF_Array: FOR i IN 0 TO 255 GENERATE
		DFF8 : ENTITY work.DFF8 PORT MAP(CLK, RAMnext(i), RAM(i));
		RAMnext(i) <=
			Firmware(i) WHEN Reset = '1'                ELSE
			MemNext     WHEN MemWriteEn = '1' AND i = a ELSE
			RAM(i);
	END GENERATE;
	Instr1 <= RAM(i1);
	Instr2 <= RAM(i2);
	Mem <= RAM(a);
	RAMdisplay: FOR i IN 0 TO 7 GENERATE
		RAMdisp1(i) <= RAM(200 + i);
		RAMdisp2(i) <= RAM(248 + i);
	END GENERATE;
END;