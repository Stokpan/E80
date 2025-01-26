-----------------------------------------------------------------------
-- E80 CPU
-- Fetches instruction and data from the RAM and the DIP input.
-- Decodes the instruction to get the control signals, addresses and values.
-- Reads registers from the Register Array.
-- Assigns input values to the ALU.
-- Writes the result of the ALU to the registers and the RAM.
-- Advances to the next instruction.
-----------------------------------------------------------------------

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY CPU IS PORT (
	CLK        : IN STD_LOGIC;
	Reset      : IN STD_LOGIC;
	Instr1     : IN WORD;       -- [PC] first part of current instruction
	Instr2     : IN WORD;       -- [PC+1] 2nd part (ignored for 1-word instr.)
	Data       : IN WORD;       -- [MemAddr] if MemAddr<0xFF, else DIP input
	PC         : BUFFER WORD;   -- current instruction address
	MemAddr    : OUT WORD;      -- memory address to be read or written
	MemWriteEn : OUT STD_LOGIC; -- write enable for [MemAddr]
	MemNext    : OUT WORD;      -- next cycle value of [MemAddr]
	R          : OUT WORDx8);   -- FPGA LED output
END;
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
	-- op2isReg discerns between types 4 and 5 to check if the flexible 2nd
	-- operand is a register (op2isReg=1) or an immediate/direct (op2isReg=0)
	-- eg. in ADD R0,R1 op2isReg=1 whereas ADD R0,10 op2isReg=0.
	ALIAS op2isReg   : STD_LOGIC IS Instr1(3);
	ALIAS Instr1Reg  : REG_ADDR IS Instr1(2 DOWNTO 0);
	ALIAS Instr2Reg1 : REG_ADDR IS Instr2(6 DOWNTO 4);
	ALIAS Instr2Reg2 : REG_ADDR IS Instr2(2 DOWNTO 0);
	-- Instruction Decoder output
	SIGNAL isHLT, isNOP, isJMP, isJMPr, isJC, isJNC, isJZ, isJNZ, isJV, isJNV,
		isJS, isJNS, isCALL, isRETURN, isSTORE, isSTOREr, isLOAD, isLOADr,
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
	ALIAS Halt     : STD_LOGIC IS Flags(3);
	-- ALU signals
	SIGNAL ALUop : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL ALUinB : WORD;
	SIGNAL FlagsOut : WORD;
	ATTRIBUTE syn_keep : BOOLEAN; -- FPGA fix, see MemAddr assignment
	ATTRIBUTE syn_keep OF ALUinB : SIGNAL IS TRUE;
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
	-- By default, all instructions are assumed to be types 5 and 6 with
	-- opcodes matching their required ALUop. The following instructions are
	-- either exceptions or need custom handling.
	isHLT    <= match(Instr1,"00000000");
	isNOP    <= match(Instr1,"00000001");
	isJMP    <= match(Instr1,"0000001-");
	isJMPr   <= match(Instr1,"00000011");   -- JMP reg
	isJC     <= match(Instr1,"00000100");
	isJNC    <= match(Instr1,"00000101");
	isJZ     <= match(Instr1,"00000110");
	isJNZ    <= match(Instr1,"00000111");
	isJS     <= match(Instr1,"00001010");
	isJNS    <= match(Instr1,"00001011");
	isJV     <= match(Instr1,"00001100");
	isJNV    <= match(Instr1,"00001101");
	isCALL   <= match(Instr1,"00001110");
	isRETURN <= match(Instr1,"00001111");
	isSTORE  <= match(Instr1,"1000----");
	isSTOREr <= match(Instr1,"10001000");   -- STORE reg1,reg2
	isLOAD   <= match(Instr1,"1001----");
	isLOADr  <= match(Instr1,"10011000");   -- LOAD reg1,reg2
	isSHIFT  <= match(Instr1,"10100---") OR -- RSHIFT
	            match(Instr1,"11000---");   -- LSHIFT
	isPUSH   <= match(Instr1,"11100---");
	isPOP    <= match(Instr1,"11110---");
	isStack  <= isPUSH OR isCALL OR isPOP OR isRETURN;
	-------------------------------------------------------------------
	-- Arithmetic Logical Unit
	-------------------------------------------------------------------
	-- All instructions start with their ALU opcode, except for CALL & RETURN.
	-- ALUinA/ALUout are assigned to A_reg's current A_val and A_next values.
	-- ALUinB is assigned to either an immediate value (Instr2), a register
	-- value (B_val), or data from the RAM or DIP input (Data).
	ALU : ENTITY work.ALU PORT MAP(
		ALUop,
		A_val,   -- ALUinA
		ALUinB,
		Flags,
		A_next,  -- ALUout, results are accumulated on A_reg
		FlagsOut);
	ALUop <=
		"1110" WHEN isCALL   ELSE -- push PC
		"1111" WHEN isRETURN ELSE -- pop PC
		Instr1(7 DOWNTO 4);
	ALUinB <=
		Data    WHEN isLOAD   ELSE -- RAM or DIP input
		B_val   WHEN op2isReg ELSE
		Instr2;
	-------------------------------------------------------------------
	-- Registers
	-------------------------------------------------------------------
	RegisterFile : ENTITY work.RegisterFile PORT MAP(
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
		Instr2Reg1   WHEN op2isReg ELSE  -- type 4
		Instr1Reg;                       -- type 2 or 5
	-- B_reg's value is used in ALUinB, or as a memory address for LOAD/STORE.
	-- B_reg is almost exclusively set to Instr2Reg2, except for PUSH where
	-- A_reg is assigned to the stack pointer and Instr1Reg's value needs to
	-- be read through B_reg / B_val to be stored in the RAM.
	B_reg <= Instr1Reg WHEN isPUSH ELSE Instr2Reg2;
	-- W_reg is the write register. It's almost exclusively set to the
	-- flags register, except for POP which writes on its Instr1Reg.
	W_reg <= Instr1Reg WHEN isPOP ELSE FlagsRegister;
	W_next <=
		Data                WHEN isPOP ELSE
		Flags OR "00001000" WHEN isHLT ELSE -- HLT sets the Halt flag
		FlagsOut;                           -- ALU flags output
	-------------------------------------------------------------------
	-- Memory access
	-------------------------------------------------------------------
	-- All operations that use memory addressing, specified with [...]
	-- brackets in the ISA, assign MemAddr to the address in the bracket.
	-- Assigning MemAddr to A_next (ALUout) causes conditional loop warnings
	-- in Quartus & Gowin. That's due to their optimizations which cause an
	-- "A_next → MemAddr → Data → ALUinB → A_next" loop; they somehow make
	-- ALUinB depend on Data for Stack operations. By replacing A_next with
	-- STD_LOGIC_VECTOR(UNSIGNED(A_val)-1) the problem is "fixed" but this
	-- adds the undesirable dependency on numeric_std. Thankfully, Gowin
	-- supports the syn_keep attribute to disable these optimizations, thus
	-- eliminating the problem.
	MemAddr <=
		B_val   WHEN isSTOREr OR isLOADr ELSE -- Instr2Reg2
		A_val   WHEN isPOP OR isRETURN   ELSE -- SP before increase
		A_next  WHEN isPUSH OR isCALL    ELSE -- SP after decrease
		Instr2;                               -- STORE / LOAD direct
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
	-- Instructions have a variable Size of 1 or 2 words.
	-- Adjacent, the address of the following instruction, is set to PC+Size
	-- by using an 8-bit full adder (PC_Adder).
	-- If a jump is occurring, Adjacent is ignored and the PC is set to the
	-- target address which is either the Instr2 argument of the jump/call
	-- instruction, or memory data from the stack (in case of RETURN).
	-- The program counter is stored in an 8-bit D flip-flop.
	Size <=
		x"01" WHEN isHLT OR isNOP OR isRETURN OR isSHIFT OR isPUSH OR isPOP ELSE
		x"02";
	PC_Adder : ENTITY work.FA8 PORT MAP(PC, Size, '0', Adjacent);
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
		B_val    WHEN isJMPr        ELSE
		Instr2;
	PC_DFF : ENTITY work.DFF8 PORT MAP(CLK, PCnext, PC);
END;