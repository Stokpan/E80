-----------------------------------------------------------------------
-- E80 Arithmetic Logic Unit
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Performs addition, subtraction, rotation, and logical operations.
-- The calculated result and/or flags is discarded in some operations.
-----------------------------------------------------------------------
LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY ALU IS PORT (
	ALUop    : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
	ALUinA   : IN WORD;
	ALUinB   : IN WORD;
	FlagsIn  : IN WORD; -- Carry, Zero, Sign, Overflow, Halt
	ALUout   : OUT WORD;
	FlagsOut : OUT WORD);
END;
ARCHITECTURE a1 OF ALU IS
	ALIAS A : WORD IS ALUinA;
	SIGNAL B : WORD; -- ALUinB or 1 for INR/DCR
	-- ALU Decoder output
	SIGNAL isBypass, isAssign, isADD, isSUB, isROR, isAND, isOR, isXOR,
		isRSHIFT, isCMP, isLSHIFT, isBIT, isDCR, isINR,
		FullFlags, DiscardFlags, DiscardResult : STD_LOGIC;
	-- Barrel shifter result
	SIGNAL Rotated : WORD;
	-- Adder / subtractor output
	SIGNAL Sum_C, Sum_V : STD_LOGIC;
	SIGNAL Sum : WORD;
    -- Result signals (assigned to ALUout/FlagsOut or ignored)
	SIGNAL Result : WORD;
	SIGNAL C, Z, S, V : STD_LOGIC;
BEGIN
	-----------------------------------+------------------------------+------+
	-- ALUop Decoder                   | ALUout                       | CZSV |
	-----------------------------------+------------------------------+------+
	isBypass <= match(ALUop,"-000"); --| A (J*, STORE, CALL, etc)     |      |
	isAssign <= match(ALUop,"-001"); --| B (MOV, LOAD)                |  **  |
	isADD    <= match(ALUop,"0010"); --| A + B                        | **** | 
	isSUB    <= match(ALUop,"-011"); --| A - B (includes CMP)         | **** | 
	isAND    <= match(ALUop,"-100"); --| A AND B (includes BIT)       |  **  |
	isOR     <= match(ALUop,"0101"); --| A OR B                       |  **  |
	isXOR    <= match(ALUop,"0110"); --| A XOR B                      |  **  |
	isROR    <= match(ALUop,"0111"); --| A rotated by B mod 8 bits    |  **  |         
	isLSHIFT <= match(ALUop,"1010"); --| A << 1, C ← A(7), V ← S flip | **** | 
	isCMP    <= match(ALUop,"1011"); --| SUB, discard result          | **** |
	isBIT    <= match(ALUop,"1100"); --| AND, discard result          |  **  |
	isRSHIFT <= match(ALUop,"1101"); --| A >> 1, C ← A(0), V ← S flip | **** | 
	isDCR    <= match(ALUop,"1110"); --| A - 1 (PUSH, CALL)           |      | 
	isINR    <= match(ALUop,"1111"); --| A + 1 (POP, RETURN)          |      | 
	FullFlags     <= isADD OR isSUB OR isRSHIFT OR isLSHIFT;
	DiscardFlags  <= isBypass OR isINR OR isDCR;
	DiscardResult <= isBypass OR isCMP OR isBIT;
	-------------------------------------------------------------------
	-- Full Adder / Subtractor
	-------------------------------------------------------------------
	B <= x"01" WHEN isDCR OR isINR ELSE ALUinB;
	ALU_Adder : ENTITY work.FA8 PORT MAP(
		A,
		B,
		isSUB OR isDCR, -- 1 = subtraction (includes CMP)
		Sum,
		Sum_C,
		Sum_V);
	-------------------------------------------------------------------
	-- Barrel shifter
	-------------------------------------------------------------------
	-- Rotation is determined by the 3 LSBs of operand B.
	-- It had to be performed manually because Quartus Lite
	-- doesn't support VHDL 2008 SRL/SLL/ROR/ROL operators.
	WITH B(2 DOWNTO 0) SELECT Rotated <=
		A(0 DOWNTO 0) & A(7 DOWNTO 1) WHEN "001",  -- right 1, left 7
		A(1 DOWNTO 0) & A(7 DOWNTO 2) WHEN "010",  -- right 2, left 6
		A(2 DOWNTO 0) & A(7 DOWNTO 3) WHEN "011",  -- right 3, left 5
		A(3 DOWNTO 0) & A(7 DOWNTO 4) WHEN "100",  -- right 4, left 4
		A(4 DOWNTO 0) & A(7 DOWNTO 5) WHEN "101",  -- right 5, left 3
		A(5 DOWNTO 0) & A(7 DOWNTO 6) WHEN "110",  -- right 6, left 2
		A(6 DOWNTO 0) & A(7 DOWNTO 7) WHEN "111",  -- right 7, left 1
		A                             WHEN OTHERS; -- no rotation
	-------------------------------------------------------------------
	-- Result & Flags
	-------------------------------------------------------------------
	-- Result needs to be calculated, even if discarded later, for flags-only
	-- operations. For shift operations, the carry bit holds the shifted
	-- bit while the overflow bit is set if the sign bit was flipped.
	Result <=
		B                   WHEN isAssign       ELSE
		Rotated             WHEN isROR          ELSE
		A AND B             WHEN isAND          ELSE
		A OR B              WHEN isOR           ELSE
		A XOR B             WHEN isXOR          ELSE
		"0" & A(7 DOWNTO 1) WHEN isRSHIFT       ELSE
		A(6 DOWNTO 0) & "0" WHEN isLSHIFT       ELSE
		Sum;
	C <= A(0) WHEN isRSHIFT ELSE A(7) WHEN isLSHIFT ELSE Sum_C;
	Z <= match(Result,"00000000");
	S <= Result(7);
	V <= A(7) XOR S WHEN isRSHIFT OR isLSHIFT ELSE Sum_V;
	-------------------------------------------------------------------
	-- Final output
	-------------------------------------------------------------------
	FlagsOut <=
		FlagsIn                                   WHEN DiscardFlags ELSE
		C & Z & S & V & FlagsIn(3 DOWNTO 0)       WHEN FullFlags    ELSE
		FlagsIn(7) & Z & S & FlagsIn(4 DOWNTO 0);
	ALUout <= A WHEN DiscardResult ELSE Result;
END;