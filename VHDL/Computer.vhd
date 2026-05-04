-----------------------------------------------------------------------
-- E80 Computer
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Interconnects the CPU with RAM for instruction/data access.
-- Routes DIPinput to CPU when MemAddr=0xFF (memory-mapped I/O).
-- Outputs all signals required for LED display.
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY Computer IS PORT (
	CLK      : IN STD_LOGIC;
	Reset    : IN STD_LOGIC; -- resets the PC, SP, Halt, and Program data
	DIPinput : IN WORD;      -- 8-bit DIP switch user input
	PC       : BUFFER WORD;  -- program counter (+ LED display)
	R        : OUT WORDx8;   -- register file (LED display)
	RAM      : OUT WORDx256  -- RAM contents (LED display)
); END;
ARCHITECTURE a1 OF Computer IS
	SIGNAL Instr1 : WORD;          -- instruction part 1 / [PC]
	SIGNAL Instr2 : WORD;          -- instruction part 2 / [PC+1]
	SIGNAL MemAddr : WORD;         -- memory address to be read or written
	SIGNAL Mem : WORD;             -- current value at MemAddr
	SIGNAL MemNext : WORD;         -- next cycle value at MemAddr
	SIGNAL MemWriteEn : STD_LOGIC; -- write enable for MemAddr
	SIGNAL Data : WORD;            -- Mem if MemAddr<0xFF, else DIP input
BEGIN
	RAM_inst : ENTITY work.RAM PORT MAP(
		CLK,
		Reset,
		PC,
		MemAddr,    
		MemWriteEn,
		MemNext,
		Instr1,
		Instr2,
		Mem,        
		RAM
	);

	Data <= DIPinput WHEN match(MemAddr,x"FF") ELSE Mem;

	CPU_inst : ENTITY work.CPU PORT MAP(
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