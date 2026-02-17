-----------------------------------------------------------------------
-- E80 Board Interface, Clock Generator, and MAX7219 driver
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Interfaces the E80 Computer system with the FPGA board
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Clock Generator for the E80 Computer FPGA Board Interface
-- Requires a 2 MHz minimum clock input with its frequency supplied by
-- the board-specific mini-library (Board.vhd) in the Board subfolders.
-- Converts the onboard oscillator input to 8 clock speeds.
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL, ieee.numeric_std.ALL;
ENTITY ClockGenerator IS
	GENERIC (BoardCLK_MHz : NATURAL := 50);
	PORT (
		BoardCLK : IN STD_LOGIC;
		GenCLK   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END;
ARCHITECTURE a1 OF ClockGenerator IS
	SIGNAL Count500ns : UNSIGNED(23 DOWNTO 1) := (OTHERS => '0');
BEGIN
	PROCESS (BoardCLK)
		-- Divisor = BoardCLK_MHz / 2 = frequency * 10^(-6) / 2
		-- Period = 1 sec / frequency
		CONSTANT Divisor : NATURAL := BoardCLK_MHz / 2;
		VARIABLE Period : NATURAL RANGE 1 TO Divisor := 1;
	BEGIN
		IF RISING_EDGE(BoardCLK) THEN
			IF Period < Divisor THEN
				Period := Period + 1;
			ELSE
				-- runs every Period * Divisor = 1 sec * 10(-6) / 2 = 500 ns
				Period := 1;
				Count500ns <= Count500ns + 1;
			END IF;
		END IF;
	END PROCESS;
	-- Each x bit of Count500ns provides a 2 MHz / 2^x frequency. They are used
	-- to provide various frequencies for pause, execution from 0.24 Hz up to
	-- 2 KHz, and a 1 MHz clock to run the board interface.
	-- GenCLK(0) is set to a constant to allow pausing, and specifically high
	-- to allow for user-controlled rising edges for step execution when the
	-- Pause button gates the CPU clock to low.
	GenCLK(0) <= '1';            -- 0 Hz
	GenCLK(1) <= Count500ns(23); -- 2 MHz / 2^23 ~ 0.24 Hz
	GenCLK(2) <= Count500ns(21); -- 2 MHz / 2^21 ~ 1 Hz
	GenCLK(3) <= Count500ns(20); -- 2 MHz / 2^20 ~ 2 Hz
	GenCLK(4) <= Count500ns(19); -- 2 MHz / 2^19 ~ 4 Hz
	GenCLK(5) <= Count500ns(17); -- 2 MHz / 2^17 ~ 15 Hz
	GenCLK(6) <= Count500ns(9);  -- 2 MHz / 2^9 ~ 2 KHz
	GenCLK(7) <= Count500ns(1);  -- 2 MHz / 2 = 1 MHz
END;

-----------------------------------------------------------------------
-- Simple MAX7219 driver for 4 daisy‑chained 8x8 LED matrices
-- Comprises two main states: data preparation, and bit shifting.
-- Once the data are prepared, CS is pulled low and the bits are shifted
-- serially via DIN on CLK rising edges; once finished, CS is raised and
-- latches all four shift registers.
-- For table references, see the MAX7219 datasheet.
-----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL, ieee.numeric_std.ALL, work.support.ALL;

ENTITY MAX7219 IS PORT (
	CLK1MHz : IN  STD_LOGIC;
	Reset	: IN  STD_LOGIC;
	Matrix1 : IN  WORDx8;    -- leftmost
	Matrix2 : IN  WORDx8;
	Matrix3 : IN  WORDx8;
	Matrix4 : IN  WORDx8;
	DIN		: OUT STD_LOGIC; -- shift register data, loaded on rising CLK edge
	CS		: OUT STD_LOGIC; -- latches the shift register on its rising edge
	CLK		: OUT STD_LOGIC	 -- serial clock
); END;

ARCHITECTURE a1 OF MAX7219 IS
BEGIN
	PROCESS(CLK1MHz)
		-- ShiftRegister contains a packet of 64 bits (16 for each matrix) which
		-- either control the matrix (eg. intensity) or the LEDs in one row.
		SUBTYPE SRpacket IS STD_LOGIC_VECTOR(63 DOWNTO 0);
		VARIABLE ShiftRegister : SRpacket;
		VARIABLE Shifted : NATURAL RANGE 0 TO 64; -- number of shifted bits
		-- Initialization packets (see specification tables 2-10) ordered
		-- with a bit of trial and error until I got a reliable initialization
		-- in multiple reflashes
		TYPE InitPackets IS ARRAY (0 TO 4) OF SRpacket;
		CONSTANT InitPacket : InitPackets := (
			0 => x"-F-1-F-1-F-1-F-1", -- display test: enabled
			1 => x"-C-1-C-1-C-1-C-1", -- shutdown: disabled (normal operation)
			2 => x"-F-0-F-0-F-0-F-0", -- display test: disabled
			3 => x"-A-F-A-F-A-F-A-F", -- intensity: max
			4 => x"-B-7-B-7-B-7-B-7"  -- scan-limit: max, allow all LEDs
		);
		VARIABLE InitStage : NATURAL RANGE 0 TO InitPacket'length := 0;
		-- Physical LED rows map to "digits" per table 2. The module is assumed
		-- to be read with pin inputs on the left, so physical rows are in
		-- reverse order which translates to RowHexCode = 8 - Row.
		VARIABLE Row : NATURAL RANGE 0 TO 8;
		VARIABLE RowHexCode : STD_LOGIC_VECTOR(3 DOWNTO 0);
	BEGIN
		IF RISING_EDGE(CLK1MHz) THEN
			IF Reset = '1' THEN
				InitStage := 0;
			-- ----------------------------------------------------------------
			-- Initialization and shift register preparation state
			-- ----------------------------------------------------------------
			-- Triggered after latching previous packet on CS rising edge
			ELSIF CS = '1' OR InitStage = 0 THEN
				IF InitStage < InitPacket'length THEN
					IF InitStage = 0 THEN
						-- Initialize the serial clock to high to allow for
						-- a full first period at the Shifting state.
						CLK <= '1';
						Row := 0;
						Shifted := 0;
					END IF;
					ShiftRegister := InitPacket(InitStage);
					InitStage := InitStage + 1;
				ELSE
					IF Row = 8 THEN
						Row := 0;
					END IF;
					RowHexCode := STD_LOGIC_VECTOR(TO_UNSIGNED(8-Row,4));
					-- the MSB will be shifted out first into the 4th matrix
					ShiftRegister(63 DOWNTO 56) := x"-" & RowHexCode;
					ShiftRegister(55 DOWNTO 48) := reverse_vector(Matrix4(Row));
					ShiftRegister(47 DOWNTO 40) := x"-" & RowHexCode;
					ShiftRegister(39 DOWNTO 32) := reverse_vector(Matrix3(Row));
					ShiftRegister(31 DOWNTO 24) := x"-" & RowHexCode;
					ShiftRegister(23 DOWNTO 16) := reverse_vector(Matrix2(Row));
					ShiftRegister(15 DOWNTO 8)	:= x"-" & RowHexCode;
					ShiftRegister(7 DOWNTO 0)   := reverse_vector(Matrix1(Row));
					Row := Row + 1;
				END IF;
				CS <= '0'; -- proceed to the Shifting state
			-- ----------------------------------------------------------------
			-- Shifting state
			-- ----------------------------------------------------------------
			ELSE
				IF Shifted < 64 THEN -- more bits to shift
					IF CLK = '1' THEN
						-- shift the new bit before the next rising edge
						DIN <= ShiftRegister(63);
						CLK <= '0';
					ELSE
						-- increase the counter in the low phase, otherwise
						-- there won't be a rising edge for the last bit
						ShiftRegister := ShiftRegister(62 DOWNTO 0) & '0';
						Shifted := Shifted + 1;
						CLK <= '1'; -- rising edge, send DIN to register
					END IF;
				ELSE 
					-- All bits have been shifted; latch them to the MAX7219
					-- shift registers, and return to the preparation state
					CS <= '1';
					Shifted := 0;
				END IF;
			END IF;
		END IF;
	END PROCESS;
END;

-----------------------------------------------------------------------
-- E80 Board Interface
-- Generates a GenCLK vector with up to 1MHz frequencies from the BoardCLK.
-- Runs the E80 CPU with a DIP input and variable clock speeds from 0 to 2KHz.
-- Runs the main interface process on a 1MHz clock to:
-- * Debounce reset, pause, and speed selection signals
-- * Provide a stable initialization/reset with hysteresis
-- * Control the CPU clock frequency
-- * Stop the clock to allow for stepped execution via the pause button
-- * Output the display signals to four MAX7219 8x8 LED matrices.
-----------------------------------------------------------------------

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.board.ALL, work.support.ALL, work.firmware.ALL;
ENTITY Interface IS PORT (
	BoardCLK    : IN STD_LOGIC;  -- board clock (frequency in Board.vhd)
	ResetButton : IN STD_LOGIC;  -- resets PC, SP, & uploads the firmware
	SetButton   : IN STD_LOGIC;  -- raises one clock edge and pauses
	Right       : IN STD_LOGIC;  -- increases CLK frequency up to 1 MHz
	Left        : IN STD_LOGIC;  -- decreases CLK frequency down to 0 (pause)
	DIPinput    : IN WORD;       -- 8-pin DIP switch input
	MAX7219DIN	: OUT STD_LOGIC; -- MAX7219 4x8x8 LED matrix DIN
	MAX7219CS	: OUT STD_LOGIC; -- MAX7219 4x8x8 LED matrix CS
	MAX7219CLK  : OUT STD_LOGIC  -- MAX7219 4x8x8 LED matrix Serial CLK
); END;
ARCHITECTURE a1 OF Interface IS
	SIGNAL Reset  : STD_LOGIC := '0'; -- debounced ResetButton
	SIGNAL Pause    : STD_LOGIC := '0'; -- debounced SetButton
	SIGNAL GenCLK : STD_LOGIC_VECTOR(7 DOWNTO 0); -- see ClockGenerator
	SIGNAL Speed  : NATURAL RANGE 0 TO 6 := InitSpeed; -- GenCLK index
	ALIAS CLK1MHz : STD_LOGIC IS GenCLK(7); -- for board interface only
	SIGNAL CLK    : STD_LOGIC; -- CPU clock speeds range from 0 to 2 KHz
	-- Display signals
	SIGNAL PC       : WORD;
	SIGNAL R        : WORDx8;
	SIGNAL Instr1   : WORD;
	SIGNAL Instr2   : WORD;
	SIGNAL RAMdisp1 : WORDx8;
	SIGNAL RAMdisp2 : WORDx8;
	SIGNAL Matrix1  : WORDx8;
	SIGNAL Matrix2  : WORDx8;
	SIGNAL Matrix3  : WORDx8;
	SIGNAL Matrix4  : WORDx8;
BEGIN
	-------------------------------------------------------------------
	-- 1MHz clock generator
	-------------------------------------------------------------------
	ClockGenerator: ENTITY work.ClockGenerator
		GENERIC MAP (BoardCLK_MHz) PORT MAP (BoardCLK, GenCLK);
	-------------------------------------------------------------------
	-- E80 Computer instantiation
	-------------------------------------------------------------------
	Computer: ENTITY work.Computer PORT MAP(
		CLK,       -- Provided by the Clock, Reset and Pause process
		Reset,
		DIPinput,  -- 8-pin DIP switch user input, shown on Matrix4
		PC,        -- Program Counter, shown on Matrix1
		R,         -- Register file, shown on Matrix2
		Instr1,    -- Instruction word Part 1, shown on Matrix1
		Instr2,    -- Instruction word Part 2, shown on Matrix1
		RAMdisp1,  -- RAM words on address 200-207, shown on Matrix3
		RAMdisp2); -- RAM words on address 248-254, shown on Matrix4
	-----------------------------------------------------------------------
	-- Clock, Reset and Pause process
	-----------------------------------------------------------------------
	-- When a reset is registered, the CPU clock switches to the clock of the
	-- button handling process to ensure the reset applies during a rising
	-- edge in the E80 Computer/CPU.
	-- The clock is gated low while pause is pressed. Combined with GenCLK(0)=1
	-- (see ClockGenerator), this causes a clock rising edge when releasing
	-- the pause button, allowing for stepped execution when Speed=0.
	PROCESS (CLK1MHz)
		-- Debouncing and repeat rate settings
		CONSTANT Idle : NATURAL := 400000; -- 0.4 sec
		CONSTANT Ready : NATURAL := 401000; -- plus debounce guard
		CONSTANT Finish : NATURAL := 402000; -- plus Reset delay for MAX7219
		CONSTANT MinPause : NATURAL := 100000; -- 0.1 sec
		-- Pause (pause/step execution) and Reset debouncing
		VARIABLE ResetTimer : NATURAL RANGE 0 TO Finish := Ready;
		VARIABLE PauseRelease : NATURAL RANGE 0 TO MinPause := MinPause;
		VARIABLE JoystickPress : NATURAL RANGE 0 TO Ready := 0;
	BEGIN
		IF RISING_EDGE(CLK1MHz) THEN
			IF ResetTimer < Idle THEN
				IF NOT ResetButton THEN
					ResetTimer := ResetTimer + 1;
				END IF;
			ELSIF ResetTimer < Ready THEN
				IF ResetButton THEN
					ResetTimer := ResetTimer + 1;
				ELSE
					ResetTimer := Idle;
				END IF;
			ELSE
				Reset <= '1';
			END IF;
			IF NOT Reset THEN
				CLK <= GenCLK(Speed) AND NOT Pause;
			ELSE
				IF ResetTimer = Ready THEN
					CLK <= '0';
					ResetTimer := ResetTimer + 1;
				ELSIF ResetTimer < Finish THEN
					CLK <= '1';
					ResetTimer := ResetTimer + 1;
				ELSE
					Reset <= '0';
					ResetTimer := 0;
				END IF;
			END IF;
			IF ResetButton THEN
				-- don't allow combined buttons
			ELSIF PauseRelease < MinPause THEN
				Pause <= '1';
				PauseRelease := PauseRelease + 1;
			ELSIF SetButton THEN
				PauseRelease := 0;
			ELSE
				Pause <= '0';
			END IF;
			IF ResetButton OR SetButton THEN
				-- don't allow combined buttons
			ELSIF JoystickPress < Idle THEN
				JoystickPress := JoystickPress + 1;
			ELSIF Right THEN
				IF JoystickPress < Ready THEN
					JoystickPress := JoystickPress + 1;
				ELSIF Speed < 6 THEN
					Speed <= Speed + 1;
					JoystickPress := 0;
				END IF;
			ELSIF Left THEN
				IF JoystickPress < Ready THEN
					JoystickPress := JoystickPress + 1;
				ELSIF Speed > 0 THEN
					Speed <= Speed - 1;
					JoystickPress := 0;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------
	-- LED display
	-------------------------------------------------------------------
	MatrixDriver: ENTITY work.MAX7219 PORT MAP (
		CLK1MHz,
		Reset,
		Matrix1,
		Matrix2,
		Matrix3,
		Matrix4,
		MAX7219DIN,
		MAX7219CS,
		MAX7219CLK);
	-- Matrix1
	-- Row 1: Speed level (slider on bits 7 to 1), Clock (bit 0)
	-- Row 2: Program Counter
	-- Row 3: Instr1 (Instruction Word part 1)
	-- Row 4: Instr2 (Instruction Word part 2)
	-- Rows 5-7: blank
	-- Row 8: Carry, Zero, Sign, Overflow, Halt, blank, blank, blank
	WITH Speed SELECT Matrix1(0)(7 DOWNTO 1) <=
		"1000000" WHEN 0, "0100000" WHEN 1, "0010000" WHEN 2,
		"0001000" WHEN 3, "0000100" WHEN 4, "0000010" WHEN 5,
		"0000001" WHEN 6;
	Matrix1(0)(0) <= CLK;
	Matrix1(1) <= x"00";
	Matrix1(2) <= PC;
	Matrix1(3) <= Instr1;
	Matrix1(4) <= Instr2;
	Matrix1(5) <= x"00";
	Matrix1(6)(7 DOWNTO 3) <= R(6)(7 DOWNTO 3);
	Matrix1(6)(2 DOWNTO 0) <= "000";
	Matrix1(7) <= x"00";
	-- Matrix2
	-- Rows 1-6: General Purpose Registers R0-R5
	-- Row 7: blank
	-- Row 8: Stack Pointer (R7)
	Matrix2(0 TO 5) <= R(0 TO 5);
	Matrix2(6) <= x"00";
	Matrix2(7) <= R(7);
	-- Matrix3
	-- Rows 1-8: RAM block 200-207
	Matrix3 <= RAMdisp1;
	-- Matrix4
	-- Rows 1-7: RAM block 248-254
	-- Row 8: DIP switch input
	Matrix4(0 TO 6) <= RAMdisp2(0 TO 6);
	Matrix4(7) <= DIPinput;
END;