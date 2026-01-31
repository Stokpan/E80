-----------------------------------------------------------------------
-- E80 Board Interface
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
-- Generates a GenCLK vector with up to 1MHz frequencies from the BoardCLK
-- Runs the main interface process with a 1MHz clock
-- Generates debounced reset, pause, speed and register selection signals.
-- Runs the E80 CPU with a DIP input and variable clock speeds from 0 to 2KHz.
-- Displays the flags, one register, the CLK, and the PC on 3 LED rows.
-- Allows reset, pause/step, speed control, and register display selection.
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

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.board.ALL, work.support.ALL, work.firmware.ALL;
ENTITY Interface IS PORT (
	BoardCLK    : IN STD_LOGIC; -- board clock (frequency in Board.vhd)
	ResetButton : IN STD_LOGIC; -- resets PC, SP, & uploads the firmware
	SetButton   : IN STD_LOGIC; -- raises one clock edge and pauses
	Up          : IN STD_LOGIC; -- shows the next register on row B
	Down        : IN STD_LOGIC; -- shows the previous register on row B
	Right       : IN STD_LOGIC; -- increases CLK frequency up to 1 MHz
	Left        : IN STD_LOGIC; -- decreases CLK frequency down to 0 (pause)
	DIPinput    : IN WORD;      -- 8-pin DIP switch input
	LED_rowA    : OUT WORD;     -- flags(CZSV), selected register, clock
	LED_rowB    : OUT WORD;     -- selected register's value
	LED_rowC    : OUT WORD);    -- program counter
END;
ARCHITECTURE a1 OF Interface IS
	SIGNAL Reset  : STD_LOGIC := '0'; -- debounced ResetButton
	SIGNAL Pause    : STD_LOGIC := '0'; -- debounced SetButton
	SIGNAL GenCLK : STD_LOGIC_VECTOR(7 DOWNTO 0); -- see ClockGenerator
	SIGNAL Speed  : NATURAL RANGE 0 TO 6 := InitSpeed; -- GenCLK index
	ALIAS CLK1MHz : STD_LOGIC IS GenCLK(7); -- for board interface only
	SIGNAL CLK    : STD_LOGIC; -- CPU clock speeds range from 0 to 2 KHz
	-- Display signals
	SIGNAL PC     : WORD;
	SIGNAL R      : WORDx8;
	SIGNAL reg    : NATURAL RANGE 0 TO 7 := 0; -- current register address
	ALIAS Halt    : STD_LOGIC IS R(6)(3);
BEGIN
	-------------------------------------------------------------------
	-- E80 Computer instantiation
	-------------------------------------------------------------------
	Computer: ENTITY work.Computer PORT MAP(
		CLK,
		Reset,
		DIPinput,
		PC,
		R);
	-------------------------------------------------------------------
	-- Clock conversion
	-------------------------------------------------------------------
	ClockGenerator: ENTITY work.ClockGenerator
		GENERIC MAP (BoardCLK_MHz) PORT MAP (BoardCLK, GenCLK);
	-----------------------------------------------------------------------
	-- Clock, reset and pause logic
	-----------------------------------------------------------------------
	-- When a reset is registered, the CPU clock switches to the clock of the
	-- button handling process to ensure the reset applies during a rising
	-- edge in the E80 Computer/CPU.
	-- The clock is gated low while pause is pressed. Combined with GenCLK(0)=1
	-- (see ClockGenerator), this causes a clock rising edge when releasing
	-- the pause button, allowing for stepped execution when Speed=0.
	-------------------------------------------------------------------
	-- Button handling
	-------------------------------------------------------------------
	PROCESS (CLK1MHz)
		-- Debouncing and repeat rate settings
		CONSTANT Idle : NATURAL := 400000; -- 0.4 sec
		CONSTANT Ready : NATURAL := 401000; -- plus debounce guard
		CONSTANT Finish : NATURAL := 401010; -- plus 10 cycles
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
			ELSIF Up THEN
				IF JoystickPress < Ready THEN
					JoystickPress := JoystickPress + 1;
				ELSE
					reg <= reg + 1;
					JoystickPress := 0;
				END IF;
			ELSIF Down THEN
				IF JoystickPress < Ready THEN
					JoystickPress := JoystickPress + 1;
				ELSE
					reg <= reg - 1;
					JoystickPress := 0;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------
	-- LED display
	-------------------------------------------------------------------
	-- Row A: status flags, selected register address and clock
	-- [7]Carry [6]Zero [5]Sign [4]Overflow [3][2][1]Register Address [0]CLK
	LED_rowA(7 DOWNTO 4) <= R(6)(7 DOWNTO 4); -- CZSV flags on R6 register
	WITH reg SELECT LED_rowA(3 DOWNTO 1) <=
		"000" WHEN 0, "001" WHEN 1, "010" WHEN 2, "011" WHEN 3,
		"100" WHEN 4, "101" WHEN 5, "110" WHEN 6, "111" WHEN 7;
	LED_rowA(0) <=
		'0'     WHEN Reset         ELSE
		CLK     WHEN Left OR Right ELSE -- show speed change even when halted
		'1'     WHEN Halt          ELSE -- solid, bright
		CLK1MHz WHEN CLK           ELSE -- pulse, dim
		'0';
	-- Row B: selected register value
	LED_rowB <= R(reg);
	-- Row C: program counter
	LED_rowC <= PC;
END;