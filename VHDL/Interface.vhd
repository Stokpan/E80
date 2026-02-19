-----------------------------------------------------------------------
-- E80 Clock Generator, MAX7219x4 driver, and Board Interface
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Interfaces the E80 Computer with I/O hardware components.
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- The Clock Generator converts the input clock (BoardCLK) to an array (GenCLK)
-- of eight clocks between 0 Hz and 1 MHz. It requires the BoardCLK's frequency 
-- (BoardCLK_MHz) from the \Boards\*\Board.vhd file.
-----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL, ieee.numeric_std.ALL, work.board.ALL;
ENTITY ClockGenerator IS PORT (
	BoardCLK : IN STD_LOGIC;
	GenCLK   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
); END;
ARCHITECTURE a1 OF ClockGenerator IS
	SIGNAL Count500ns : UNSIGNED(23 DOWNTO 1) := (OTHERS => '0');
BEGIN
	PROCESS (BoardCLK)
		-- Divisor = BoardCLK_MHz / 2 = hardware_frequency * 10^(-6) / 2
		-- Period = 1 sec / hardware_frequency
		CONSTANT Divisor : NATURAL := BoardCLK_MHz / 2;
		VARIABLE Period : NATURAL RANGE 1 TO Divisor := 1;
	BEGIN
		IF RISING_EDGE(BoardCLK) THEN
			IF Period < Divisor THEN
				Period := Period + 1;
			ELSE
				-- runs every Period * Divisor = 500 ns
				Period := 1;
				Count500ns <= Count500ns + 1;
			END IF;
		END IF;
	END PROCESS;
	GenCLK(0) <= '1';            -- 0 Hz with clock set to high
	GenCLK(1) <= Count500ns(23); -- 2 MHz / 2^23 ~ 0.24 Hz
	GenCLK(2) <= Count500ns(21); -- 2 MHz / 2^21 ~ 1 Hz
	GenCLK(3) <= Count500ns(20); -- 2 MHz / 2^20 ~ 2 Hz
	GenCLK(4) <= Count500ns(19); -- 2 MHz / 2^19 ~ 4 Hz
	GenCLK(5) <= Count500ns(17); -- 2 MHz / 2^17 ~ 15 Hz
	GenCLK(6) <= Count500ns(9);  -- 2 MHz / 2^9 ~ 2 KHz
	GenCLK(7) <= Count500ns(1);  -- 2 MHz / 2 = 1 MHz
END;

-----------------------------------------------------------------------
-- Simple MAX7219 driver for 4 daisy‑chained 8x8 LED matrices.
-- Comprises two main states: data preparation, and bit shifting.
-- Once the data are prepared, CS is pulled low and the bits are shifted
-- serially via DIN on CLK rising edges; once finished, CS is raised to
-- latch the four MAX7219 shift registers and return to data preparation.
-- For table references, see the MAX7219 datasheet.
-----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL;

ENTITY MAX7219x4 IS PORT (
	MainCLK : IN  STD_LOGIC; -- main process clock
	Reset	: IN  STD_LOGIC;
	Matrix1 : IN  WORDx8;    -- leftmost, gets the last shifted data
	Matrix2 : IN  WORDx8;
	Matrix3 : IN  WORDx8;
	Matrix4 : IN  WORDx8;    -- rightmost, gets the first shifted data
	DIN		: OUT STD_LOGIC; -- shift register data, loaded on rising CLK edge
	CS		: OUT STD_LOGIC; -- latches the shift register on its rising edge
	CLK		: OUT STD_LOGIC	 -- serial clock output to MAX7219
); END;

