-----------------------------------------------------------------------
TITLE_PLACEHOLDER
-----------------------------------------------------------------------
LIBRARY ieee, work; USE ieee.std_logic_1164.ALL, work.support.ALL;
PACKAGE firmware IS
CONSTANT DefaultFrequency : DECIHERTZ := %d;
CONSTANT SimDIP : WORD := "%s";
CONSTANT Firmware : WORDx256  := (
MACHINE_CODE_PLACEHOLDER
OTHERS => "UUUUUUUU");END;