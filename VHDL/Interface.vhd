-----------------------------------------------------------------------
-- E80 Clock Generator, MAX7219x4 driver, and Board Interface
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Interfaces the E80 Computer with I/O hardware components.
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- The Clock Generator converts the input clock (BoardCLK) to an array
-- (GenCLK) of eight clocks between 0 Hz and 1 MHz. It requires the
-- BoardCLK's frequency (BoardCLK_MHz) from the \Boards\*\Board.vhd file.
-----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL, ieee.numeric_std.ALL, work.board.ALL;
ENTITY ClockGen IS PORT (
	BoardCLK : IN STD_LOGIC;                    -- hardware clock, at least 2Mhz
	GenCLK   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) -- generated clocks array
); END;
ARCHITECTURE a1 OF ClockGen IS
	SIGNAL Count500ns : UNSIGNED(23 DOWNTO 1) := (OTHERS => '0');
BEGIN
	PROCESS (BoardCLK)
		-- Divisor = BoardCLK_MHz / 2 = Board Clock Frequency * 10^(-6) / 2
		-- Period = 1 sec / Board Clock Frequency
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
	GenCLK(6) <= Count500ns(9);  -- 2 MHz / 2^9 ~ 4 KHz
	GenCLK(7) <= Count500ns(1);  -- 2 MHz / 2 = 1 MHz
END;

