-----------------------------------------------------------------------
-- E80 Support Library
-- Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>
-- Provides types and a few functions to allow for cleaner code that's
-- compatible with Quartus Lite which doesn't fully support VHDL2008.
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
PACKAGE support IS
	SUBTYPE WORD IS STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE WORDx8 IS ARRAY (0 TO 7) OF WORD; -- 8 registers
	TYPE WORDx256 IS ARRAY (0 TO 255) OF WORD; -- RAM signals
	SUBTYPE REG_ADDR IS STD_LOGIC_VECTOR(2 DOWNTO 0);
	SUBTYPE DECIHERTZ IS NATURAL RANGE 1 TO 1000;
	FUNCTION int(arg : STD_LOGIC_VECTOR) RETURN NATURAL;
	FUNCTION match(arg1, arg2 : STD_LOGIC_VECTOR) RETURN BOOLEAN;
	FUNCTION match(arg1, arg2 : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
END;
PACKAGE BODY support IS
	-- Equivalent to TO_INTEGER with a logic vector argument to be used
	-- for indexing purposes where logic vectors are considered unsigned.
	FUNCTION int(arg : STD_LOGIC_VECTOR) RETURN NATURAL IS
		VARIABLE result : NATURAL := 0;
	BEGIN
		FOR I IN arg'RANGE LOOP
			result := 2*result;
			IF arg(I) = '1' THEN
				result := result + 1;
			END IF;
		END LOOP;
		RETURN result;
	END;
	-- Simplified version of STD_MATCH that can be used in both boolean and
	-- std_logic expressions to substitute "?=" matching and unary logic
	-- operators which Quartus Lite doesn't support.
	FUNCTION match(arg1, arg2 : STD_LOGIC_VECTOR) RETURN BOOLEAN IS
		-- reorder to make DOWNTOs compatible with FOR I IN RANGE
		ALIAS v1 : STD_LOGIC_VECTOR(1 TO arg1'LENGTH) IS arg1;
		ALIAS v2 : STD_LOGIC_VECTOR(1 TO arg2'LENGTH) IS arg2;
	BEGIN
		FOR I IN v2'RANGE LOOP -- match("abc","a") = true
			IF v1(I) = '-' OR v2(I) = '-' THEN  -- skip don't cares
				NEXT;
			-- compare as bit to avoid std_logic's matching table
			ELSIF To_bit(v1(I)) XOR To_bit(v2(I)) THEN
				RETURN FALSE;
			END IF;
		END LOOP;
		RETURN TRUE;
	END;
	-- overloaded to allow matching in STD_LOGIC context
	FUNCTION match(arg1, arg2 : STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
	BEGIN
		IF match(arg1, arg2) THEN
			RETURN '1';
		ELSE
			RETURN '0';
		END IF;
	END;
END;