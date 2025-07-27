-----------------------------------------------------------------------
-- E80 Computer
-- Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>
-- Interconnects the CPU with RAM for instruction/data access.
-- Routes DIPinput to CPU when MemAddr=0xFF (memory-mapped I/O).
-- Outputs PC and registers for LED display on the FPGA.
-----------------------------------------------------------------------

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY Computer IS PORT (
	CLK      : IN STD_LOGIC;
	Reset    : IN STD_LOGIC;
	DIPinput : IN WORD;      -- 8-pin DIP switch user input
	PC       : BUFFER WORD;
	R        : OUT WORDx8);  -- Passthrough for FPGA LEDs
END;
ARCHITECTURE a1 OF Computer IS
	SIGNAL Instr1, Instr2 : WORD;
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
		Mem);       -- [MemAddr] (RAM output)

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
		R);
END;