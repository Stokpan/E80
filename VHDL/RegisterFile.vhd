-----------------------------------------------------------------------
-- E80 8x8 Register File
-- Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>
-- Reads A_reg, B_reg, and Flags; writes to A_reg and W_reg. Reset is
-- synchronous (to ensure a full first cycle) and clears only the SP and
-- the Halt flag, leaving the rest to undefined.
-- The R-array (FPGA LED output) is passed to the final FPGA component for
-- display and should *not* be accessible by the CPU.
-- R0-R5: General-purpose registers, R6: Flags register, R7: Stack pointer
-----------------------------------------------------------------------

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY RegisterFile IS PORT (
	CLK    : IN STD_LOGIC;
	Reset  : IN STD_LOGIC;
	A_reg  : IN REG_ADDR;    -- read/write register
	A_next : IN WORD;        -- next cycle value of A_reg
	B_reg  : IN REG_ADDR;    -- read only register
	W_reg  : IN REG_ADDR;    -- write only register
	W_next : IN WORD;        -- next cycle value of W_reg
	A_val  : OUT WORD;       -- current value of A_reg
	B_val  : OUT WORD;       -- current value of B_reg
	Flags  : OUT WORD;       -- current value of Flags Register
	R      : OUT WORDx8);    -- all current register values for FPGA LED output
END;
ARCHITECTURE a1 OF RegisterFile IS
	SIGNAL Rnext : WORDx8; -- stored values
	SIGNAL a, b, w : NATURAL RANGE 0 TO 7; -- indexes
	-- Clear the Halt flag and reset the Stack Pointer to 255 to reserve this
	-- address for DIP input. Everything else is set to undefined for easier
	-- inspection in ModelSim/GHDL and to enforce good programming practices.
	CONSTANT Init : WORDx8 := (6 => "UUUU0UUU", 7 => x"FF", OTHERS => x"UU");
BEGIN
	a <= int(A_reg);
	b <= int(B_reg);
	w <= int(W_reg);
	DFF_Array: FOR i IN 0 TO 7 GENERATE
		DFF8 : ENTITY work.DFF8 PORT MAP(CLK, Rnext(i), R(i));
		Rnext(i) <=
			 Init(i) WHEN Reset ELSE
			 -- Typically, a=w when trying to modify the FLAGS register,
			 -- eg. by OR FLAGS, 0b10000000 which would set the Carry flag.
			 -- In these cases, it's essential to pass the data from ALUresult
			 -- (A_next) instead of the normal ALU Flags output (W_next).
			 A_next  WHEN i = a ELSE -- higher priority for A_next when a=w
			 W_next  WHEN i = w ELSE
			 R(i);
	END GENERATE;
	A_val <= R(a);
	B_val <= R(b);
	Flags <= R(6);
END;