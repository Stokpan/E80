-- A simple program to showcase the features of E80 assembly
LIBRARY ieee; USE ieee.std_logic_1164.ALL, work.support.ALL;
PACKAGE program IS
CONSTANT SIMDIP_directive  : WORD    := "10000010";
CONSTANT SPEED_directive   : NATURAL := 2;
CONSTANT MONITOR_directive : NATURAL := 14;
CONSTANT Program : WORDx256  := (
0   => "00010000", 1   => "01101000",  -- 1068  MOV R0, 104
2   => "10000000", 3   => "00001110",  -- 800E  STORE R0, [14]
4   => "11100000",                     -- E0    PUSH R0
5   => "10010000", 6   => "11111111",  -- 90FF  LOAD R0, [255]
7   => "00001110", 8   => "00001011",  -- 0E0B  CALL 11
9   => "11110001",                     -- F1    POP R1
10  => "00000000",                     -- 00    HLT
11  => "00100000", 12  => "10011100",  -- 209C  ADD R0, 156 (-100)
13  => "00001111",                     -- 0F    RETURN
14  => "01101010",                     -- data  'j' (106)
15  => "01100101",                     -- data  'e' (101)
16  => "01101100",                     -- data  'l' (108)
17  => "01101100",                     -- data  'l' (108)
18  => "01101111",                     -- data  'o' (111)
19  => "00000000",                     -- data  0
OTHERS => "UUUUUUUU");END;