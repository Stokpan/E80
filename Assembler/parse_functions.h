#ifndef PARSE_FUNCTIONS_H
#define PARSE_FUNCTIONS_H

/* Converts s to a decimal number according to this rule:
<number> ::= "0x" <hex+> | "0b" <bit+> | <dec+>
Negative numbers are converted to their 2's complement, so when the conversion
is successful, it always returns beween 0-255. A negative return value signifies
an error or a non-number (eg. -200 would return signed range error) */
int number(const char *s);

/* Trims leading and trailing whitespace and comments from s */
void trim(char *s);

/* Compares two strings case-insensitevely, taking into account NULL pointers,
and returns 1 if the strings are equal, 0 otherwise */
char eq(const char *s1, const char *s2);

/* Returns 1 if s is a <label> */
char label(const char *s);

/* Returns 1 if s is an <array_element> */
char array_element(const char *s);

/* Returns 1 if s is a single-word instruction */
char instr_size1(const char *s);

/* Returns 1 if the parameter is a two-word instruction */
char instr_size2(const char *s);

/* "HLT" | "NOP" | "RETURN" */
char instr_noarg(const char *s);

/* "RSHIFT" | "LSHIFT" | "PUSH" | "POP" */
char instr_reg(const char *s);

/* "JC" | "JNC" | "JZ" | "JNZ" | "JS" | "JNS" | "JV" | "JNV" | "CALL" */
char instr_n(const char *s);

/* "JMP" */
char instr_op1(const char *s);

/* "MOV" | "ADD" | "ROR" | "SUB" | "CMP" | "AND" | "OR" | "XOR" |
"LOAD" | "STORE" */
char instr_reg_op2(const char *s);

/* "LOAD" | "STORE" */
char load_store(const char *s);

/* "BIT" */
char instr_reg_n(const char *s);

/* Returns the address of the register string parameter according to:
<reg> ::= "R0"|"R1"|"R2"|"R3"|"R4"|"R5"|"R6"|"SP"|"R7"|"FLAGS" */
int regnum(const char *s);

/* Returns the value of s according to <value> ::= <number> | <label>
if the parameter is an label, it gets its value from the labels table */
int value(const char *s);

/* Converts num to bits, in Little Endian order to match VHDL's DOWNTO */
void bitcopy(char *dest, int num, int high, int low);

#endif
