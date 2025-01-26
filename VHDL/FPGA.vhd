-----------------------------------------------------------------------
-- E80 FPGA implementation
-- Converts the fast 50 MHz clock to a slow deciHertz-class CLK.
-- Reads the DIPinput and Reset signals.
-- Runs the E80 CPU with the converted CLK, DIPinput and Reset.
-- Displays the flags, one register, the CLK, and the PC on the FPGA LEDs.
-- Allows reset, pause, speed control, and register selection via Joystick.
-----------------------------------------------------------------------

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.support.ALL, work.firmware.ALL;
ENTITY FPGA IS PORT (
	CLK50MHz : IN STD_LOGIC; -- converted to slow CLK
	Reset    : IN STD_LOGIC; -- resets the PC & SP and uploads the firmware
	Pause    : IN STD_LOGIC; -- pauses the CLK
	Up       : IN STD_LOGIC; -- shows the next register on row B
	Down     : IN STD_LOGIC; -- shows the previous register on row B
	Right    : IN STD_LOGIC; -- increases CLK frequency
	Left     : IN STD_LOGIC; -- decreases CLK frequency
	Mid      : IN STD_LOGIC; -- resets CLK to the firmware-specified frequency
	DIPinput : IN WORD;      -- 8-pin DIP switch input
	LED_rowA : OUT WORD;
	LED_rowB : OUT WORD;
	LED_rowC : OUT WORD);
END;
ARCHITECTURE a1 OF FPGA IS
	SIGNAL CLK : STD_LOGIC; -- slow clock (deciHertz-class)
	-- clock control and display signals
	SIGNAL PC : WORD;
	SIGNAL R : WORDx8;
	SIGNAL reg: NATURAL RANGE 0 TO 7 := 0; -- current register address
	SIGNAL ResetComplete : STD_LOGIC := '0';
	ALIAS Halt : STD_LOGIC IS R(6)(3);
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
	-- Clock conversion and joystick input handling
	-------------------------------------------------------------------
	PROCESS (CLK50MHz)
		-- Tick20ns: 50 MHz counter
		-- RepeatRate (in 20ns): minimum time between joystick signals
		-- Delay: 50 MHz joystick signal repeat rate counter
		-- Frequency: initialized to firmware's DefaultFrequency value
		VARIABLE Tick20ns : NATURAL RANGE 0 TO 249999999 := 0;
		CONSTANT RepeatRate : NATURAL := 18000000; -- × 2/10^8 = 0.36 sec
		VARIABLE Delay : NATURAL RANGE 0 TO RepeatRate := 0;
		VARIABLE Frequency : DECIHERTZ := DefaultFrequency; -- see Firmware.vhd
	BEGIN
		IF RISING_EDGE(CLK50MHz) THEN
			IF NOT Pause THEN -- freeze CLK while Pause is being pressed
				-- CLK50MHz to deciHertz CLK conversion:
				-- 50MHz frequency = 50×10^6 cycles/sec ⇒ Period =
				-- 1/(50×10^6) sec/cycle = 2/10^8 sec = 20ns (1 tick).
				-- For a 1 deciHertz clock we need a 10 second period:
				-- 10sec = 5×10^8 × 2/10^8 sec = 5×10^8 * 20ns = 5×10^8 ticks.
				-- CLK <= NOT CLK needs to be executed twice to make a period,
				-- therefore 2.5×10^8 - 1 = 249999999 ticks, because the tick
				-- count starts from zero.
				Tick20ns := Tick20ns + 1;
				IF Tick20ns * Frequency >= 249999999 THEN
					Tick20ns := 0;
					CLK <= NOT CLK;
					-- Signify a completed reset (may take a few seconds
					-- due to synchronization with the slow CLK).
					ResetComplete <= CLK AND Reset;
				END IF;
			END IF;
			-- handle joystick inputs with a delay to prevent rapid toggling
			IF Delay < RepeatRate THEN
				Delay := Delay + 1;
			ELSIF Up THEN
				reg <= reg + 1;
				Delay := 0;
			ELSIF Down THEN
				reg <= reg - 1;
				Delay := 0;
			ELSIF Right THEN -- increase CLK speed
				IF Frequency > 850 THEN
					Frequency := 1000; -- ceiling
				ELSE
					Frequency := Frequency + Frequency/8 + 2;
				END IF;
				Delay := 0;
			ELSIF Left THEN -- decrease CLK speed
				IF Frequency < 3 THEN
					Frequency := 1; -- floor
				ELSE
					Frequency := Frequency - Frequency/8 - 2;
				END IF;
				Delay := 0;
			ELSIF Mid THEN
				Frequency := DefaultFrequency;
				Delay := 0;
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
		'1'      WHEN Halt AND NOT Reset ELSE -- solid, bright
		'1'      WHEN ResetComplete      ELSE -- pulse, bright
		CLK50MHz WHEN CLK                ELSE -- pulse, dim
		'0';
	-- Row B: selected register value or DIP input during reset
	LED_rowB <= DIPinput WHEN Reset ELSE R(reg);
	-- Row C: program counter
	LED_rowC <= PC;
END;