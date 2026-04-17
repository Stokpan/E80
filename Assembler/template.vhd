-- %s
LIBRARY ieee; USE ieee.std_logic_1164.ALL, work.support.ALL;
PACKAGE firmware IS
CONSTANT SIMDIP_directive  : WORD    := "%s";
CONSTANT SPEED_directive   : NATURAL := %d;
CONSTANT MONITOR_directive : NATURAL := %d;
CONSTANT Firmware : WORDx256  := (
MACHINE_CODE_PLACEHOLDER
OTHERS => "UUUUUUUU");END;