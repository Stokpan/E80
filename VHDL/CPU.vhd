-----------------------------------------------------------------------
-- E80 CPU
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Fetches instruction and data from the RAM and the DIP input.
-- Decodes the instruction to get the control signals, addresses and values.
-- Reads registers from the Register Array.
-- Assigns input values to the ALU.
-- Writes the result of the ALU to the registers and the RAM.
-- Advances to the next instruction.
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY CPU IS PORT (
	CLK        : IN STD_LOGIC;
	Reset      : IN STD_LOGIC;  -- resets the PC
	Instr1     : IN WORD;       -- instruction part 1 / [PC]
	Instr2     : IN WORD;       -- instruction part 2 / [PC+1]
	Data       : IN WORD;       -- [MemAddr] if MemAddr<0xFF, else DIP input
	PC         : BUFFER WORD;   -- program counter (+ LED display)
	MemAddr    : OUT WORD;      -- memory address to be read or written
	MemWriteEn : OUT STD_LOGIC; -- write enable for MemAddr
	MemNext    : OUT WORD;      -- next cycle value at MemAddr
	R          : OUT WORDx8     -- register file (LED display)
); END;
ARCHITECTURE a1 OF CPU IS
	-- Instruction format signal aliases
	--                     Instr1                          Instr2
	--          7   6   5   4   3   2   1   0   7   6   5   4   3   2   1   0
	--        +-------------------------------+
	-- Type 1 |            opcode             |
	--        +-------------------------------+
	--        +---------------+---+-----------+
	-- Type 2 |     opcode    | 0 |    reg    |
	--        +---------------+---+-----------+
	--        +-------------------------------+-------------------------------+
	-- Type 3 |            opcode             |             direct            |
	--        +-------------------------------+-------------------------------+
	--        +---------------+---+-----------+---+-----------+---+-----------+
	-- Type 4 |     opcode    | 1 | 0   0   0 | 0 |    reg1   | 0 |   reg2    |
	--        +---------------+---+-----------+---+-----------+---+-----------+
	--        +---------------+---+-----------+-------------------------------+
	-- Type 5 |     opcode    | 0 |    reg    |      immediate or direct      |
	--        +---------------+---+-----------+-------------------------------+
	-- op2isReg defines the position of arguments in type 2, 4 and 5.
	-- op2isReg=1 ⇒ op2=register in Instr2[2:0], op1=register in Instr1[6:4]
	-- op2isReg=0 ⇒ op2=immediate/direct/nil,    op1=register in Instr1[2:0]
	-- eg. in ADD R0,R1 op2isReg=1 whereas in ADD R0,10 or PUSH R0 op2isReg=0.
	ALIAS op2isReg   : STD_LOGIC IS Instr1(3);
	ALIAS Instr1Reg  : REG_ADDR IS Instr1(2 DOWNTO 0);
	ALIAS Instr2Reg1 : REG_ADDR IS Instr2(6 DOWNTO 4);
	ALIAS Instr2Reg2 : REG_ADDR IS Instr2(2 DOWNTO 0);
	-- Instruction Decoder output
	SIGNAL isHLT, isNOP, isJMP, isJC, isJNC, isJZ, isJNZ, isJV, isJNV,
		isJS, isJNS, isCALL, isRETURN, isSTORE, isLOAD, isMOV,
		isSHIFT, isPUSH, isPOP, isStack : STD_LOGIC;
	-- Register signals
	SIGNAL A_reg     : REG_ADDR; -- accumulator address (usually 1st operand)
	SIGNAL A_val     : WORD;     -- current value of A_reg
	SIGNAL A_next    : WORD;     -- next cycle value of A_reg
	SIGNAL B_reg     : REG_ADDR; -- read register address (usually 2nd operand)
	SIGNAL B_val     : WORD;     -- current value of B_reg
	SIGNAL W_reg     : REG_ADDR; -- write register address (usually R6)
	SIGNAL W_next    : WORD;     -- next cycle value of W_reg
	SIGNAL Flags     : WORD;     -- current value of Flags Register
	CONSTANT FlagsRegister : REG_ADDR := "110"; -- R6
	CONSTANT StackPointer  : REG_ADDR := "111"; -- R7
	-- Flags
	ALIAS Carry    : STD_LOGIC IS Flags(7);
	ALIAS Zero     : STD_LOGIC IS Flags(6);
	ALIAS Sign     : STD_LOGIC IS Flags(5);
	ALIAS Overflow : STD_LOGIC IS Flags(4);
	ALIAS Halt     : STD_LOGIC IS Flags(0);
	-- ALU signals
	SIGNAL op2      : WORD;
	SIGNAL FlagsOut : WORD;
	SIGNAL ALUout   : WORD;
	SIGNAL noALU    : STD_LOGIC;
	-- Execution control flow signals
	-- if Jumping=0, PCnext ← Adjacent
	-- if Jumping=1, PCnext ← jump, call, or return address
	SIGNAL Size     : WORD;      -- current instruction size
	SIGNAL Adjacent : WORD;      -- address of adjacent instruction (PC + Size)
	SIGNAL Jumping  : STD_LOGIC; -- are we jumping ?
	SIGNAL PCnext   : WORD;      -- address of the next instruction to execute
