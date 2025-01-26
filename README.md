# E80 CPU

A simple CPU in VHDL designed to:

* Offer an Assembly education Microworld with a rich instruction set
* Bridge digital design and architecture using textbook components only
* Demonstrate the application of Informatics theory throughout the toolchain
* Run on low-cost FPGAs or libre/free simulators

| Feature               | Description                                    |
|-----------------------|------------------------------------------------|
| **Dependencies**      | ieee.std_logic_1164 only                       |
| **Execution**         | Single-cycle                                   |
| **Word Size**         | 8-bit                                          |
| **Buses**             | 8-bit data, 8-bit address, 16-bit instruction  |
| **Instruction size**  | Variable (1 or 2 words)                        |
| **RAM**               | 3-port (2R, 1R/W), Little Endian at 0x00-0xFE  |
| **Register file**     | 8x8, multiport (1R+W, 2R, 1W)                  |
| **Registers**         | 6 general purpose (R0-R5), Flags (R6), SP (R7) |
| **Stack**             | Full descending (SP init = 0xFF)               |
| **Architecture**      | Load/Store, register-register                  |
| **Addressing**        | Immediate, direct, register, register-indirect |
| **Assembly syntax**   | Hybrid of ARM, x86, & textbook (Hayes)         |
| **Assembler**         | ISO C99 (standard library, stdin I/O)          |
| **Simulated on**      | GHDL, ModelSim                                 |
| **Tested on**         | Tang Primer 25K, Altera Cyclone IV             |
| **Input**             | 8-bit at 0xFF (1x8 DIP switch)                 |
| **Output**            | Flags, Registers, PC, Clock (3x8 LEDs)         |

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

← or →  : data transfer, takes effect on the next cycle
n       : 8-bit immediate value or memory address
r,r1,r2 : 3-bit register address (R0 to R7)
[x]     : memory at 8-bit address x < 255, [255] = DIP input
PC      : program counter, initialized to 0 on reset
SP      : register R7, initialized to 255 on reset
--SP    : decrease SP by 1, and then read it
SP++    : read SP, and then increase it by 1
Flags   : register R6 = [CZSVH---], * = flag affected, space = flag unaffected
C       : carry flag, C=1 in SUB/CMP A,B ⇔ unsigned A ≥ unsigned B
Z       : zero flag, ALU result = 0
S       : sign flag, ALU result MSB
V       : signed overflow flag, V=1 in L/RSHIFT ⇔ Sign bit flipped
H       : halt flag, PC freezes
* ROR rotates the 1st operand to the right, by 2nd operand mod 8 bits.
  Right rotation by x equals to left rotation by 8-x.
* Shift instructions are logical; Carry flag = shifted bit and the Overflow
  flag is set if the sign bit has been changed.
* Instructions that modify the FLAGS register take precedence over normal flag
  changes. Eg. OR FLAGS, 0b01000000 sets Z=1 although the result is non-zero.
* The HLT instruction freezes the PC and sets the H flag. This flag is used by
  the testbench to stop the simulation and it's also used by the FPGA module
  to keep the CLK LED active.
* Example of hex & bin encoding: Assume MOV R3,R5. According to the cheatsheet,
  it translates to 0x18rr ≡ 0x1835 ≡ 0b(00011000 00110101).
* A-B is done via A + ~B + 1 (standard adder logic), so:
  SUB/CMP R1, R2 with unsigned R1 ≥ R2 ⇔ Carry flag is set to 1 (no borrow).
* Explicit updates of the FLAGS (R6) register bypasses normal flag logic,
  eg. MOV FLAGS,0 sets Z=0 instead of 1.
```

# Assembly cheatsheet
```
* Directives must precede all instructions.
* Labels mark memory addresses, eg:
    label1: instruction1 ; label1 = address of instruction1
    label2:              ; label2 = address of instruction2
            instruction2 ; (indentation optional)
    label3:              ; label3 = address after instruction2
* Labels must start with a letter and end with a colon.

| Directive            |                   Description            |
|----------------------|------------------------------------------|
| .TITLE "string"      | Sets VHDL output title to string         |
| .NAME symbol number  | Assigns a number to a symbol             |
| .SIMDIP n            | Sets the DIP input for testbench only    |
| .DATA n csv          | Write csv to RAM starting from address n |
| .FREQUENCY deciHertz | Set frequency to deciHertz (1-1000)      |

string : ASCII with escaped quotes, eg. "a\"sd" → a"sd
symbol : Starts from a letter, may contain letters, numbers, underscores
number : 0-255 no leading zeroes, bin (eg. 0b0011), hex (eg. 0x0A)
n      : Number or symbol
csv    : Comma-separated numbers and ASCII strings

| Instruction      |                      Notes                      |
|------------------|-------------------------------------------------|
| HLT              | Halt, FPGA stops, GHDL/ModelSim simulation ends |
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
| ROR reg, op2     | Rotate right by op2 bits ⇔ left by (op2-8) bits |
| AND reg, op2     | Bitwise AND                                     |
| OR reg, op2      | Bitwise OR                                      |
| XOR reg, op2     | eg. XOR reg, 0xFF ⇒ reg ← NOT reg               |
| STORE reg, [op2] | Store reg to op2 address, reg → [op2]           |
| LOAD reg, [op2]  | Load word at op2 address to reg, reg ← [op2]    |
| RSHIFT reg       | Right shift, C = shifted bit, V = sign change   |
| CMP reg, op2     | Compare with SUB, set flags and discard result  |
| LSHIFT reg       | Left shift, C = shifted bit, V = sign change    |
| BIT reg, n       | Bit test with AND, set flags and discard result |
| PUSH reg         | Push reg to stack                               |
| POP reg          | Pop reg from stack                              |

reg     : register R0-R7 or FLAGS (alias of R6) or SP (alias of R7)
op1/op2 : reg or n (flexible operand)
[op2]   : memory at address op2 (or DIP input if op2=0xFF)

S and Z flags are updated by CMP, BIT and any instruction that updates
a register, except for stack-related instructions.

C and V flags are only updated by arithmetic and RSHIFT/LSHIFT instructions.
```

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