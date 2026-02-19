-----------------------------------------------------------------------
TITLE_PLACEHOLDER
-----------------------------------------------------------------------
LIBRARY ieee; USE ieee.std_logic_1164.ALL, work.support.ALL;
PACKAGE firmware IS
CONSTANT SimDIP : WORD := "%s"; -- Simulated DIP input at 0xFF
CONSTANT InitSpeed : NATURAL := %d; -- Initial speed in hardware interface
CONSTANT Firmware : WORDx256  := (
MACHINE_CODE_PLACEHOLDER
OTHERS => "UUUUUUUU");END;