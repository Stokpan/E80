# E80 CPU

A simple CPU in structural VHDL, developed for [my undergraduate thesis](https://apothesis.eap.gr/archive/item/222454) to evoke the powerful idea of program execution on logic gates and flip-flops as a Papertian Microworld: with a low floor of one-click simulation, and a high ceiling of a textbook-complete instruction set.

| Feature               | Description                                        |
|-----------------------|----------------------------------------------------|
| **Architecture**      | 8-bit, single-cycle, Load/Store                    |
| **Dependencies**      | ieee.std_logic_1164 (no arithmetic libraries)      |
| **Memory**            | Addressable at 0x00-0xFE                           |
| **Registers**         | 6 General-purpose (R0-R5), Flags (R6), SP (R7)     |
| **Instruction format**| Variable size (8 or 16-bit), up to 2 operands      |
| **Addressing**        | Immediate, direct, register, register-indirect     |
| **Stack**             | Full descending, SP initialized at 0xFF            |
| **Input**             | 8-bit memory-mapped at 0xFF (DIP switches)         |
| **Output**            | Flags, Registers, PC, Clock (3x8 LEDs)             |
| **Assembly syntax**   | Hybrid of ARM, x86, and textbook pseudocode        |
| **Assembler**         | ISO C99 stdin I/O                                  |
| **Simulated on**      | GHDL/GTKWave & ModelSim via one-click scripts      |
| **Synthesized on**    | GHDL+Yosys, Gowin, Quartus, Vivado                 |
| **Tested on**         | GateMateA1-EVB, Tang Primer 25K, Altera Cyclone IV |

# ISA cheatsheet
```
Operands : n = 8-bit immediate value or direct memory address
           r, r1, r2 = 3-bit register address (R0 to R7)
           eg. MOV R5,110 = 00010rrr nnnnnnnn = 00010101 01101110 = 1rnn = 156E
[x]      : Memory at address x < 255, [255] = DIP input
PC       : Program counter, initialized to 0 on reset
SP       : Register R7, initialized to 255 on reset
           --SP Decrease SP by 1, and then read it
           SP++ Read SP, and then increase it by 1
Flags    : Register R6 = [CZSVH---] (see ALU.vhd)
           C = Carry out (unsigned arithmetic) or shifted-out bit
           Z = Zero, set to 1 when result is 0
           S = Sign, set to the most significant bit of the result
           V = Overflow (signed arithmetic), or sign bit flip in L/RSHIFT
           H = Halt flag, (freezes PC)

     +-------------------+-------+---------------+-----------------------+-------+
     | Instruction       | Hex   | Mnemonic      | Description           | Flags |
+----+-------------------+-------+---------------+-----------------------+-------+
| 1  | 00000000          | 00    | HLT           | PC ← PC               |     H |
| 2  | 00000001          | 01    | NOP           |                       |       |
| 3  | 00000010 nnnnnnnn | 02 nn | JMP n         | PC ← n                |       |
| 4  | 00000011 00000rrr | 03 0r | JMP r         | PC ← r                |       |
| 5  | 00000100 nnnnnnnn | 04 nn | JC n          | if C=1, PC ← n        |       |
| 6  | 00000101 nnnnnnnn | 05 nn | JNC n         | if C=0, PC ← n        |       |
| 7  | 00000110 nnnnnnnn | 06 nn | JZ n          | if Z=1, PC ← n        |       |
| 8  | 00000111 nnnnnnnn | 07 nn | JNZ n         | if Z=0, PC ← n        |       |
| 9  | 00001010 nnnnnnnn | 0A nn | JS n          | if S=1, PC ← n        |       |
| 10 | 00001011 nnnnnnnn | 0B nn | JNS n         | if S=0, PC ← n        |       |
| 11 | 00001100 nnnnnnnn | 0C nn | JV n          | if V=1, PC ← n        |       |
| 12 | 00001101 nnnnnnnn | 0D nn | JNV n         | if V=0, PC ← n        |       |
| 13 | 00001110 nnnnnnnn | 0E nn | CALL n        | PC+2 → [--SP]; PC ← n |       |
| 14 | 00001111          | 0F    | RETURN        | PC ← [SP++]           |       |
| 15 | 00010rrr nnnnnnnn | 1r nn | MOV r,n       | r ← n                 |  ZS   |
| 16 | 00011000 0rrr0rrr | 18 rr | MOV r1,r2     | r1 ← r2               |  ZS   |
| 17 | 00100rrr nnnnnnnn | 2r nn | ADD r,n       | r ← r+n               | CZSV  |
| 18 | 00101000 0rrr0rrr | 28 rr | ADD r1,r2     | r1 ← r1+r2            | CZSV  |
| 19 | 00110rrr nnnnnnnn | 3r nn | SUB r,n       | r ← r+(~n)+1          | CZSV  |
| 20 | 00111000 0rrr0rrr | 38 rr | SUB r1,r2     | r1 ← r1+(~r2)+1       | CZSV  |
| 21 | 01000rrr nnnnnnnn | 4r nn | AND r,n       | r ← r&n               |  ZS   |
| 22 | 01001000 0rrr0rrr | 48 rr | AND r1,r2     | r1 ← r1&r2            |  ZS   |
| 23 | 01010rrr nnnnnnnn | 5r nn | OR r,n        | r ← r|n               |  ZS   |
| 24 | 01011000 0rrr0rrr | 58 rr | OR r1,r2      | r1 ← r1|r2            |  ZS   |
| 25 | 01100rrr nnnnnnnn | 6r nn | XOR r,n       | r ← r^n               |  ZS   |
| 26 | 01101000 0rrr0rrr | 68 rr | XOR r1,r2     | r1 ← r1^r2            |  ZS   |
| 27 | 01110rrr nnnnnnnn | 7r nn | ROR r,n       | r>>n (r<<8-n)         |  ZS   |
| 28 | 01111000 0rrr0rrr | 78 rr | ROR r1,r2     | r1>>r2 (r1<<8-r2)     |  ZS   |
| 29 | 10000rrr nnnnnnnn | 8r nn | STORE r,[n]   | r → [n]               |       |
| 30 | 10001000 0rrr0rrr | 88 rr | STORE r1,[r2] | r1 → [r2]             |       |
| 31 | 10010rrr nnnnnnnn | 9r nn | LOAD r,[n]    | r ← [n]               |  ZS   |
| 32 | 10011000 0rrr0rrr | 98 rr | LOAD r1,[r2]  | r1 ← [r2]             |  ZS   |
| 33 | 10100rrr          | Ar    | LSHIFT r      | (C,r)<<1; V ← S flip  | CZSV  |
| 34 | 10110rrr nnnnnnnn | Br nn | CMP r,n       | SUB, discard result   | CZSV  |
| 35 | 10111000 0rrr0rrr | B8 rr | CMP r1,r2     | SUB, discard result   | CZSV  |
| 36 | 11000rrr nnnnnnnn | Cr nn | BIT r,n       | AND, discard result   |  ZS   |
| 37 | 11010rrr          | Dr    | RSHIFT r      | (r,C)>>1; V ← S flip  | CZSV  |
| 38 | 11100rrr          | Er    | PUSH r        | r → [--SP]            |       |
| 39 | 11110rrr          | Fr    | POP r         | r ← [SP++]            |       |
+----+-------------------+-------+---------------+-----------------------+-------+
```
**Notes**
* `ROR R1,R2` rotates R1 to the right by R2 bits. This is equivalent to left rotation by 8-R2 bits.
* Carry and oVerflow flags are updated by arithmetic and shift instructions, except `ROR`.
* Shift instructions are logical; Carry flag = shifted bit and the Overflow flag is set if the sign bit is changed.
* The Sign and Zero flags are updated by `CMP`, `BIT`, and any instruction that modifies a register, except for stack-related instructions.
* Explicit modifications of the FLAGS register take precedence over normal flag changes, eg. `OR FLAGS, 0b01000000` sets Z=1 although the result is non-zero.
* The `HLT` instruction sets the H flag and freezes the PC, thereby stopping execution in the current cycle. Setting the Halt flag by modifying the Flags (R6) register will stop execution on the next cycle.
* Comparison of unsigned numbers via the Carry flag can be confusing because `SUB R1,R2` is done via standard adder logic (R1 + ~R2 + 1). See the flags cheatsheet below.
## Flags cheatsheet
```
           +------+-----------------------------+----------------------+
           | Flag | Signed                      | Unsigned             |
 +---------+------+-----------------------------+----------------------+
 | ADD a,b | C=1  |                             | a+b > 255 (overflow) |
 |         | C=0  |                             | a+b ≤ 255            |
 |         | V=1  | a+b ∉ [-128,127] (overflow) |                      |
 |         | V=0  | a+b ∈ [-128,127]            |                      |
 |         | S=1  | a+b < 0                     | a+b ≥ 128 (if C=0)   |
 |         | S=0  | a+b ≥ 0                     | a+b < 128 (if C=0)   |
 +---------+------+-----------------------------+----------------------+
 | SUB a,b | C=1  |                             | a ≥ b                |
 | or      | C=0  |                             | a < b (overflow)     |
 | CMP a,b | V=1  | a-b ∉ [-128,127] (overflow) |                      |
 |         | V=0  | a-b ∈ [-128,127]            |                      |
 |         | S=1  | a < b                       | a-b ≥ 128 (if C=1)   |
 |         | S=0  | a ≥ b                       | a-b < 128 (if C=1)   |
 +---------+------+-----------------------------+----------------------+
```
# Assembly cheatsheet
```
string  : ASCII with escaped quotes, eg. "a\"bc" is quoted a"bc
label   : Starts from a letter, may contain letters, numbers, underscores
number  : -128 to 255 no leading zeros, or bin (eg. 0b0011), or hex (eg. 0x0A)
val     : Number or label
csv     : Comma-separated numbers and strings
reg     : Register R0-R7 or FLAGS (alias of R6) or SP (alias of R7)
op1/op2 : Reg or val (flexible operand)
[op2]   : Memory at address op2 (or DIP input if op2=0xFF)

+----------------------+----------------------------------------------------+
| Directive            | Description                                        |
+----------------------+----------------------------------------------------+
| .TITLE "string"      | Set the title for the Firmware.vhd output          |
| .LABEL label number  | Assign a number to a label                         |
| .DATA label csv      | Append csv at label address after program space    |
| .SIMDIP value        | Set the DIP switch input (simulation only)         |
| .SPEED level         | Initialize clock speed to level 0-6 on the FPGA    |
+----------------------+----------------------------------------------------+

+----------------------+----------------------------------------------------+
| Instruction          | Description                                        |
+----------------------+----------------------------------------------------+
| label:               | Label the address of the next instruction          |
| HLT                  | Set the H flag and halt execution                  |
| NOP                  | No operation                                       |
| JMP op1              | Jump to op1 address                                |
| J⟨flag⟩ n            | Jump if flag=1 (flags: C,Z,N,V)                    |
| JN⟨flag⟩ n           | Jump if flag=0                                     |
| CALL n               | Call subroutine at n                               |
| RETURN               | Return from subroutine                             |
| MOV reg, op2         | Move op2 to reg                                    |
| ADD reg, op2         | Add op2 to reg                                     |
| SUB reg, op2         | Subtract op2 from reg                              |
| ROR reg, op2         | Rotate right by op2 bits (left by 8-op2 bits)      |
| AND reg, op2         | Bitwise AND                                        |
| OR reg, op2          | Bitwise OR                                         |
| XOR reg, op2         | Bitwise XOR                                        |
| STORE reg, [op2]     | Store reg to op2 address, reg → [op2]              |
| LOAD reg, [op2]      | Load reg with word at op2 address, reg ← [op2]     |
| RSHIFT reg           | Right shift, C = shifted bit, V = sign change      |
| CMP reg, op2         | Compare with SUB, set flags and discard result     |
| LSHIFT reg           | Left shift, C = shifted bit, V = sign change       |
| BIT reg, n           | Bit test with AND, set flags and discard result    |
| PUSH reg             | Push reg to stack                                  |
| POP reg              | Pop reg from stack                                 |
+----------------------+----------------------------------------------------+
```
**Notes**
* Directives must precede instructions.
* Labels are case sensitive; directives and instructions are not.
* .DATA sets a label after the last instruction and writes the csv data to it; consecutive .DATA directives append after each other.
* Comments start with a semicolon.
* The grammar is available in BNF notation at [Piber's Testing suite](https://cpiber.github.io/CFG-Tester/#input=.TITLE%20%22Division%20testing%22%0A.SPEED%203%20%0A%0A.LABEL%20a%2010%0A.DATA%20a%202%2C%220%22%0A%0A%09MOV%20R1%2C%20-0b0101%0A%09LOAD%20R2%2C%20%5B0xFF%5D%0A%09CALL%20mult%0A%09JMP%20fin%0Amult%3A%20PUSH%20R1%09%09%09%09%0A%09PUSH%20R2%0A%09MOV%20R0%2C%200%0Aloop%3A&rules=%3Cstart%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3C%5Bdirectives%5D%3E%20%3C%5Bstatements%5D%3E%20%3C%5Blabel%3A%5D%3E%0A%3C%5Bdirectives%5D%3E%20%20%3A%3A%3D%20%3Cdirective%3E%20%7C%20%3Cdirective%3E%20%3Cnl%2B%3E%20%3C%5Bdirectives%5D%3E%20%7C%20%3C%5B%5Cn%5D%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.TITLE%22%20%3Cs%2B%3E%20%3Cquoted_string%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.SPEED%22%20%3Cs%2B%3E%20%3Cdec%2B%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.SIMDIP%22%20%3Cs%2B%3E%20%3Cvalue%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.LABEL%22%20%3Cs%2B%3E%20%3Clabel%3E%20%3Cs%2B%3E%20%3Cnumber%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.DATA%22%20%3Cs%2B%3E%20%3Clabel%3E%20%3Cs%2B%3E%20%3Carray%3E%0A%3C%5Bstatements%5D%3E%20%20%3A%3A%3D%20%3Cstatement%3E%20%7C%20%3Cstatement%3E%20%3Cnl%2B%3E%20%3C%5Bstatements%5D%3E%20%7C%20%3C%5B%5Cn%5D%3E%0A%3Cstatement%3E%20%20%20%20%20%3A%3A%3D%20%3Cinstruction%3E%20%7C%20%3Clabel%3A%3E%20%3Cinstruction%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_noarg%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_reg%3E%20%3Cs%2B%3E%20%3Creg%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_val%3E%20%3Cs%2B%3E%20%3Cvalue%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_op1%3E%20%3Cs%2B%3E%20%3Cop1%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_reg_op2%3E%20%3Cs%2B%3E%20%3Creg%3E%20%3C%2C%3E%20%3Cop2%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_ldst%3E%20%3Cs%2B%3E%20%3Creg%3E%20%3C%2C%3E%20%3Cbracket_op2%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_reg_n%3E%20%3Cs%2B%3E%20%3Creg%3E%20%3C%2C%3E%20%3Cvalue%3E%0A%3Cinstr_noarg%3E%20%20%20%3A%3A%3D%20%22HLT%22%20%7C%20%22NOP%22%20%7C%20%22RETURN%22%0A%3Cinstr_reg%3E%20%20%20%20%20%3A%3A%3D%20%22RSHIFT%22%20%7C%20%22LSHIFT%22%20%7C%20%22PUSH%22%20%7C%20%22POP%22%0A%3Cinstr_val%3E%20%20%20%20%20%3A%3A%3D%20%22JC%22%20%7C%20%22JNC%22%20%7C%20%22JZ%22%20%7C%20%22JNZ%22%20%7C%20%22JS%22%20%7C%20%22JNS%22%20%7C%20%22JV%22%20%7C%20%22JNV%22%20%7C%20%22CALL%22%0A%3Cinstr_op1%3E%20%20%20%20%20%3A%3A%3D%20%22JMP%22%0A%3Cinstr_reg_op2%3E%20%3A%3A%3D%20%22MOV%22%20%7C%20%22ADD%22%20%7C%20%22ROR%22%20%7C%20%22SUB%22%20%7C%20%22CMP%22%20%7C%20%22AND%22%20%7C%20%22OR%22%20%7C%20%22XOR%22%0A%3Cinstr_ldst%3E%20%20%20%20%3A%3A%3D%20%22LOAD%22%20%7C%20%22STORE%22%0A%3Cinstr_reg_n%3E%20%20%20%3A%3A%3D%20%22BIT%22%0A%3Cop1%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cop2%3E%0A%3Cbracket_op2%3E%20%20%20%3A%3A%3D%20%22%5B%22%20%3Cop2%3E%20%22%5D%22%0A%3Cop2%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Creg%3E%20%7C%20%3Cvalue%3E%0A%3Cvalue%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cnumber%3E%20%7C%20%3Clabel%3E%0A%3C%5Blabel%3A%5D%3E%20%20%20%20%20%20%3A%3A%3D%20%3Clabel%3A%3E%20%7C%20%3C%5B%5Cn%5D%3E%0A%3Clabel%3A%3E%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Clabel%3E%22%3A%22%20%3C%5B%5Cn%5D%3E%0A%3Clabel%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cletter%3E%20%3Clabel_char%2A%3E%0A%3Clabel_char%2A%3E%20%20%20%3A%3A%3D%20%3Clabel_char%3E%20%3Clabel_char%2A%3E%20%7C%20%22%22%0A%3Clabel_char%3E%20%20%20%20%3A%3A%3D%20%3Cletter%3E%20%7C%20%3Cdec%3E%20%7C%20%22_%22%0A%3Creg%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%22R0%22%20%7C%20%22R1%22%20%7C%20%22R2%22%20%7C%20%22R3%22%20%7C%20%22R4%22%20%7C%20%22R5%22%20%7C%20%22R6%22%20%7C%20%22R7%22%20%7C%20%22FLAGS%22%20%7C%20%22SP%22%0A%3Carray%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Carray_element%3E%20%7C%20%3Carray_element%3E%20%3C%2C%3E%20%3Carray%3E%0A%3Carray_element%3E%20%3A%3A%3D%20%3Cnumber%3E%20%7C%20%3Cquoted_string%3E%0A%3Cquoted_string%3E%20%3A%3A%3D%20%22%5C%22%22%20%3Cchar%2B%3E%20%22%5C%22%22%0A%3C%2C%3E%20%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cs%2A%3E%20%22%2C%22%20%3Cs%2A%3E%0A%3Cnumber%3E%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cunumber%3E%20%7C%20%22-%22%20%3Cunumber%3E%0A%3Cunumber%3E%20%20%20%20%20%20%20%3A%3A%3D%20%220x%22%20%3Chex%2B%3E%20%7C%20%220b%22%20%3Cbit%2B%3E%20%7C%20%3Cdec%2B%3E%0A%3Chex%2B%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Chex%3E%20%7C%20%3Chex%3E%20%3Chex%2B%3E%0A%3Cdec%2B%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cdec%3E%20%7C%20%3Cdec%3E%20%3Cdec%2B%3E%0A%3Cbit%2B%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cbit%3E%20%7C%20%3Cbit%3E%20%3Cbit%2B%3E%0A%3Chex%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cdec%3E%20%7C%20%22A%22%20%7C%20%22B%22%20%7C%20%22C%22%20%7C%20%22D%22%20%7C%20%22E%22%20%7C%20%22F%22%20%7C%20%22a%22%20%7C%20%22b%22%20%7C%20%22c%22%20%7C%20%22d%22%20%7C%20%22e%22%20%7C%20%22f%22%0A%3Cdec%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%220%22%20%7C%20%221%22%20%7C%20%222%22%20%7C%20%223%22%20%7C%20%224%22%20%7C%20%225%22%20%7C%20%226%22%20%7C%20%227%22%20%7C%20%228%22%20%7C%20%229%22%0A%3Cbit%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%220%22%20%7C%20%221%22%0A%3Cchar%2B%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cchar%3E%20%7C%20%3Cchar%3E%20%3Cchar%2B%3E%0A%3Cchar%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cletter%3E%20%7C%20%3Cdec%3E%20%7C%20%22%20%22%0A%3C%5B%5Cn%5D%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cnl%2B%3E%20%7C%20%3Cs%2A%3E%0A%3Cnl%2B%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cnl%3E%20%7C%20%3Cnl%3E%20%3Cnl%2B%3E%0A%3Cnl%3E%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cs%2A%3E%20%22%5Cn%22%20%3Cs%2A%3E%0A%3Cs%2A%3E%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cs%2B%3E%20%7C%20%22%22%0A%3Cs%2B%3E%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cs%3E%20%7C%20%3Cs%3E%20%3Cs%2B%3E%0A%3Cs%3E%20%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%22%20%22%20%7C%20%22%5Ct%22%0A%3Cletter%3E%20%20%20%20%20%20%20%20%3A%3A%3D%20%22A%22%20%7C%20%22B%22%20%7C%20%22C%22%20%7C%20%22D%22%20%7C%20%22E%22%20%7C%20%22F%22%20%7C%20%22G%22%20%7C%20%22H%22%20%7C%20%22I%22%20%7C%20%22J%22%20%7C%20%22K%22%20%7C%20%22L%22%20%7C%20%22M%22%20%7C%20%22N%22%20%7C%20%22O%22%20%7C%20%22P%22%20%7C%20%22Q%22%20%7C%20%22R%22%20%7C%20%22S%22%20%7C%20%22T%22%20%7C%20%22U%22%20%7C%20%22V%22%20%7C%20%22W%22%20%7C%20%22X%22%20%7C%20%22Y%22%20%7C%20%22Z%22%20%7C%20%22a%22%20%7C%20%22b%22%20%7C%20%22c%22%20%7C%20%22d%22%20%7C%20%22e%22%20%7C%20%22f%22%20%7C%20%22g%22%20%7C%20%22h%22%20%7C%20%22i%22%20%7C%20%22j%22%20%7C%20%22k%22%20%7C%20%22l%22%20%7C%20%22m%22%20%7C%20%22n%22%20%7C%20%22o%22%20%7C%20%22p%22%20%7C%20%22q%22%20%7C%20%22r%22%20%7C%20%22s%22%20%7C%20%22t%22%20%7C%20%22u%22%20%7C%20%22v%22%20%7C%20%22w%22%20%7C%20%22x%22%20%7C%20%22y%22%20%7C%20%22z%22). To test your input, first select BNF from the settings cogwheel on the top right. This syntax is a structural blueprint, not a full specification, and lacks features such as comments.
* The `.SPEED` directive doesn't affect simulation; it's used for execution in the FPGA. Speed levels are 0 (0 Hz), 1 (0.24 Hz), 2 (~1 Hz, default), 3 (~4 Hz), 4 (~15 Hz), 5 (2 KHz).
* Likewise, the `.SIMDIP` directive doesn't affect execution on FPGAs; it's used in simulation only.

## Example 1 - One-click simulation with GHDL/GTKWave or ModelSim
The following program writes the null-terminated string `` `az{"0 `` to memory after the last instruction (notice the label under HLT) and converts the lowercase characters to uppercase, stopping when it hits the terminator:
```
.TITLE "Converts the lowercase characters of a given string to uppercase"
.LABEL char_a 97
.LABEL char_after_z 123     ; character after "z" is "{"
.LABEL case_difference 32
.DATA string "`az{\"0",0    ; null-terminated string under the last instruction
    MOV R0, string          ; R0 = address of the first character ("`")
loop:   
    LOAD R1, [R0]           ; updates SZ flags (like 6800 & 6502)
    JZ finish               ; loop while [R0] != null
    CMP R1, char_a
    JNC next                ; if [R0] < "a" goto next
    CMP R1, char_after_z
    JC next                 ; else if [R0] ≥ "{" goto next
    SUB R1, case_difference ; [R0] ∈ ["a", "z"], so change to uppercase
    STORE R1, [R0]          ; write character back to RAM
next:
    ADD R0, 1               ; go to the next character
    JMP loop                ; end loop
finish:
    HLT                     ; stop execution & simulation
```
To simulate it, first install the E80 Toolchain package from the Releases, then open the E80 Editor and paste the code into it:

<p align="center"><img width="594" height="525" alt="Sc1 editor window with assembly code" src="https://github.com/user-attachments/assets/e91c689d-6519-46de-bff9-124ed50d6dc4" /></p>

_Notice that syntax highlighting for the E80 assembly language has been enabled by default for all code (except for VHDL files)._

Press F5. The editor will automatically assemble the code, save the VHDL output, compile the entire design with GHDL, and launch a GTKWave instance. Subsequent simulations will close the previous GTKWave window to open a new one.

You should see the following waveform, in which the RAM has been expanded to show how the lowercase letters of the string have changed to uppercase:

<p align="center"><img width="1383" height="1177" alt="GHDL waveform output in GTKWave. The highlighted RAM locations 25-31 have been initialized by the .DATA directive and modified by the program. These have been manually set to ASCII data format in GTKwave." src="https://github.com/user-attachments/assets/5c0606e3-69f4-4e06-8caa-f3125d3c4ef8" /></p>

_Notice that the HLT instruction has stopped the simulation in GHDL, allowing for the waveforms to be drawn for the runtime only. This useful feature is supported in ModelSim as well._

You can also press F7 to view the generated `Firmware.vhd` file, without simulation:

<p align="center"><img width="591" height="577" alt="VHDL output of the assembler" src="https://github.com/user-attachments/assets/a10a54a1-60e7-43cd-b89f-3b4ef980bc06" /></p>

_Notice how the assembler formats the output into columns according to instruction size, and annotates each line to its respective disassembled instruction, ASCII character or number._

If you have installed ModelSim, you can press F8 to automatically open ModelSim and simulate into it. Subsequent simulations on ModelSim will update its existing window:

<p align="center"><img width="1357" height="874" alt="ModelSim simulation and waveform" src="https://github.com/user-attachments/assets/ca2101c5-192a-4323-9d8a-31312d8fe005" /></p>

_The Memory Data tab next to the Wave tab contains the RAM at the end of simulation. The contents can also be displayed by hovering on the RAM in the Wave tab, but there's a catch: if the radix is set to ASCII and the data include a curly bracket, ModelSim will throw an error when trying to show the tooltip._

## Example 2 - Testing on the Tang Primer 25K

First, install Gowin EDA Student Edition ([Windows](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_x64_win.zip), [Linux](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_Linux.tar.gz), [MacOS](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03Education_macOS.dmg)).

Study the pin assignments in the `Gowin\E80.cst` file and apply them to your board. Use a five-direction navigation button/joystick with Left, Right, Up, Down, Set (for Pause), and Reset. All input pins must be *active high* with a 10kΩ pull-down resistor and the joystick's COM port must be connected to a 3.3V output. Below is a reference photo of the board setup:

<p align="center"><img width="2300" height="1294" alt="Tang Primer 25K Board Setup" src="https://github.com/user-attachments/assets/d1b91bf1-b6d4-4091-96af-2e636041546f" /></p>

The top module (FPGA.vhd) uses three 8-LED rows for display, and the joystick buttons for control:

**LEDs**
* **Row A (Status):**
    * **[7:4] (Flags):** Carry, Zero, Sign, Overflow.
    * **[3:1] (Register Selection):** Binary index of the register currently displayed on Row B.
    * **[0] (Clock):** Pulses dimly during normal execution and turns solid bright on HLT.
* **Row B (Data):** Displays the value of the selected register.
* **Row C (PC):** Displays the current Program Counter.

**Buttons**
* **Joystick Left/Right:** Adjust clock speed; supports auto-repeat when held down.
* **Joystick Up/Down:** Select which register is displayed on Row B; supports auto-repeat when held down.
* **Set:** Pause execution. When clock speed is set to 0 Hz, this button allows for step execution.
* **Reset:** CPU initialization and firmware reset.

To run the test, paste the following program into the editor and press F7. This will automatically update `Firmware.vhd` with your new code.

```
.TITLE "256-ROR to test joystick control"
.SIMDIP 0b00000010     ; for simulation only, FPGA ignores this
	LOAD R0, [0xFF]    ; loads the DIP input word to R0
	MOV R1, 0
loop:
	ROR R0, 1
	ADD R1, 1
	JNC loop            ; stop after 256 RORs (32 full rotations)
	HLT
```

Set the DIP switches to match the .SIMDIP value of the program. Open the `Gowin\Gowin.gprj` file in the Gowin IDE. Compile the project using *Run All*, wait for completion, connect your Tang Primer 25K board to your PC, and then use the *Programmer* function to upload the configuration. The clock LED will be pulsing as the program runs. LED row B defaults to R0, so you will see it rotating right. Then the HLT instruction will be executed and the clock LED will stop pulsing.

## Example 3 - Testing on the Olimex GateMateA1-EVB (on Windows)

The following assumes you have installed the latest E80 Toolchain release and the paths mentioned will always be relative to its installation folder.

First, open the `Boards\Yosys_GateMateA1\E80.ccf` file and connect the components using a breadboard, as suggested in the previous section for the Gowin board:

<p align="center"><img width="1200" height="1002" alt="GateMateA1-EVB Board Setup" src="https://github.com/user-attachments/assets/8613203f-9cb4-4e8f-85e8-0e674c599457" /></p>

Connect your GateMate board to your computer via USB, locate the new DirtyJtag device on the Device Manager, and update its driver to `Boards\Yosys_GateMateA1\Driver`. The device should now appear under `Universal Serial Bus devices` (not the standard USB adapters).

Download the latest [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build) release and extract it so that the `oss-cad-suite` directory in the toolchain installation folder contains bin, lib, etc.

You can now run `Boards\Yosys_GateMateA1\synth.bat`. It will go through all the necessary steps, from checking requirements to flashing:

<p align="center"><img width="685" height="319" alt="image" src="https://github.com/user-attachments/assets/51b4f0f6-e2c8-4d57-8166-704fb4a1c778" /></p>

After step 7, the board will start running the pre-generated Division-Multiplication program. Press **Right** on the joystick to speed it up until the clock LED stops flashing, signifying execution halt. Open the E80 editor, load the divmul.e80asm program from the installation folder and hit `F5` to verify the simulated results (R0, R1, R2) on the board. Remember, as specified in the Gowin section, press **Up** or **Down** on the joystick to change the register shown on the LEDs.

In the E80 Editor, paste the 256-ROR program from the previous section into a new tab and hit `F5` to assemble and simulate it. Go back to the synth.bat window and press `3` to repeat the process using the new Firmware.vhd generated by the toolchain. Remember to set a value on the DIP switches before step 7. Once the program starts running, this value should be rotating right on LED row B.