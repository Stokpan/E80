<a href="#"><img align="left" alt="E80 " src="Images/e80icon.svg" width="92" height="83"></a> is a simple CPU in structural VHDL, originally developed for [my undergraduate thesis](https://apothesis.eap.gr/archive/item/222454) as a Papertian Microworld to excersise the idea of program execution on primitive components.

A design exclusively based on the standard logic library and a toolchain that enables one-click simulation of assembly programs provides the low floor. Annotated and extensible code with a textbook-complete instruction set and a pre-configured hardware interface for three low-cost FPGA boards provides the high ceiling. <br clear="left">

## Table of Contents

1. [Features](#features)
2. [Instruction Set Architecture](#instruction-set-architecture)
3. [Assembly Language](#assembly-language)
4. [Simulation Example](#simulation-example)
5. [Hardware Implementation](#hardware-implementation)
6. [Workflow Example with the Olimex GateMateA1-EVB](#workflow-example-with-the-olimex-gatematea1-evb)

## Features

| Feature               | Description                                        |
|-----------------------|----------------------------------------------------|
| **Architecture**      | 8-bit, single-cycle, Load/Store                    |
| **Dependencies**      | ieee.std_logic_1164 (no arithmetic libraries)      |
| **Registers**         | 6 General-purpose, Flags, Stack Pointer            |
| **Instruction format**| Variable size (8 or 16-bit), up to 2 operands      |
| **Memory**            | 1R/W and 2R ports, addressable at 0x00-0xFE        |
| **Addressing**        | Immediate, direct, register, register-indirect     |
| **Stack**             | Full descending, SP initialized at 0xFF            |
| **Input**             | 8-bit static user input memory-mapped at 0xFF      |
| **Output**            | Serial 4x8x8 LED Matrix (4x daisy-chained MAX7219) |
| **Assembly syntax**   | Hybrid of ARM, x86, and textbook pseudocode        |
| **Assembler**         | ISO C99 stdin I/O                                  |
| **Simulated on**      | GHDL+GTKWave and ModelSim                          |
| **Synthesized on**    | GHDL+Yosys, Gowin, Quartus, Vivado                 |
| **Tested on**         | GateMateA1-EVB, Tang Primer 25K, DSD-i1 Cyclone IV |

## Instruction Set Architecture

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
| 4  | 00000100 nnnnnnnn | 04 nn | JC n          | if C=1, PC ← n        |       |
| 5  | 00000101 nnnnnnnn | 05 nn | JNC n         | if C=0, PC ← n        |       |
| 6  | 00000110 nnnnnnnn | 06 nn | JZ n          | if Z=1, PC ← n        |       |
| 7  | 00000111 nnnnnnnn | 07 nn | JNZ n         | if Z=0, PC ← n        |       |
| 8  | 00001010 nnnnnnnn | 0A nn | JS n          | if S=1, PC ← n        |       |
| 9  | 00001011 nnnnnnnn | 0B nn | JNS n         | if S=0, PC ← n        |       |
| 10 | 00001100 nnnnnnnn | 0C nn | JV n          | if V=1, PC ← n        |       |
| 11 | 00001101 nnnnnnnn | 0D nn | JNV n         | if V=0, PC ← n        |       |
| 12 | 00001110 nnnnnnnn | 0E nn | CALL n        | PC+2 → [--SP]; PC ← n |       |
| 13 | 00001111          | 0F    | RETURN        | PC ← [SP++]           |       |
| 14 | 00010rrr nnnnnnnn | 1r nn | MOV r,n       | r ← n                 |  ZS   |
| 15 | 00011000 0rrr0rrr | 18 rr | MOV r1,r2     | r1 ← r2               |  ZS   |
| 16 | 00100rrr nnnnnnnn | 2r nn | ADD r,n       | r ← r+n               | CZSV  |
| 17 | 00101000 0rrr0rrr | 28 rr | ADD r1,r2     | r1 ← r1+r2            | CZSV  |
| 18 | 00110rrr nnnnnnnn | 3r nn | SUB r,n       | r ← r+(~n)+1          | CZSV  |
| 19 | 00111000 0rrr0rrr | 38 rr | SUB r1,r2     | r1 ← r1+(~r2)+1       | CZSV  |
| 20 | 01000rrr nnnnnnnn | 4r nn | AND r,n       | r ← r&n               |  ZS   |
| 21 | 01001000 0rrr0rrr | 48 rr | AND r1,r2     | r1 ← r1&r2            |  ZS   |
| 22 | 01010rrr nnnnnnnn | 5r nn | OR r,n        | r ← r|n               |  ZS   |
| 23 | 01011000 0rrr0rrr | 58 rr | OR r1,r2      | r1 ← r1|r2            |  ZS   |
| 24 | 01100rrr nnnnnnnn | 6r nn | XOR r,n       | r ← r^n               |  ZS   |
| 25 | 01101000 0rrr0rrr | 68 rr | XOR r1,r2     | r1 ← r1^r2            |  ZS   |
| 26 | 01110rrr nnnnnnnn | 7r nn | ROR r,n       | r>>n (r<<8-n)         |  ZS   |
| 27 | 01111000 0rrr0rrr | 78 rr | ROR r1,r2     | r1>>r2 (r1<<8-r2)     |  ZS   |
| 28 | 10000rrr nnnnnnnn | 8r nn | STORE r,[n]   | r → [n]               |       |
| 29 | 10001000 0rrr0rrr | 88 rr | STORE r1,[r2] | r1 → [r2]             |       |
| 30 | 10010rrr nnnnnnnn | 9r nn | LOAD r,[n]    | r ← [n]               |  ZS   |
| 31 | 10011000 0rrr0rrr | 98 rr | LOAD r1,[r2]  | r1 ← [r2]             |  ZS   |
| 32 | 10100rrr          | Ar    | LSHIFT r      | (C,r)<<1; V ← S flip  | CZSV  |
| 33 | 10110rrr nnnnnnnn | Br nn | CMP r,n       | SUB, discard result   | CZSV  |
| 34 | 10111000 0rrr0rrr | B8 rr | CMP r1,r2     | SUB, discard result   | CZSV  |
| 35 | 11000rrr nnnnnnnn | Cr nn | BIT r,n       | AND, discard result   |  ZS   |
| 36 | 11010rrr          | Dr    | RSHIFT r      | (r,C)>>1; V ← S flip  | CZSV  |
| 37 | 11100rrr          | Er    | PUSH r        | r → [--SP]            |       |
| 38 | 11110rrr          | Fr    | POP r         | r ← [SP++]            |       |
+----+-------------------+-------+---------------+-----------------------+-------+
```
**Notes**
* `ROR R1,R2` rotates R1 to the right by R2 bits. This is equivalent to left rotation by 8-R2 bits.
* Carry and Overflow flags are updated by arithmetic and shift instructions, except `ROR`.
* Shift instructions are logical; Carry flag = shifted bit and the Overflow flag is set if the sign bit is changed.
* Sign and Zero flags are updated by `CMP`, `BIT`, and any instruction that modifies a register, except for stack-related instructions.
* Explicit modifications of the FLAGS register take precedence over normal flag changes, eg. `OR FLAGS, 0b01000000` sets Z=1 although the result is non-zero.
* The `HLT` instruction sets the Halt flag and freezes the PC, thereby stopping execution in the current cycle. Setting the Halt flag by modifying the Flags (R6) register will stop execution on the next cycle.
* Addition & subtraction is performed with a textbook adder; flags are set according to this cheatsheet:
```
	               +------+-----------------------------+----------------------+
	               | Flag | Signed                      | Unsigned             |
	+--------------+------+-----------------------------+----------------------+
	| ADD a,b      | C=1  |                             | a+b > 255 (overflow) |
	|              | C=0  |                             | a+b ≤ 255            |
	|              | V=1  | a+b ∉ [-128,127] (overflow) |                      |
	|              | V=0  | a+b ∈ [-128,127]            |                      |
	|              | S=1  | a+b < 0                     | a+b ≥ 128 (if C=0)   |
	|              | S=0  | a+b ≥ 0                     | a+b < 128 (if C=0)   |
	+--------------+------+-----------------------------+----------------------+
	| SUB/CMP a,b  | C=1  |                             | a ≥ b                |
	|              | C=0  |                             | a < b (overflow)     |
	|              | V=1  | a-b ∉ [-128,127] (overflow) |                      |
	|              | V=0  | a-b ∈ [-128,127]            |                      |
	|              | S=1  | a < b (if V=0)              | a-b ≥ 128 (if C=1)   |
	|              | S=0  | a ≥ b (if V=0)              | a-b < 128 (if C=1)   |
	+--------------+------+-----------------------------+----------------------+
```

## Assembly Language

```
string : ASCII with escaped quotes, eg. "a\"bc" is quoted a"bc
label  : Starts from a letter, may contain letters, numbers, underscores
number : -128 to 255 no leading zeros, or bin (eg. 0b0011), or hex (eg. 0x0A)
val    : Number or label
csv    : Comma-separated numbers and strings
reg    : Register R0-R7 or FLAGS (alias of R6) or SP (alias of R7)
op2    : Reg or val (flexible 2nd operand)
[op2]  : Memory at address op2 (or DIP input if op2=0xFF)

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
| JMP n                | Jump to address n                                  |
| Jflag n              | Jump if flag=1 (flags: C,Z,S,V)                    |
| JNflag n             | Jump if flag=0                                     |
| CALL n               | Call subroutine at n                               |
| RETURN               | Return from subroutine                             |
| MOV reg, op2         | Move op2 to reg                                    |
| ADD reg, op2         | Add op2 to reg                                     |
| SUB reg, op2         | Subtract op2 from reg (add 2's complement of op2)  |
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
* The `.SPEED` directive sets the initial CPU clock frequency in the FPGA according to the [Hardware Implementation section](#hardware-implementation). Default value is 2 (~1 Hz).
* The `.SIMDIP` directive sets a constant value for address 0xFF in simulation only. It's ignored on hardware execution, assuming the programmer would set the same value on the DIP switches.

## Simulation Example

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

To simulate it, first install the latest E80 Toolchain release, and then open the E80 Editor and paste the code into it:

<p align="center"><img alt="Sc1 editor window with assembly code" src="Images/Simulation/Sc1Assembly.png" width="591" height="496"></p>

_Notice that syntax highlighting for the E80 assembly language has been enabled by default._

Hit F5. The editor will automatically assemble the code, save the VHDL output, compile the entire design with GHDL, and launch a GTKWave instance. Subsequent simulations will close the previous GTKWave window to open a new one.

You should see the following waveform, in which the RAM has been expanded to show how the lowercase letters of the string have changed to uppercase:

<p align="center"><img alt="GHDL waveform output in GTKWave; the highlighted RAM locations 25-31 (shown in ASCII radix) have been initialized by the .DATA directive and modified by the program" src="Images/Simulation/GTKWave.png" width="1383" height="1177"></p>

_Notice that the HLT instruction has stopped the simulation in GHDL, allowing for the waveforms to be drawn for the runtime only. This useful feature is supported in ModelSim as well._

You can also hit F7 to view the generated Firmware.vhd file, without simulation:

<p align="center"><img alt="VHDL output of the assembler" src="Images/Simulation/Sc1VHDL.png" width="591" height="581"></p>

_Notice how the assembler formats the output into columns according to instruction size, and annotates each line to its respective disassembled instruction, ASCII character or number._

If you have installed ModelSim, you can hit F8 to automatically open ModelSim and simulate into it. Subsequent simulations on ModelSim will update its existing window:

<p align="center"><img alt="ModelSim simulation and waveform" src="Images/Simulation/ModelSim.png" width="1440" height="900"></p>

_The Memory Data tab next to the Wave tab contains the RAM at the end of simulation. The contents can also be displayed by hovering on the RAM in the Wave tab, but there's a catch: if the radix is set to ASCII and the data include a curly bracket, ModelSim will throw an error when trying to show the tooltip._

## Hardware Implementation

The design is complemented by an Interface unit which requires a clock input; its frequency (2 MHz minimum) must be specified in `Boards\*\Board.vhd`. This generates an array of seven clocks from 0 to 2 kHz, one of which is selected to drive the CPU.

User input is provided via an 8-bit DIP switch. Reset, pause, and speed throttling are provided by four buttons; a 5-way joystick provides more than enough buttons. All input pins must be active-high with 10kΩ pull-down resistors.

Output is provided via a 4x8x8 LED module driven by four daisy-chained MAX7219 chips, requiring three input lines. The logic assumes the module is oriented with its pins on the left, where Matrix 1 is the leftmost and Row 1 is the topmost.

* **8-bit DIP switch:** Provides a static word at address 0xFF.
* **Left/Right buttons:** Adjust speed level (clock frequency) as follows:
	* Speed level 0: 0 Hz, clock is gated high
	* Speed level 1: 0.24 Hz
	* Speed level 2: ~1 Hz
	* Speed level 3: ~2 Hz
	* Speed level 4: ~4 Hz
	* Speed level 5: ~15 Hz
	* Speed level 6: 2 KHz
* **Pause button:** Pauses clock to low while pressed. Combined with Speed Level 0, releasing will resume clock to high, triggering a rising edge thereby allowing for step execution.
* **Reset button:** Initializes the RAM to the Firmware, and resets the Program Counter and the Halt flag to 0, and the Stack Pointer to 255.
* **Matrix 1:**
	* Row 1: **Speed level** (one-hot encoded on first seven LEDs), **Clock** (rightmost LED)
	* Row 2: blank
	* Row 3: **Program Counter**
	* Row 4: **Instr1** (Instruction Word part 1)
	* Row 5: **Instr2** (Instruction Word part 2)
	* Row 6: blank
	* Row 7: **Carry**, **Zero**, **Sign**, **Overflow**, **Halt**
	* Row 8: blank
* **Matrix 2:**
	* Rows 1-6: **General Purpose Registers R0-R5**
	* Row 7: blank
	* Row 8: **Stack Pointer (R7)**
* **Matrix 3:**
	* Rows 1-8: **RAM block 200-207**
* **Matrix 4:**
	* Rows 1-7: **RAM block 248-254**
	* Row 8: **DIP switch input**

Step-by-step instructions for all three boards and their respective EDAs are provided in their respective folders. The photos showcase the completion of DivMul.e80asm as described in the next section.

**<a href="Boards/Gowin_TangPrimer25K/README.md">Tang Primer 25K (Gowin FPGA Designer) <br> <img src="Boards/Gowin_TangPrimer25K/TangPrimer25K.jpg" width="400" height="200"></a>**

**<a href="Boards/Yosys_GateMateA1/README.md">GateMateA1-EVB (OSS CAD Suite) <br> <img alt="GateMateA1-EVB full setup" src="Boards/Yosys_GateMateA1/GateMateA1-EVB.jpg" width="400" height="250"></a>**

**<a href="Boards/Quartus_DSDi1/README.md">Hellenic Open University DSD-i1 (Quartus Lite) <br> <img src="Boards/Quartus_DSDi1/DSD-i1.jpg" width="400" height="223"></a>**

## Workflow Example with the Olimex GateMateA1-EVB

The following assumes that you have set up the GateMateA1-EVB board according to the instructions in the previous section, and that you are on the toolchain installation folder.

Open DivMul.e80asm and hit F5 to assemble and simulate it. Set the Data Format for all vectors to Binary, for easier comparison with the LED display:

<p align="center"><img alt="DivMul.e80asm simulation on GHDL+GTKWave" src="Images/Hardware/GTKwave.png" width="915" height="594"></p>

Run `Boards\Yosys_GateMateA1\synth.bat`. After step 5, the board will start running the DivMul program.

Use the Left button to set speed to 0. Use the Pause button to execute step-by-step. Use the Right button to change speed to max. When the Halt flag turns on (leftmost row #7, LED #5), compare the simulated results on GTKWave with your LED display:

<p align="center"><img alt="DivMul.e80asm verification on the 4x8x8 LED display" src="Images/Hardware/LEDmatrix.png" width="915" height="497"></p>

_E80 initializes the Program Counter, the Stack Pointer, and the Halt flag, and leaves everything else to undefined. Yosys does not set undefined to 0 by default -- a useful trait for the educational purposes of this project._