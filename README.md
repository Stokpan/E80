# E80 CPU

A simple CPU in VHDL, developed from scratch for [my undergraduate thesis](https://apothesis.eap.gr/archive/item/222454), designed to:

* Offer an Assembly education Microworld with a rich instruction set
* Bridge digital design and architecture using textbook components only
* Run on low-cost FPGAs or libre/free simulators
* Demonstrate the application of [HOU's Informatics course](https://www.eap.gr/en/undergraduate/computer-science/) throughout the toolchain

| Feature               | Description                                    |
|-----------------------|------------------------------------------------|
| **Dependencies**      | ieee.std_logic_1164 (no arithmetic libraries)  |
| **Execution**         | Single-cycle                                   |
| **Word Size**         | 8-bit                                          |
| **Buses**             | 8-bit data, 8-bit address, 16-bit instruction  |
| **Instruction size**  | Variable (1 or 2 words)                        |
| **RAM**               | 3-port (2R, 1R/W), addressable at 0x00-0xFE    |
| **Register file**     | 8x8, multiport (1R+W, 2R, 1W)                  |
| **Registers**         | 6 general purpose (R0-R5), Flags (R6), SP (R7) |
| **Stack**             | Full descending (Stack Pointer init = 0xFF)    |
| **Architecture**      | Load/Store, register-register                  |
| **Addressing**        | Immediate, direct, register, register-indirect |
| **Input**             | 8-bit at 0xFF (1x8 DIP switch)                 |
| **Output**            | Flags, Registers, PC, Clock (3x8 LEDs)         |
| **Assembly syntax**   | Hybrid of ARM, x86, and textbook pseudocode    |
| **Assembler**         | ISO C99 (standard library, stdin I/O)          |
| **Simulated on**      | GHDL, ModelSim via one-click scripts           |
| **Synthesized on**    | Quartus Lite, Gowin Education, Vivado Standard |
| **Tested on**         | Tang Primer 25K, Altera Cyclone IV             |

# ISA cheatsheet
```
|    | Instr1   | Instr2   | Hex   | Mnemonic      | Description           | CZSV |
|----|----------|----------|-------|---------------|-----------------------|------|
| 1  | 00000000 |          | 00    | HLT           | H ← 1, PC ← PC        |      |
| 2  | 00000001 |          | 01    | NOP           |                       |      |
| 3  | 00000010 | nnnnnnnn | 02 nn | JMP n         | PC ← n                |      |
| 4  | 00000011 | 00000rrr | 03 0r | JMP r         | PC ← r                |      |
| 5  | 00000100 | nnnnnnnn | 04 nn | JC n          | if C=1, PC ← n        |      |
| 6  | 00000101 | nnnnnnnn | 05 nn | JNC n         | if C=0, PC ← n        |      |
| 7  | 00000110 | nnnnnnnn | 06 nn | JZ n          | if Z=1, PC ← n        |      |
| 8  | 00000111 | nnnnnnnn | 07 nn | JNZ n         | if Z=0, PC ← n        |      |
| 9  | 00001010 | nnnnnnnn | 0A nn | JS n          | if S=1, PC ← n        |      |
| 10 | 00001011 | nnnnnnnn | 0B nn | JNS n         | if S=0, PC ← n        |      |
| 11 | 00001100 | nnnnnnnn | 0C nn | JV n          | if V=1, PC ← n        |      |
| 12 | 00001101 | nnnnnnnn | 0D nn | JNV n         | if V=0, PC ← n        |      |
| 13 | 00001110 | nnnnnnnn | 0E nn | CALL n        | PC+2 → [--SP]; PC ← n |      |
| 14 | 00001111 |          | 0F    | RETURN        | PC ← [SP++]           |      |
| 15 | 00010rrr | nnnnnnnn | 1r nn | MOV r,n       | r ← n                 |  **  |
| 16 | 00011000 | 0rrr0rrr | 18 rr | MOV r1,r2     | r1 ← r2               |  **  |
| 17 | 00100rrr | nnnnnnnn | 2r nn | ADD r,n       | r ← r+n               | **** |
| 18 | 00101000 | 0rrr0rrr | 28 rr | ADD r1,r2     | r1 ← r1+r2            | **** |
| 19 | 00110rrr | nnnnnnnn | 3r nn | SUB r,n       | r ← r+(~n)+1          | **** |
| 20 | 00111000 | 0rrr0rrr | 38 rr | SUB r1,r2     | r1 ← r1+(~r2)+1       | **** |
| 21 | 01000rrr | nnnnnnnn | 4r nn | ROR r,n       | r>>n (r<<8-n)         |  **  |
| 22 | 01001000 | 0rrr0rrr | 48 rr | ROR r1,r2     | r1>>r2 (r1<<8-r2)     |  **  |
| 23 | 01010rrr | nnnnnnnn | 5r nn | AND r,n       | r ← r&n               |  **  |
| 24 | 01011000 | 0rrr0rrr | 58 rr | AND r1,r2     | r1 ← r1&r2            |  **  |
| 25 | 01100rrr | nnnnnnnn | 6r nn | OR r,n        | r ← r|n               |  **  |
| 26 | 01101000 | 0rrr0rrr | 68 rr | OR r1,r2      | r1 ← r1|r2            |  **  |
| 27 | 01110rrr | nnnnnnnn | 7r nn | XOR r,n       | r ← r^n               |  **  |
| 28 | 01111000 | 0rrr0rrr | 78 rr | XOR r1,r2     | r1 ← r1^r2            |  **  |
| 29 | 10000rrr | nnnnnnnn | 8r nn | STORE r,[n]   | r → [n]               |      |
| 30 | 10001000 | 0rrr0rrr | 88 rr | STORE r1,[r2] | r1 → [r2]             |      |
| 31 | 10010rrr | nnnnnnnn | 9r nn | LOAD r,[n]    | r ← [n]               |  **  |
| 32 | 10011000 | 0rrr0rrr | 98 rr | LOAD r1,[r2]  | r1 ← [r2]             |  **  |
| 33 | 10100rrr |          | Ar    | RSHIFT r      | (r,C)>>1; V ← S flip  | **** |
| 34 | 10110rrr | nnnnnnnn | Br nn | CMP r,n       | SUB, discard result   | **** |
| 35 | 10111000 | 0rrr0rrr | B8 rr | CMP r1,r2     | SUB, discard result   | **** |
| 36 | 11000rrr |          | Cr    | LSHIFT r      | (C,r)<<1; V ← S flip  | **** |
| 37 | 11010rrr | nnnnnnnn | Dr nn | BIT r,n       | AND, discard result   |  **  |
| 38 | 11100rrr |          | Er    | PUSH r        | r → [--SP]            |      |
| 39 | 11110rrr |          | Fr    | POP r         | r ← [SP++]            |      |

← or →  : Data transfer, takes effect on the next cycle.
n       : 8-bit immediate value or memory address.
r,r1,r2 : 3-bit register address (R0 to R7).
[x]     : Memory at 8-bit address x < 255, [255] = DIP input.
PC      : Program counter, initialized to 0 on reset.
SP      : Register R7, initialized to 255 on reset.
--SP    : Decrease SP by 1, and then read it.
SP++    : Read SP, and then increase it by 1.
Flags   : Register R6 = [CZSVH---], * = flag affected, space = flag unaffected.
C       : Carry flag, C=1 in SUB/CMP A,B ⇔ unsigned A ≥ unsigned B.
Z       : Zero flag, ALU result = 0.
S       : Sign flag, ALU result MSB.
V       : Signed overflow flag, V=1 in L/RSHIFT ⇔ Sign bit flipped.
H       : Halt flag, PC freezes.
```
**Notes**
* ROR rotates the 1st operand to the right, by 2nd operand mod 8 bits. Right rotation by x equals to left rotation by 8-x.
* Shift instructions are logical; Carry flag = shifted bit and the Overflow flag is set if the sign bit has been changed.
* Instructions that modify the FLAGS register take precedence over normal flag changes. Eg. OR FLAGS, 0b01000000 sets Z=1 although the result is non-zero.
* The HLT instruction freezes the PC and sets the H flag. This flag is used by the testbench to stop the simulation and it's also used by the FPGA module to keep the CLK LED active.
* Example of hex & bin encoding: Assume MOV R3,R5. According to the cheatsheet, it translates to 0x18rr ≡ 0x1835 ≡ 0b(00011000 00110101).
* A-B is done via A + ~B + 1 (standard adder logic). Assuming unsigned R1 ≥ R2, SUB/CMP R1, will set Carry flag to 1 (no borrow).
* Explicit updates of the FLAGS (R6) register bypasses normal flag logic, eg. MOV FLAGS,0 sets Z=0 instead of 1.

# Assembly cheatsheet
```
| Directive            | Description                                        |
|----------------------|----------------------------------------------------|
| .TITLE "string"      | Sets VHDL output title to string                   |
| .LABEL name number   | Assigns a number to a label name                   |
| .SIMDIP value        | Sets the DIP input to value (for simulation only)  |
| .DATA val csv        | Write csv to RAM starting from address val         |
| .FREQUENCY deciHertz | Set frequency to deciHertz (1-1000)                |

string : ASCII with escaped quotes, eg. "a\"s d" → "a"s d".
label  : Starts from a letter, may contain letters, numbers, underscores.
number : 0-255 no leading zeroes, bin (eg. 0b0011), hex (eg. 0x0A).
val    : Number or label.
csv    : Comma-separated numbers and strings.

| Instruction      | Notes                                           |
|------------------|-------------------------------------------------|
| HLT              | Sets the H flag and halts execution             |
| NOP              | No operation                                    |
| JMP op1          | Jump to op1 address                             |
| JC n             | Jump if Carry (C=1)                             |
| JNC n            | Jump if Not Carry (C=0)                         |
| JZ n             | Jump if Zero (Z=1)                              |
| JNZ n            | Jump if Not Zero (Z=0)                          |
| JS n             | Jump if Sign (S=1)                              |
| JNS n            | Jump if Not Sign (S=0)                          |
| JV n             | Jump if Overflow (V=1)                          |
| JNV n            | Jump if Not Overflow (V=0)                      |
| CALL n           | Call subroutine at n                            |
| RETURN           | Return from subroutine                          |
| MOV reg, op2     | Move op2 to reg                                 |
| ADD reg, op2     | Add op2 to reg                                  |
| SUB reg, op2     | In unsigned subtraction, C = reg ≥ op2          |
| ROR reg, op2     | Rotate right by op2 bits (left by 8-op2 bits)   |
| AND reg, op2     | Bitwise AND                                     |
| OR reg, op2      | Bitwise OR                                      |
| XOR reg, op2     | Bitwise XOR                                     |
| STORE reg, [op2] | Store reg to op2 address, reg → [op2]           |
| LOAD reg, [op2]  | Load word at op2 address to reg, reg ← [op2]    |
| RSHIFT reg       | Right shift, C = shifted bit, V = sign change   |
| CMP reg, op2     | Compare with SUB, set flags and discard result  |
| LSHIFT reg       | Left shift, C = shifted bit, V = sign change    |
| BIT reg, n       | Bit test with AND, set flags and discard result |
| PUSH reg         | Push reg to stack                               |
| POP reg          | Pop reg from stack                              |

reg     : Register R0-R7 or FLAGS (alias of R6) or SP (alias of R7).
op1/op2 : Reg or val (flexible operand).
[op2]   : Memory at address op2 (or DIP input if op2=0xFF).
```
**Notes**
* Directives must precede all instructions.
* Labels, followed by a colon, can be set between instructions to mark their address, see [Example 1](#example-1---simulation-with-ghdl).
* The Sign and Zero flags are updated by CMP, BIT and any instruction that modifies a register, except for stack-related instructions.
* Carry and oVerflow flags are only updated by arithmetic and shift instructions but not ROR.
* The HLT instruction stops execution on the current cycle, whereas setting the Halt flag by modifying the Flags (R6) register will stop execution on the next cycle. This applies to both ModelSim/GHDL and in the FPGA implementation.

## Flags cheatsheet for ADD a,b
```
| Flag  | Signed                      | Unsigned             |
|-------|-----------------------------|----------------------|
| C=1   |                             | a+b > 255 (overflow) |
| C=0   |                             | a+b ≤ 255            |
| V=1   | a+b ∉ [-128,127] (overflow) |                      |
| V=0   | a+b ∈ [-128,127]            |                      |
| S=1   | a+b < 0                     | a+b ≥ 128 (if C=0)   |
| S=0   | a+b ≥ 0                     | a+b < 128 (if C=0)   |
```

## Flags cheatsheet for  SUB/CMP a,b
```
| Flag  | Signed                      | Unsigned             |
|-------|-----------------------------|----------------------|
| C=1   |                             | a ≥ b                |
| C=0   |                             | a < b (overflow)     |
| V=1   | a-b ∉ [-128,127] (overflow) |                      |
| V=0   | a-b ∈ [-128,127]            |                      |
| S=1   | a < b                       | a-b ≥ 128 (if C=1)   |
| S=0   | a ≥ b                       | a-b < 128 (if C=1)   |
```

## Example 1 - Simulation with GHDL
The following writes the string `` `az{"0 `` followed by the null character, after the last instruction in the memory and converts the lowercase characters to uppercase:
```
.TITLE "Converts the lowercase characters of a given string to uppercase"
.LABEL char_a 97
.LABEL char_after_z 123
.LABEL case_difference 32
.DATA string "`az{\"0",0    ; null-terminated string under the last instruction
    MOV R0, string          ; R0 = address of the first character ("`")
loop:   
    LOAD R1, [R0]           ; R1 = ANSI value of current character
    CMP R1, 0
    JZ finish               ; if R1 = 0 (null character) goto finish
    CMP R1, char_a
    JNC next                ; else if R1 < "a" goto next
    CMP R1, char_after_z
    JC next                 ; else if R1 > "z" goto next
    SUB R1, case_difference ; else change to uppercase
    STORE R1, [R0]          ; write character back to RAM
next:
    ADD R0, 1               ; advance to the next memory address
    JMP loop                ; repeat loop
finish:
    HLT                     ; stop execution & simulation
string:                     ; memory address under HLT
```
You can save this as `uppercase.e80asm` and use `e80asm < uppercase.e80asm` to get the following output:
```
-----------------------------------------------------------------------
-- Converts the lowercase characters of a given string to uppercase
-----------------------------------------------------------------------
LIBRARY ieee, work; USE ieee.std_logic_1164.ALL, work.support.ALL;
PACKAGE firmware IS
CONSTANT DefaultFrequency : DECIHERTZ := 15; -- 1 to 1000
CONSTANT SimDIP : WORD := "00000000"; -- DIP input for testbench only
CONSTANT Firmware : WORDx256  := (
0   => "00010000", 1   => "00011001",  -- MOV R0, 25
2   => "10011000", 3   => "00010000",  -- LOAD R1, [R0]
4   => "10110001", 5   => "00000000",  -- CMP R1, 0
6   => "00000110", 7   => "00011000",  -- JZ 24
8   => "10110001", 9   => "01100001",  -- CMP R1, 97
10  => "00000101", 11  => "00010100",  -- JNC 20
12  => "10110001", 13  => "01111011",  -- CMP R1, 123
14  => "00000100", 15  => "00010100",  -- JC 20
16  => "00110001", 17  => "00100000",  -- SUB R1, 32
18  => "10001000", 19  => "00010000",  -- STORE R1, [R0]
20  => "00100000", 21  => "00000001",  -- ADD R0, 1
22  => "00000010", 23  => "00000010",  -- JMP 2
24  => "00000000",                     -- HLT
25  => "01100000",                     -- '`' (96)
26  => "01100001",                     -- 'a' (97)
27  => "01111010",                     -- 'z' (122)
28  => "01111011",                     -- '{' (123)
29  => "00100010",                     -- '"' (34)
30  => "00110000",                     -- '0' (48)
31  => "00000000",                     -- 0
OTHERS => "UUUUUUUU");END;
```
You can now save this in VHDL\Firmware.vhd and run computer_tb.bat in the `GHDL Scripts` folder. Provided that you have installed GHDL & GTKwave (both included in the [Release package](https://github.com/Stokpan/E80/releases)), you'll see this:

<img width="1858" height="1200" alt="image" src="https://github.com/user-attachments/assets/f2d6ea5c-f4fd-4b1b-ac63-68b8a3f10847" />

The highlighted RAM locations 25-31 have been initialized by the .DATA directive and modified by the program. These have been manually set to ASCII data format in GTKwave.

## Example 2 - Testing on the Tang Primer 25K

First, install Gowin EDA Student Edition ([Windows](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_x64_win.zip), [Linux](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_Linux.tar.gz), [MacOS](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03Education_macOS.dmg)).

Study the pin assignments in the `Gowin\E80.cst` file and apply them to your board. Use a five-direction navigation button/joystick with Left, Right, Up, Down, Set (for Pause), and Reset. All input pins must be *active high* with a 10kΩ pull-down resistor and the joystick's COM port must be connected to a 3.3V output. Below is a reference photo of the board setup:

<img width="2300" height="1294" alt="image" src="https://github.com/user-attachments/assets/d1b91bf1-b6d4-4091-96af-2e636041546f" />

The top module (FPGA.vhd) uses three 8-LED rows for display, and the joystick buttons for control:

**LEDs**
* **Row A (Status):**
    * **[7:4] (Flags):** Carry, Zero, Sign, Overflow.
    * **[3:1] (Register Selection):** Binary index of the register currently displayed on Row B.
    * **[0] (Clock):** Pulses dimly during normal execution, pulses brightly during reset, and turns solid bright on HLT.
* **Row B (Data):** Displays the value of the selected register. When Reset is held, it mirrors the DIP switch input instead.
* **Row C (PC):** Displays the current Program Counter.

**Buttons**
* **Joystick Left/Right:** Adjust clock speed; supports auto-repeat when held down.
* **Joystick Center:** Reset clock speed.
* **Joystick Up/Down:** Select which register is displayed on Row B; supports auto-repeat when held down.
* **Set:** Pause execution.
* **Reset:** CPU initialization and firmware reset; press until the Clock LED starts flashing brightly.

To run the test, start by converting the following program to VHDL using the assembler and paste it into `Firmware.vhd` as in the previous example.

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

Open the `Gowin\Gowin.gprj` file in the Gowin IDE. Compile the project using *Run All*, wait for completion, connect your Tang Primer 25K board on your PC, and then use the *Programmer* function to upload the configuration.

When the upload is finished, press the Reset button to initialize the RAM with your program's code. The LED will then pulse dimly as the program runs. If R0 is selected (Row A [3:1] are off), you will see Row B initialize to your DIP input and then rotate 32 times. Then an HLT instruction will be executed and the Clock LED will become solid and bright.