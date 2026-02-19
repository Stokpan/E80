
# E80 CPU

A simple CPU in structural VHDL, originally developed for [my undergraduate thesis](https://apothesis.eap.gr/archive/item/222454) as a Papertian Microworld, to evoke the powerful idea of program execution on logic gates and flip-flops through a low floor of one-click simulation, and a high ceiling of a textbook-complete instruction set.

| Feature               | Description                                        |
|-----------------------|----------------------------------------------------|
| **Architecture**      | 8-bit, single-cycle, Load/Store                    |
| **Dependencies**      | ieee.std_logic_1164 (no arithmetic libraries)      |
| **Registers**         | 6 General-purpose, Flags, Stack Pointer            |
| **Instruction format**| Variable size (8 or 16-bit), up to 2 operands      |
| **Memory**            | 1R/W and 2R ports, addressable at 0x00-0xFE        |
| **Addressing**        | Immediate, direct, register, register-indirect     |
| **Stack**             | Full descending, SP initialized at 0xFF            |
| **Input**             | 8-bit DIP switches memory-mapped at 0xFF           |
| **Output**            | Serial 4x8x8 LED Matrix (4x daisy-chained MAX7219) |
| **Assembly syntax**   | Hybrid of ARM, x86, and textbook pseudocode        |
| **Assembler**         | ISO C99 stdin I/O                                  |
| **Simulated on**      | GHDL+GTKWave, ModelSim via one-click scripts       |
| **Synthesized on**    | GHDL+Yosys, Gowin, Quartus, Vivado                 |
| **Tested on**         | GateMateA1-EVB, Tang Primer 25K, DSD-i1 Cyclone IV |

# ISA Cheatsheet
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
 +-------------+------+-----------------------------+----------------------+
 | ADD a,b     | C=1  |                             | a+b > 255 (overflow) |
 |             | C=0  |                             | a+b ≤ 255            |
 |             | V=1  | a+b ∉ [-128,127] (overflow) |                      |
 |             | V=0  | a+b ∈ [-128,127]            |                      |
 |             | S=1  | a+b < 0                     | a+b ≥ 128 (if C=0)   |
 |             | S=0  | a+b ≥ 0                     | a+b < 128 (if C=0)   |
 +-------------+------+-----------------------------+----------------------+
 | SUB/CMP a,b | C=1  |                             | a ≥ b                |
 |             | C=0  |                             | a < b (overflow)     |
 |             | V=1  | a-b ∉ [-128,127] (overflow) |                      |
 |             | V=0  | a-b ∈ [-128,127]            |                      |
 |             | S=1  | a < b (if V=0)              | a-b ≥ 128 (if C=1)   |
 |             | S=0  | a ≥ b (if V=0)              | a-b < 128 (if C=1)   |
 +-------------+------+-----------------------------+----------------------+
```
# Assembly Cheatsheet
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
| J⟨flag⟩ n            | Jump if flag=1 (flags: C,Z,S,V)                    |
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
* The `.SPEED` directive defines the initial CPU clock frequency in the FPGA. The seven levels are defined in the [Hardware Implementation section](https://github.com/Stokpan/E80/?tab=readme-ov-file#hardware-implementation). Default `.SPEED` value is 2 (~1 Hz).
* Likewise, the `.SIMDIP` directive doesn't affect execution on FPGAs; it's used in simulation only.

## Example - One-click simulation with GHDL/GTKWave or ModelSim

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

<p align="center"><img alt="Sc1 editor window with assembly code" src="https://github.com/user-attachments/assets/e91c689d-6519-46de-bff9-124ed50d6dc4" /></p>

_Notice that syntax highlighting for the E80 assembly language has been enabled by default for all code (except for VHDL files)._

Press F5. The editor will automatically assemble the code, save the VHDL output, compile the entire design with GHDL, and launch a GTKWave instance. Subsequent simulations will close the previous GTKWave window to open a new one.

You should see the following waveform, in which the RAM has been expanded to show how the lowercase letters of the string have changed to uppercase:

<p align="center"><img alt="GHDL waveform output in GTKWave. The highlighted RAM locations 25-31 have been initialized by the .DATA directive and modified by the program. These have been manually set to ASCII data format in GTKwave." src="https://github.com/user-attachments/assets/5c0606e3-69f4-4e06-8caa-f3125d3c4ef8" /></p>

_Notice that the HLT instruction has stopped the simulation in GHDL, allowing for the waveforms to be drawn for the runtime only. This useful feature is supported in ModelSim as well._

You can also press F7 to view the generated `Firmware.vhd` file, without simulation:

<p align="center"><img alt="VHDL output of the assembler" src="https://github.com/user-attachments/assets/a10a54a1-60e7-43cd-b89f-3b4ef980bc06" /></p>

_Notice how the assembler formats the output into columns according to instruction size, and annotates each line to its respective disassembled instruction, ASCII character or number._

If you have installed ModelSim, you can press F8 to automatically open ModelSim and simulate into it. Subsequent simulations on ModelSim will update its existing window:

<p align="center"><img alt="ModelSim simulation and waveform" src="https://github.com/user-attachments/assets/e767a3a9-15e8-443a-9e1f-bd6bef93ae58" /></p>

_The Memory Data tab next to the Wave tab contains the RAM at the end of simulation. The contents can also be displayed by hovering on the RAM in the Wave tab, but there's a catch: if the radix is set to ASCII and the data include a curly bracket, ModelSim will throw an error when trying to show the tooltip._


# Hardware Implementation

The design is complemented by an Interface unit which requires a hardware clock of at least 2 MHz and, optionally, an 8-bit DIP switch and four buttons for Reset, Pause, Left and Right functions. A 5-direction button joystick with its COM port connected to a VDD pin provides more than enough buttons for this purpose. All input pins must be active high with a 10kΩ pull-down resistor.

The input pins serve the following functions:

* **Left/Right buttons:** Adjust speed level (clock frequency) as follows:
	* Speed level 0: 0 Hz and clock is constantly high
	* Speed level 1: 0.24 Hz
	* Speed level 2: ~1 Hz
	* Speed level 3: ~2 Hz
	* Speed level 4: ~4 Hz
	* Speed level 5: ~15 Hz
	* Speed level 6: 2 KHz
* **Pause:** Sets the clock to 0 while pressed. Combined with Speed Level 0, releasing the Pause button will resume clock to high, triggering a rising edge, thereby allowing for step execution.
* **Reset:** Initializes the RAM to the Firmware, and resets the Program Counter and the Halt flag to 0, and the Stack Pointer to 255.

Output is provided on 4x8x8 LED module driven by four daisy-chained MAX7219 chips. The code assumes that the module is to be read with its connected pins on the left. In the following list, Matrix 1 is leftmost and Row 1 is topmost:

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

## Example 1 - Testing on the Olimex GateMateA1-EVB on Windows

The following assumes you have installed the latest E80 Toolchain release and the paths mentioned will always be relative to its installation folder. You will also need to download the latest [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build) and run it on the toolchain installation folder.

To prepare your hardware, open `Boards\Yosys_GateMateA1\E80.ccf` in a text editor, study its pin assignments and connect the components accordingly. This is an example setup with all components:

<p align="center"><img alt="GateMateA1-EVB full setup" src="https://github.com/user-attachments/assets/ec6f141c-a11d-4d31-b4f9-2ff5ced1fcb7" /></p>

_The LED module requires a minimum 4.0V power supply at 330mA. For the sake of simplicity, I connected it to 3.3V pins in 3 different boards (GateMate, Gowin, DSD-i1) for several hours without issues; if you are using an expensive FPGA, please avoid my example and use a dedicated 5V supply._

Connect the board to your computer via USB, locate the new DirtyJtag device on the Device Manager on "Other Devices", and update its driver to `Boards\Yosys_GateMateA1\Driver`. The device should now appear under "Universal Serial Bus devices" (not the standard USB adapters).

From the toolchain installation folder, open divmul.e80asm and hit `F5` to assemble and simulate it. You can now run `Boards\Yosys_GateMateA1\synth.bat`. It will go through all the necessary steps, from checking requirements to flashing:

<p align="center"><img alt="E80 VHDL Synthesis batch" src="https://github.com/user-attachments/assets/bd71546d-410e-47fa-89c8-0e8773392a1f" /></p>

After step 5, the board will start running the previously assembled program. Use the Left or Right buttons to control the clock speed as shown at the 1st row. When the Halt flag LED turns on (Matrix 1, Row 7, LED #5) the program is finished. You can now compare the simulated results (R0, R1, R2) on GTKWave with the LEDs on Matrix 2, Rows 1-3 as seen here:

<p align="center">
	<img alt="divmul.e80asm simulation on GHDL+GTKWave" src="https://github.com/user-attachments/assets/c2eab69b-5092-4748-aa62-5375078fabc1" />
	<img alt="divmul.e80asm verification on the 4x8x8 LED display" src="https://github.com/user-attachments/assets/5480f387-ed66-4a08-98c1-ab87ddc88d15" />
</p>

_Notice that undefined is not equivalent to zero. While some tools may initialize undefined spaces to 0, Yosys/Gatemate doesn't._

## Example 2 - Testing on the Tang Primer 25K

First, install Gowin EDA Student Edition ([Windows](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_x64_win.zip), [Linux](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_Linux.tar.gz), [MacOS](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03Education_macOS.dmg)).

Like the previous example, open `Boards\Gowin_TangPrimer25K\E80.cst` in a text editor and connect the components accordingly. This is a barebones setup without input buttons:

<p align="center"><img alt="Tang Primer 25K barebones setup" src="https://github.com/user-attachments/assets/5685f56a-0cbf-4a71-ae9d-2158c978ed72" /></p>

_Gowin sets all undefined memory to zero; the non-connected 8-bit DIP switch input defaults to high._

Open divmul.e80asm as in the previous example and assemble it to create Firmware.vhd.

Open the `Boards\Gowin_TangPrimer25K\Gowin.gprj` file in the Gowin IDE. Compile the project using Run All and connect your Tang Primer 25K board to your PC/ When the compilation is finished use the Programmer function (click on USB Cable Setting > Save, and then click on Program/Configure) to upload the bitstream. After the Halt flag turns on, the results should be similar to the photo above.
