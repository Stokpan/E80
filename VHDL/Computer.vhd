-----------------------------------------------------------------------
-- E80 Computer
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Interconnects the CPU with RAM for instruction/data access.
-- Routes DIPinput to CPU when MemAddr=0xFF (memory-mapped I/O).
-- Outputs some internal signals and two 8-word RAM blocks for LED display.
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY Computer IS PORT (
	CLK      : IN STD_LOGIC;
	Reset    : IN STD_LOGIC;
	DIPinput : IN WORD;      -- 8-pin DIP switch user input
	PC       : BUFFER WORD;  -- display
	R        : OUT WORDx8;   -- display
	Instr1   : BUFFER WORD;  -- display
	Instr2   : BUFFER WORD;  -- display
	RAMdisp1 : OUT WORDx8;   -- display RAM(200-207)
	RAMdisp2 : OUT WORDx8    -- display RAM(248-255)
); END;
ARCHITECTURE a1 OF Computer IS
	SIGNAL MemAddr : WORD;
	SIGNAL MemWriteEn : STD_LOGIC;
	SIGNAL MemNext : WORD;
	SIGNAL Mem : WORD;
	SIGNAL Data : WORD; -- [MemAddr] if MemAddr<0xFF, else DIP input
BEGIN
	RAM : ENTITY work.RAM PORT MAP(
		CLK,
		Reset,
		PC,         -- current instruction address
		MemAddr,    -- memory address to be read or written
		MemWriteEn, -- write enable for MemAddr
		MemNext,    -- next cycle value of [MemAddr]
		Instr1,     -- [PC] first part of current instruction
		Instr2,     -- [PC+1] 2nd part (ignored for 1-word instructions)
		Mem,        -- [MemAddr] (RAM output)
		RAMdisp1,   -- Passthrough for display
		RAMdisp2    -- Passthrough for display
	);

	Data <= DIPinput WHEN match(MemAddr,x"FF") ELSE Mem;

	CPU : ENTITY work.CPU PORT MAP(
		CLK,
		Reset,
		Instr1,
		Instr2,
		Data,
		PC,
		MemAddr,
		MemWriteEn,
		MemNext,
		R
	);
END;