BEGIN
	-----------------------------------------------------------------------
	-- Instruction Decoder
	-----------------------------------------------------------------------
	-- By default, all instructions are treated as types 4 and 5 with opcodes
	-- matching their required ALUop. The following ones need custom handling:
	isHLT    <= match(Instr1,"00000000");
	isNOP    <= match(Instr1,"00000001");
	isJMP    <= match(Instr1,"00000010");
	isJC     <= match(Instr1,"00000100");
	isJNC    <= match(Instr1,"00000101");
	isJZ     <= match(Instr1,"00000110");
	isJNZ    <= match(Instr1,"00000111");
	isJS     <= match(Instr1,"00001000");
	isJNS    <= match(Instr1,"00001001");
	isJV     <= match(Instr1,"00001010");
	isJNV    <= match(Instr1,"00001011");
	isCALL   <= match(Instr1,"11101000");
	isRETURN <= match(Instr1,"11111000");
	isSTORE  <= match(Instr1,"1000----");
	isLOAD   <= match(Instr1,"1001----");
	isMOV    <= match(Instr1,"0001----");
	isSHIFT  <= match(Instr1,"10100---") OR   -- LSHIFT
	            match(Instr1,"11010---");     -- RSHIFT
	isPUSH   <= match(Instr1,"11100---");
	isPOP    <= match(Instr1,"11110---");
	noALU    <= match(Instr1,"-00-----");     -- bypass ALU and flags
	isStack  <= isPUSH OR isCALL OR isPOP OR isRETURN;
	-------------------------------------------------------------------
	-- Arithmetic Logical Unit
	-------------------------------------------------------------------
	ALU_inst : ENTITY work.ALU PORT MAP(
		Instr1(7 DOWNTO 4), -- all instructions start with their ALU opcode
		A_val,              -- ALUinA = A_reg's current value
		op2,                -- ALUinB = op2
		Flags,
		ALUout,
		FlagsOut);
	-- op2 is either an immediate (Instr2) or register (B_val)
	op2 <= B_val WHEN op2isReg ELSE Instr2;
	-------------------------------------------------------------------
	-- Registers
	-------------------------------------------------------------------
	RegisterFile_inst : ENTITY work.RegisterFile PORT MAP(
		CLK,
		Reset,
		A_reg,  -- accumulator (usually 1st operand) address
		A_next, -- next cycle value of accumulator = ALUout
		B_reg,  -- read register (usually 2nd operand) address
		W_reg,  -- write register (flags or POP reg) address
		W_next, -- next cycle value of W_reg
		A_val,  -- current value of A_reg
		B_val,  -- current value of B_reg
		Flags,  -- current value of Flags Register
		R);     -- FPGA LED output (not accessible on the CPU)
	-- A_reg, the ALU accumulator, is set to the first operand in all
	-- instruction types, except for stack operations where it's set to the
	-- stack pointer to be increased or decreased by the ALU.
	A_reg <=
		StackPointer WHEN isStack  ELSE
		Instr2Reg1   WHEN op2isReg ELSE -- type 4
		Instr1Reg;                      -- type 2 or 5
	A_next <=
		Data  WHEN isLOAD ELSE
		op2   WHEN isMOV  ELSE -- prioritize MOV (which is also noALU)
		A_val WHEN noALU  ELSE -- keep A_reg unmodified
		ALUout;
	-- B_reg's value is used in op2, or as a memory address for LOAD/STORE.
	-- B_reg is almost exclusively set to Instr2Reg2, except for PUSH where
	-- A_reg is assigned to the stack pointer and Instr1Reg's value needs to
	-- be read through B_reg / B_val to be stored in the RAM.
	B_reg <= Instr1Reg WHEN isPUSH ELSE Instr2Reg2;
	-- W_reg is the write register. It's almost exclusively set to the
	-- flags register, except for POP which writes on its Instr1Reg.
	W_reg <= Instr1Reg WHEN isPOP ELSE FlagsRegister;
	W_next <=
		Data           WHEN isPOP ELSE
		Flags OR x"01" WHEN isHLT ELSE -- HLT sets the Halt flag
		Flags          WHEN noALU ELSE
		FlagsOut;                      -- ALU flags output
	-------------------------------------------------------------------
	-- Memory access
	-------------------------------------------------------------------
	-- All operations that use memory addressing, specified with [...]
	-- brackets in the ISA, assign MemAddr to the address in the bracket.
	MemAddr <=
		A_val  WHEN isPOP OR isRETURN ELSE -- SP before increase
		ALUout WHEN isPUSH OR isCALL  ELSE -- SP after decrease
		op2;                               -- LOAD/STORE
	-- set MemWriteEn for all "→ [...]" operations in the ISA Cheatsheet
	MemWriteEn <= isSTORE OR isPUSH OR isCALL;
	-- if MemWriteEn, [MemAddr] ← MemNext
	MemNext <=
		B_val    WHEN isPUSH ELSE -- push the value of B_reg
		Adjacent WHEN isCALL ELSE -- push the RETURN address
		A_val;                    -- store the value of Instr1Reg
	-------------------------------------------------------------------
	-- Program flow control
	-------------------------------------------------------------------
	-- Instructions have a variable Size of 1 or 2 words. "Adjacent", the
	-- address of the following instruction, is set to PC+Size by using an
	-- 8-bit full adder (PC_Incrementor). If a jump is occurring, the PC is set
	-- to either the Instr2 argument of the jump/call instruction, or the
	-- popped memory data from the stack (in case of RETURN).
	-- The program counter is stored in an 8-bit D flip-flop.
	Size <=
		x"01" WHEN isHLT OR isNOP OR isRETURN OR isSHIFT OR isPUSH OR isPOP ELSE
		x"02";
	PC_Incrementor : ENTITY work.FA8 PORT MAP(PC, Size, '0', Adjacent);
	Jumping <=
		isJMP OR isCALL OR isRETURN OR
		(isJC AND Carry) OR (isJNC AND NOT Carry) OR
		(isJZ AND Zero) OR (isJNZ AND NOT Zero) OR
		(isJS AND Sign) OR (isJNS AND NOT Sign) OR
		(isJV AND Overflow) OR (isJNV AND NOT Overflow);
	PCnext <=
		x"00"    WHEN Reset         ELSE
		PC       WHEN isHLT OR Halt ELSE -- HLT works on the current cycle
		Adjacent WHEN NOT Jumping   ELSE
		Data     WHEN isRETURN      ELSE
		Instr2;
	ProgramCounter : ENTITY work.DFF8 PORT MAP(CLK, PCnext, PC);
END;