ARCHITECTURE a1 OF MAX7219x4 IS
BEGIN
	PROCESS(MainCLK)
		-- ShiftRegister contains a packet of 16 bits for each matrix. As seen
		-- on Tables 2-10, bits D15-D12 are don't cares, D11-D8 define control
		-- and D7-D0 are data. The module is assumed with its input pins on the
		-- left, so the the first packet is shifted on matrix 4 (the rightmost).
		SUBTYPE SRpacket IS STD_LOGIC_VECTOR(63 DOWNTO 0);
		VARIABLE ShiftRegister : SRpacket;
		VARIABLE Shifted : NATURAL RANGE 0 TO 63; -- number of shifted bits
		-- Initialization packets (see specification tables 2-10) were set
		-- to ensure a reliable startup in repeated board reflashes.
		TYPE InitPackets IS ARRAY (NATURAL RANGE <>) OF SRpacket;
		CONSTANT InitPacket : InitPackets := (
			0 => x"-F-1-F-1-F-1-F-1", -- display test: enabled
			1 => x"-C-1-C-1-C-1-C-1", -- shutdown: disabled (normal operation)
			2 => x"-F-0-F-0-F-0-F-0", -- display test: disabled
			3 => x"-A-F-A-F-A-F-A-F", -- intensity: max
			4 => x"-B-7-B-7-B-7-B-7"  -- scan-limit: max, allow all LEDs
		);
		VARIABLE InitState : NATURAL RANGE 0 TO InitPacket'length := 0;
		VARIABLE Row : NATURAL RANGE 0 TO 7; -- physical LED row on all matrices
		VARIABLE RowAddress : STD_LOGIC_VECTOR(7 DOWNTO 0); -- D15-D8 on Table 2
	BEGIN
		IF RISING_EDGE(MainCLK) THEN
			IF Reset = '1' THEN
				InitState := 0;
			-------------------------------------------------------------------
			-- Data preparation & initialization state
			-------------------------------------------------------------------
			ELSIF CS = '1' OR InitState = 0 THEN
				-- CS='1' ⇒ Previous packet was latched
				IF InitState < InitPacket'length THEN
					-- Prepare initialization data
					IF InitState = 0 THEN
						-- Initialize the serial clock to high to allow for
						-- a full first period at the Shifting state.
						CLK <= '1';
						Row := 0;
						Shifted := 0;
					END IF;
					ShiftRegister := InitPacket(InitState);
					InitState := InitState + 1;
				ELSE
					-- Prepare "No-Decode" LED bits (see Tables 2 & 6).
					-- Physical rows map to D11-D8 "digits" per Table 2, but
					-- in reverse order to allow the module to be read with
					-- its input pins on the left.
					-- Physical columns map to D7-D0 LEDs per Table 6 (since
					-- no-decode mode is enabled by default). These are filled
					-- by the input matrix row -- reversed for the same reason.
					WITH Row SELECT RowAddress(3 DOWNTO 0) :=
						x"8" WHEN 0, x"7" WHEN 1, x"6" WHEN 2, x"5" WHEN 3,
						x"4" WHEN 4, x"3" WHEN 5, x"2" WHEN 6, x"1" WHEN 7;
					--RowAddress := STD_LOGIC_VECTOR(TO_UNSIGNED(8-Row,8));
					ShiftRegister :=
						RowAddress & reverse_vector(Matrix4(Row)) &
						RowAddress & reverse_vector(Matrix3(Row)) &
						RowAddress & reverse_vector(Matrix2(Row)) &
						RowAddress & reverse_vector(Matrix1(Row));
					IF Row < 7 THEN
						Row := Row + 1;
					ELSE
						Row := 0;
					END IF;
				END IF;
				CS <= '0'; -- proceed to the Shifting state
			-------------------------------------------------------------------
			-- Shifting state
			-------------------------------------------------------------------
			ELSE
				IF CLK = '1' THEN
					CLK <= '0';
					-- shift the new bit before the next rising edge
					DIN <= ShiftRegister(63);
					ShiftRegister(63 DOWNTO 1) := ShiftRegister(62 DOWNTO 0);
				ELSE
					CLK <= '1'; -- rising edge, send DIN to register
					IF Shifted < 63 THEN
						Shifted := Shifted + 1;
					ELSE
						-- All bits have been shifted, latch them and return
						-- to the preparation state. Also, tCSHmin = 0, so
						-- both CLK & CS can be raised at the same time.
						CS <= '1';
						Shifted := 0;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
END;

-----------------------------------------------------------------------
-- The Interface unit runs the E80 Computer with its CLK provided by the
-- clock generator and its frequency selected by the control buttons. User
-- input is provided by an 8-bit DIP switch. Output is presented on 4 LED
-- matrices (see LED display section). Step execution is provided by
-- controlling the clock with the Pause button. All buttons are debounced.
-----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL, work.firmware.ALL;
ENTITY Interface IS PORT (
	BoardCLK    : IN STD_LOGIC;  -- board clock (frequency in Board.vhd)
	ResetButton : IN STD_LOGIC;  -- resets PC, SP, & uploads the firmware
	PauseButton : IN STD_LOGIC;  -- sets the clock to low while held down
	LeftButton  : IN STD_LOGIC;  -- decreases CLK frequency down to 0 (pause)
	RightButton : IN STD_LOGIC;  -- increases CLK frequency up to 2 KHz
	DIPinput    : IN WORD;       -- 8-pin DIP switch input
	MAX7219DIN	: OUT STD_LOGIC; -- MAX7219 4x8x8 LED matrix DIN
	MAX7219CS	: OUT STD_LOGIC; -- MAX7219 4x8x8 LED matrix CS
	MAX7219CLK  : OUT STD_LOGIC  -- MAX7219 4x8x8 LED matrix Serial CLK
); END;
ARCHITECTURE a1 OF Interface IS
	SIGNAL Reset  : STD_LOGIC := '0'; -- debounced ResetButton
	SIGNAL Pause    : STD_LOGIC := '0'; -- debounced PauseButton
	SIGNAL GenCLK : STD_LOGIC_VECTOR(7 DOWNTO 0); -- see ClockGenerator
	SIGNAL Speed  : NATURAL RANGE 0 TO 6 := InitSpeed; -- GenCLK index
	ALIAS CLK1MHz : STD_LOGIC IS GenCLK(7); -- for board interface only
	SIGNAL CLK    : STD_LOGIC; -- CPU clock speeds range from 0 to 2 KHz
	-- Display signals
	SIGNAL PC       : WORD;
	SIGNAL Instr1   : WORD;
	SIGNAL Instr2   : WORD;
	SIGNAL R        : WORDx8;
	SIGNAL RAMdisp1 : WORDx8;
	SIGNAL RAMdisp2 : WORDx8;
	SIGNAL Matrix1  : WORDx8;
	SIGNAL Matrix2  : WORDx8;
	SIGNAL Matrix3  : WORDx8;
	SIGNAL Matrix4  : WORDx8;
BEGIN
	-------------------------------------------------------------------
	-- Variable frequency clock generator
	-------------------------------------------------------------------
	ClockGenerator: ENTITY work.ClockGenerator PORT MAP (BoardCLK, GenCLK);
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
			ELSIF PauseButton THEN
				PauseRelease := 0;
			ELSE
				Pause <= '0';
			END IF;
			IF ResetButton OR PauseButton THEN
				-- don't allow combined buttons
			ELSIF JoystickPress < Idle THEN
				JoystickPress := JoystickPress + 1;
			ELSIF RightButton THEN
				IF JoystickPress < Ready THEN
					JoystickPress := JoystickPress + 1;
				ELSIF Speed < 6 THEN
					Speed <= Speed + 1;
					JoystickPress := 0;
				END IF;
			ELSIF LeftButton THEN
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
	MatrixDriver: ENTITY work.MAX7219x4 PORT MAP (
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