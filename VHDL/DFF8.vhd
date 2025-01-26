-----------------------------------------------------------------------
-- E80 8-bit D flip-flop
-----------------------------------------------------------------------

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY DFF8 IS PORT (
	CLK   : IN STD_LOGIC;
	D     : IN WORD;
	Q     : OUT WORD);
END;
ARCHITECTURE a1 OF DFF8 IS
BEGIN
	PROCESS(CLK) BEGIN
		IF RISING_EDGE(CLK) THEN
			Q <= D;
		END IF;
	END PROCESS;
END;