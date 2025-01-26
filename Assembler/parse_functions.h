#ifndef PARSE_FUNCTIONS_H
#define PARSE_FUNCTIONS_H

/* Converts s to a number according to this rule:
<number> ::= "0x" <hex+> | "0b" <bit+> | <dec+>
Strings correspond to unsigned numbers, so a negative return value signifies
an error or a non-number */
int number(const char *s);

/* Trims leading and trailing trimmable characters from s. */
void trim(char *s);

/* Compares two strings case-insensitevely, taking into account NULL pointers.
Returns 1 if the strings are equal, 0 otherwise. */
char eq(const char *s1, const char *s2);

char identifier(const char *str);
char array_element(const char *str);

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

/* Returns the value of the operand parameter according to:
<n> ::= <number> | <identifier>
if the parameter is an identifier, it gets its value from the symbols table. */
int value(const char *s);

/* Converts num to bits, in Little Endian order to match VHDL's DOWNTO */
void bitcopy(char *dest, int num, int high, int low);

#endif