-----------------------------------------------------------------------
-- Simple MAX7219 driver for 4 daisy‑chained 8x8 LED matrices.
-- Comprises two main states: data preparation, and bit shifting.
-- Once the data are prepared, CS is pulled low and the bits are shifted
-- serially via DIN on CLK rising edges; once finished, CS is raised to
-- latch the four MAX7219 shift registers and return to data preparation.
-- For "table" references, see the MAX7219 datasheet.
-----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY MAX7219x4 IS PORT (
	MainCLK : IN  STD_LOGIC; -- main process clock
	Reset	: IN  STD_LOGIC; -- initializes the controller
	Matrix1 : IN  WORDx8;    -- leftmost 8x8 LEDs, gets the last shifted data
	Matrix2 : IN  WORDx8;
	Matrix3 : IN  WORDx8;
	Matrix4 : IN  WORDx8;    -- rightmost 8x8 LEDs, gets the first shifted data
	DIN		: OUT STD_LOGIC; -- shift register data, loaded on rising CLK edge
	CS		: OUT STD_LOGIC; -- latches the shift register on its rising edge
	CLK		: OUT STD_LOGIC	 -- serial clock output to all MAX7219 modules
); END;
ARCHITECTURE a1 OF MAX7219x4 IS
BEGIN
	PROCESS(MainCLK)
		-- ShiftRegister contains a packet of 16 bits for each matrix. As seen
		-- on tables 2-10, bits D15-D12 are don't cares, D11-D8 define control
		-- and D7-D0 are data. The module is assumed with its input pins on the
		-- left, so the the first packet is shifted on matrix 4 (the rightmost).
		SUBTYPE SRpacket IS STD_LOGIC_VECTOR(63 DOWNTO 0);
		VARIABLE ShiftRegister : SRpacket;
		VARIABLE ShiftedBits : NATURAL RANGE 0 TO SRpacket'LENGTH;
		-- Initialization packets (see specification tables 2-10) were set
		-- to ensure a reliable startup in repeated board reflashes.
		TYPE InitPackets IS ARRAY (NATURAL RANGE <>) OF SRpacket;
		CONSTANT InitPacket : InitPackets := (
			0 => x"-F-1-F-1-F-1-F-1",  -- display test: enabled
			1 => x"-C-1-C-1-C-1-C-1",  -- shutdown: disabled (normal operation)
			2 => x"-F-0-F-0-F-0-F-0",  -- display test: disabled
			3 => x"-A-F-A-F-A-F-A-F",  -- intensity: max
			4 => x"-B-7-B-7-B-7-B-7"); -- scan-limit: max, allow all LEDs
		VARIABLE InitIdx : NATURAL RANGE 0 TO InitPacket'LENGTH := 0;
		-- Physical LED rows map to table 2 "digits" in reverse order
		-- to allow the module to be read with its input pins on the left.
		-- Eg. the first row corresponds to digit 7 with hex code 0xX8.
		CONSTANT RowAddress : WORDx8 := (
			x"-8", x"-7", x"-6", x"-5", x"-4", x"-3", x"-2", x"-1");
		VARIABLE Row : NATURAL RANGE 0 TO 7; -- physical LED row
	BEGIN
		IF RISING_EDGE(MainCLK) THEN
			IF Reset = '1' THEN
				InitIdx := 0; -- trigger initialization
			-------------------------------------------------------------------
			-- Data preparation & initialization state
			-------------------------------------------------------------------
			ELSIF CS = '1' OR InitIdx = 0 THEN
				-- CS='1' ⇒ Previous packet was latched
				IF InitIdx < InitPacket'LENGTH THEN
					-- Prepare initialization data
					IF InitIdx = 0 THEN
						-- Initialize serial clock to high to allow for
						-- a full first period at the Shifting state.
						CLK <= '1';
						Row := 0;
					END IF;
					ShiftRegister := InitPacket(InitIdx);
					InitIdx := InitIdx + 1;
				ELSE
					-- Prepare "No-Decode" LED bits (see tables 2 & 6).
					-- Physical columns map to D7-D0 LEDs per table 6 (no-decode
					-- mode is enabled by default). They are reversed to match
					-- the display's layout.
					ShiftRegister :=
						RowAddress(Row) & reverse_vector(Matrix4(Row)) &
						RowAddress(Row) & reverse_vector(Matrix3(Row)) &
						RowAddress(Row) & reverse_vector(Matrix2(Row)) &
						RowAddress(Row) & reverse_vector(Matrix1(Row));
					IF Row < 7 THEN
						Row := Row + 1;
					ELSE
						Row := 0;
					END IF;
				END IF;
				-- Proceed to the Shifting state
				ShiftedBits := 0;
				CS <= '0';
			-------------------------------------------------------------------
			-- Shifting state
			-------------------------------------------------------------------
			ELSE
				IF CLK = '1' THEN
					CLK <= '0';
					-- shift the new bit before the next rising edge
					DIN <= ShiftRegister(ShiftRegister'HIGH);
					ShiftRegister(ShiftRegister'HIGH DOWNTO 1) :=
						ShiftRegister(ShiftRegister'HIGH - 1 DOWNTO 0);
				ELSE
					CLK <= '1'; -- rising edge, send DIN to register
					ShiftedBits := ShiftedBits + 1;
					IF ShiftedBits = SRpacket'LENGTH THEN
						-- All bits have been shifted, latch them and return
						-- to the preparation state. Also, tCSHmin = 0, so
						-- both CLK & CS can be raised at the same time.
						CS <= '1';
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
	ResetButton : IN STD_LOGIC;  -- resets the PC, SP, Halt, and Program data
	PauseButton : IN STD_LOGIC;  -- sets the clock to low while held down
	LeftButton  : IN STD_LOGIC;  -- decreases CLK frequency down to 0 (pause)
	RightButton : IN STD_LOGIC;  -- increases CLK frequency up to 2 KHz
	DIPinput    : IN WORD;       -- 8-bit DIP switch user input
	MAX7219DIN	: OUT STD_LOGIC; -- MAX7219 4x8x8 LED matrix DIN
	MAX7219CS	: OUT STD_LOGIC; -- MAX7219 4x8x8 LED matrix CS (or LOAD)
	MAX7219CLK  : OUT STD_LOGIC  -- MAX7219 4x8x8 LED matrix Serial CLK
); END;
ARCHITECTURE a1 OF Interface IS
	SIGNAL Reset  : STD_LOGIC := '0'; -- debounced ResetButton
	SIGNAL Pause    : STD_LOGIC := '0'; -- debounced PauseButton
	SIGNAL GenCLK : STD_LOGIC_VECTOR(7 DOWNTO 0); -- see ClockGen
	SIGNAL Speed  : NATURAL RANGE 0 TO 6 := SPEED_directive; -- GenCLK index
	ALIAS CLK1MHz : STD_LOGIC IS GenCLK(7); -- for board interface only
	SIGNAL CLK    : STD_LOGIC; -- CPU clock speeds range from 0 to 2 KHz
	-- Display signals
	SIGNAL PC      : WORD;
	SIGNAL Instr1  : WORD;
	SIGNAL Instr2  : WORD;
	SIGNAL R       : WORDx8;
	SIGNAL RAM     : WORDx256;
	SIGNAL Matrix1 : WORDx8;
	SIGNAL Matrix2 : WORDx8;
	SIGNAL Matrix3 : WORDx8;
	SIGNAL Matrix4 : WORDx8;
BEGIN
	ClockGen_inst: ENTITY work.ClockGen PORT MAP (BoardCLK, GenCLK);
	-----------------------------------------------------------------------
	-- Control buttons process
	-----------------------------------------------------------------------
	PROCESS (CLK1MHz)
		-- Debouncing and repeat rate settings in μs
		CONSTANT DebounceDone : NATURAL := 100;
		CONSTANT ResetDone : NATURAL := DebounceDone + 1000;
		CONSTANT ResetCooldown : NATURAL := ResetDone + 200000; -- +0.2s
		VARIABLE ResetTimer : NATURAL RANGE 0 TO ResetCooldown := DebounceDone;
		CONSTANT MinPause : NATURAL := DebounceDone + 50000; -- +0.05s
		CONSTANT RepeatRate : NATURAL := DebounceDone + 350000; -- +0.35s
		VARIABLE PauseTimer : NATURAL RANGE 0 TO MinPause := 0;
		-- +4 = margin for max possible increment
		VARIABLE SpeedTimer : NATURAL RANGE 0 TO RepeatRate + 4 := 0;
	BEGIN
		IF RISING_EDGE(CLK1MHz) THEN
			-- Reset is a momentary action button, triggers once when pressed
			IF ResetTimer < DebounceDone THEN
				Reset <= '0';
				IF ResetButton THEN
					ResetTimer := ResetTimer + 1;
				ELSE
					ResetTimer := 0;
				END IF;
				-- When pause is pressed, the CPU clock is gated low; this is
				-- useful when Speed is set to 0, in which CLK is gated high,
				-- because releasing pause will cause a rising CLK edge,
				-- allowing for stepped execution.
				CLK <= GenCLK(Speed) AND NOT Pause;
			ELSIF ResetTimer = DebounceDone THEN
				-- Ensure a fresh rising edge with a synchronous reset
				CLK <= '0';
				Reset <= '1';
				ResetTimer := ResetTimer + 1;
			ELSIF ResetTimer < ResetDone THEN
				-- Keep CLK to 1 to ensure a full first cycle after reset.
				-- Otherwise the first cycle might run too fast (and in the
				-- case of Speed=0, the first cycle will run immediately so
				-- the user would go to the 2nd execution cycle).
				CLK <= '1';
				ResetTimer := ResetTimer + 1;
				PauseTimer := 0;
				SpeedTimer := 0;
			ELSIF ResetTimer < ResetCooldown THEN
				Reset <= '0';
				IF NOT ResetButton THEN
					ResetTimer := ResetTimer + 1;
				END IF;
			ELSE
				ResetTimer := 0;
			END IF;
			-- Pause is level sensitive, active continuously while held down
			IF PauseTimer < DebounceDone THEN
				Pause <= '0';
				IF PauseButton THEN
					PauseTimer := PauseTimer + 1;
				ELSE
					PauseTimer := 0;
				END IF;
			ELSIF PauseTimer < MinPause THEN
				Pause <= '1';
				IF NOT PauseButton THEN
					PauseTimer := PauseTimer + 1;
				END IF;
			ELSE
				PauseTimer := 0;
			END IF;
			-- Left/Right buttons are auto repeat
			IF SpeedTimer < DebounceDone THEN
				IF LeftButton XOR RightButton THEN
					SpeedTimer := SpeedTimer + 1;
				ELSE
					SpeedTimer := 0;
				END IF;
			ELSIF SpeedTimer = DebounceDone THEN
				IF RightButton = '1' AND Speed < 6 THEN
					Speed <= Speed + 1;
				ELSIF LeftButton = '1' AND Speed > 0 THEN
					Speed <= Speed - 1;
				END IF;
				SpeedTimer := SpeedTimer + 1;
			ELSIF SpeedTimer < RepeatRate THEN
				SpeedTimer := SpeedTimer + 1;
				-- If buttons are released, allow faster repeat
				IF LeftButton NOR RightButton THEN
					SpeedTimer := SpeedTimer + 3;
				END IF;
			ELSE
				SpeedTimer := 0;
			END IF;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------
	-- E80 Computer instantiation
	-------------------------------------------------------------------
	Computer_inst: ENTITY work.Computer PORT MAP(
		CLK,      -- generated by the Control buttons process
		Reset,    -- generated by the Control buttons process
		DIPinput, -- 8-bit DIP switch user input, shown on Matrix3
		PC,       -- program counter, shown on Matrix1
		Instr1,   -- instruction part 1 / [PC], shown on Matrix1
		Instr2,   -- instruction part 2 / [PC+1], shown on Matrix1
		R,        -- register file, shown on Matrix2 (flags shown on Matrix1)
		RAM);     -- RAM contents, two blocks shown on Matrices 3 and 4
	-------------------------------------------------------------------
	-- LED display
	-------------------------------------------------------------------
	LED_Driver: ENTITY work.MAX7219x4 PORT MAP (
		CLK1MHz,     -- main process clock input
		Reset,
		Matrix1,     -- leftmost 8x8 LEDs input, assigned below
		Matrix2,
		Matrix3,
		Matrix4,
		MAX7219DIN,  -- output to the 4in1 MAX7219 module DIN
		MAX7219CS,   -- output to the 4in1 MAX7219 module CS (or LOAD)
		MAX7219CLK); -- output to the 4in1 MAX7219 module serial CLK
	-------------------------------------------------------------------
	-- Matrix1  Row 1: Speed level (one-hot bits 7 to 1), Clock (bit 0)
	--          Row 2: 00000000
	--          Row 3: Program Counter
	--          Row 4: Instr1 (Instruction Word part 1)
	--          Row 5: Instr2 (Instruction Word part 2)
	--          Row 6: 00000000
	--          Row 7: Carry, Zero, Sign, Overflow, Halt, 0, 0, 0
	--          Row 8: 00000000
	-------------------------------------------------------------------
	WITH Speed SELECT Matrix1(0)(7 DOWNTO 1) <=
		"1000000" WHEN 0, "0100000" WHEN 1, "0010000" WHEN 2, "0001000" WHEN 3,
		"0000100" WHEN 4, "0000010" WHEN 5, "0000001" WHEN OTHERS;
	Matrix1(0)(0) <= CLK;
	Matrix1(1) <= x"00";
	Matrix1(2) <= PC;
	Matrix1(3) <= Instr1;
	Matrix1(4) <= Instr2;
	Matrix1(5) <= x"00";
	Matrix1(6) <= R(6)(7 DOWNTO 3) & "000";
	Matrix1(7) <= x"00";
	-------------------------------------------------------------------
	-- Matrix2  Rows 1-6: General Purpose Registers R0-R5
	--          Row 7: 00000000
	--          Row 8: Stack Pointer (R7)
	-------------------------------------------------------------------
	Matrix2(0 TO 5) <= R(0 TO 5);
	Matrix2(6) <= x"00";
	Matrix2(7) <= R(7);
	-------------------------------------------------------------------
	-- Matrix3  Rows 1-7: RAM block 248-254 (stack space)
	--          Row 8: DIP switch input
	-------------------------------------------------------------------
	StackSpace: FOR i IN 0 TO 6 GENERATE
		Matrix3(i) <= RAM(248 + i);
	END GENERATE;
	Matrix3(7) <= DIPinput;
	-------------------------------------------------------------------
	-- Matrix4  Rows 1-8: 8-word RAM block at .MONITOR address
	-------------------------------------------------------------------
	MonitorBlock: FOR i IN 0 TO 7 GENERATE
		Matrix4(i) <= RAM(MONITOR_directive + i);
	END GENERATE;
END;