-----------------------------------------------------------------------
-- E80 8-bit Full Adder
-- Performs textbook ripple-carry addition or subtraction
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- 1-bit full adder
-----------------------------------------------------------------------
LIBRARY ieee, work; 
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY FA IS PORT (
	A    : IN STD_LOGIC;
	B    : IN STD_LOGIC;
	Cin  : IN STD_LOGIC;
	S    : OUT STD_LOGIC;
	Cout : OUT STD_LOGIC);
END;
ARCHITECTURE a1 OF FA IS
	SIGNAL X : STD_LOGIC;
BEGIN
	X <= A XOR B;
	S <= X XOR Cin;
	Cout <= (A AND B) OR (X AND Cin);
END;
-----------------------------------------------------------------------
-- 8-bit full adder
-----------------------------------------------------------------------
LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL, work.support.ALL;
ENTITY FA8 IS PORT (
	A    : IN WORD;
	B    : IN WORD;
	Sub  : IN STD_LOGIC;   -- 0=addition, 1=subtraction
	Sum  : OUT WORD;
	Cout : OUT STD_LOGIC;
	V    : OUT STD_LOGIC); -- overflow
END;
ARCHITECTURE a1 OF FA8 IS
	SIGNAL C : STD_LOGIC_VECTOR(8 DOWNTO 0); -- C(i) = CarryIn for bit i
BEGIN
    -- Sum = A+(B XOR Sub)+C(0) = A + B + 0     = A+B (if Sub=0)
    --                            A + NOT B + 1 = A-B (if Sub=1)
	C(0) <= Sub;
	FA_Array : FOR i IN 0 TO 7 GENERATE
		FA: ENTITY work.FA PORT MAP(
			A(i),
			B(i) XOR Sub,
			C(i),    -- Cin
			Sum(i),
			C(i+1)); -- Cout
	END GENERATE;
	Cout <= C(8);
	V <= C(8) XOR C(7);
END;