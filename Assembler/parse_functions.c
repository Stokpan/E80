// Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "parse_functions.h"
#include "error_handler.h"
#include "data_structures.h"
#include "config.h"

/* Converts a string to uppercase, excluding quoted parts
taking into account escaped quotes. */
void uppercase(char *s)
{
	if (!s || !*s) return; // ignore NULL or empty strings
	*s = (char)toupper(*s); // first character
	char quoted = 0; // flag
	for (s++; *s; s++) {
		if (s[-1] != '\\' && s[0] == '"') { // \" = escaped quote
			 quoted = !quoted;
		}
		if (!quoted) *s = (char)toupper(*s);
	}
}

int number(const char *s)
{
	if (!s) return -1;
	int n; // converted value (or negative)
	char valid[MAX_LINE_LENGTH]; // for sscanf masking -- valid digits
	char invalid[MAX_LINE_LENGTH]; // for sscanf masking -- invalid characters
	char S[MAX_LINE_LENGTH]; // uppercase version of the parameter
	strcpy(S,s);
	uppercase(S);
	// extract the valid digits of the parameter and convert it
	// according to its prefix
	if (!strncmp(S, "0X", 2)) {
		// Hexadecimal format, up to 2 digits
		if (sscanf(S, "0X%2[0-9A-F]%[^\n]", valid, invalid) != 1) {
			return HEX_ERROR;
		}
		n = (int)strtol(valid, NULL, 16);
	} else if (!strncmp(S, "0B", 2)) {
		// Binary format, up to 8 digits
		if (sscanf(S, "0B%8[01]%[^\n]", valid, invalid) != 1) {
			return BIN_ERROR;
		}
		n = (int)strtol(valid, NULL, 2);
	} else {
		// Decimal format
		if (sscanf(S, "%[0-9]%[^0-9]", valid, invalid) != 1) {
			return NUMBER_ERROR;
		}
		if (S[0] == '0' && strlen(S) > 1) {
			// trailing zero is not accepted because it signifies
			// octal numbers in GNU-assembly
			return OCTAL_ERROR;
		}
		n = (int)strtol(S, NULL, 10);
		if (n > 255 || n < 0) return RANGE_ERROR; // unsigned 8 bit
	}
	return n;
}

void trim(char *s)
{
	if (!s || !*s) return;
	char *start = s;
	char *end = s; // end of string
	char quoted = 0;
	while (*end) { // find the terminal or an unquoted semicolon
		if (*end == '"' && end[-1] != '\\') quoted = !quoted; // \" = escaped
		if (!quoted && *end == ';') break;
		end++;
	}
	end--; // terminal = [end+1]
	while (isspace(*start)) start++; // first non-trimmable up to terminal
	if (start < end) {
		while (isspace(*end)) end--; // last non-trimmable
	}
	end[1] = '\0'; // terminate after the last non-trimmable
	// shift the trimmed content to the begin of the string,
	// +1 for a single character, and +1 for the added terminator
	memmove(s, start, end - start + 2);
}

char eq(const char *s1, const char *s2)
{
	if (s1 == s2) return 1; // both NULL or point to the same string
	if (!s1 || !s2) return 0; // only one is NULL
	// compare each character case-insensitively until a terminator is reached
	// in either string
	while (*s1 && *s2 && toupper(*s1) == toupper(*s2)) {
		s1++;
		s2++;
	}
	// if both terminators have been reached, they are equal
	return !*s1 && !*s2;
}

char instr_size1(const char *s) {
	// search string: space + str + space
	char search_str[strlen(s)+3];
	sprintf(search_str, " %s ", s);
	uppercase(search_str);
	return (strstr(" HLT NOP RETURN RSHIFT LSHIFT PUSH POP ",search_str) != 0);
}

char instr_size2(const char *s) {
	// search string: space + str + space
	char search_str[strlen(s)+3];
	sprintf(search_str, " %s ", s);
	uppercase(search_str);
	return (strstr(" JMP JC JNC JZ JNZ JS JNS JV JNV CALL MOV ADD SUB ROR AND"
		" OR XOR STORE LOAD CMP BIT ", search_str) != 0);
}

char reserved(const char *s) {
	if (instr_size1(s)) return 1;
	if (instr_size2(s)) return 1;
	// search string: space + s + space
	char search_str[strlen(s)+3];
	sprintf(search_str, " %s ", s);
	uppercase(search_str);
	return (strstr(" R0 R1 R2 R3 R4 R5 R6 R7 SP FLAGS ", search_str) != 0);
}

char instr_noarg(const char *s)
{
	if      (eq(s, "HLT"))    strcpy(RAM, "00000000");
	else if (eq(s, "NOP"))    strcpy(RAM, "00000001");
	else if (eq(s, "RETURN")) strcpy(RAM, "00001111");
	else return 0;
	return 1;
}

char instr_reg(const char *s)
{
	if      (eq(s, "RSHIFT")) strcpy(RAM, "10100");
	else if (eq(s, "LSHIFT")) strcpy(RAM, "11000");
	else if (eq(s, "PUSH"))   strcpy(RAM, "11100");
	else if (eq(s, "POP"))    strcpy(RAM, "11110");
	else return 0;
	return 1;
}

char instr_n(const char *s)
{
	if      (eq(s, "JC"))   strcpy(RAM, "00000100");
	else if (eq(s, "JNC"))  strcpy(RAM, "00000101");
	else if (eq(s, "JZ"))   strcpy(RAM, "00000110");
	else if (eq(s, "JNZ"))  strcpy(RAM, "00000111");
	else if (eq(s, "JS"))   strcpy(RAM, "00001010");
	else if (eq(s, "JNS"))  strcpy(RAM, "00001011");
	else if (eq(s, "JV"))   strcpy(RAM, "00001100");
	else if (eq(s, "JNV"))  strcpy(RAM, "00001101");
	else if (eq(s, "CALL")) strcpy(RAM, "00001110");
	else return 0;
	return 2;
}

char instr_op1(const char *s)
{
	if      (eq(s, "JMP"))  strcpy(RAM, "0000001"); // ≠ NOP
	else return 0;
	return 2;
}

char instr_reg_op2(const char *s)
{
	if      (eq(s, "MOV"))   strcpy(RAM, "0001");
	else if (eq(s, "ADD"))   strcpy(RAM, "0010");
	else if (eq(s, "SUB"))   strcpy(RAM, "0011");
	else if (eq(s, "ROR"))   strcpy(RAM, "0100");
	else if (eq(s, "AND"))   strcpy(RAM, "0101");
	else if (eq(s, "OR"))    strcpy(RAM, "0110");
	else if (eq(s, "XOR"))   strcpy(RAM, "0111");
	else if (eq(s, "STORE")) strcpy(RAM, "1000");
	else if (eq(s, "LOAD"))  strcpy(RAM, "1001");
	else if (eq(s, "CMP"))   strcpy(RAM, "1011");
	else return 0;
	return 2;
}

char load_store(const char *s)
{
	if      (eq(s, "STORE")) strcpy(RAM, "1000");
	else if (eq(s, "LOAD"))  strcpy(RAM, "1001");
	else return 0;
	return 2;
}

char instr_reg_n(const char *s)
{
	if (eq(s, "BIT")) strcpy(RAM, "11010");
	else return 0;
	return 2;
}

/* <label_char> ::= <letter> | <dec> | "_" */
char label_char(const char c)
{
	return isalpha(c) || isdigit(c) || c == '_';
}

/* <label> ::= <letter> <label_char*> */
char label(const char *s)
{
	if (!isalpha(s[0])) return 0;
	for (int i = 1; s[i] != '\0'; i++) {
		if (!label_char(s[i])) return 0;
	}
	// don't allow labels to use reserved words
	if (reserved(s)) error(RESERVED);
	return 1;
}

/* <array_element> ::= <number> | <quoted_string> */
char array_element(const char *s)
{
	int len = strlen(s);
	if (s[0] == '"') {
		// <quoted_string> ::= "\"" <char+> "\""
		if (len < 3) error(EMPTY_STRING);
		// the closing quote is handled at nexttoken in data_structures.c
	} else if (number(s) < 0) {
		error(ARRAY_ELEMENT);
	}
	return 1;
}

int regnum(const char *s)
{
	if (eq(s,"R0")) return 0;
	if (eq(s,"R1")) return 1;
	if (eq(s,"R2")) return 2;
	if (eq(s,"R3")) return 3;
	if (eq(s,"R4")) return 4;
	if (eq(s,"R5")) return 5;
	if (eq(s,"R6") || eq(s,"FLAGS")) return 6;
	if (eq(s,"R7") || eq(s,"SP")) return 7;
	return -1;
}

int value(const char *s)
{
	int n = number(s);
	if (n >= 0) return n;
	// if it's not a number, it must be a label
	int i = findlabel(s);
	if (i > -1) {
		return Out.label[i].val;
	} else {
		return -1;
	}
}

void bitcopy(char *dest, int num, int high, int low)
{
	// convert VHDL [7 DOWNTO 0] to array order MSB=0, LSB=7
	int MSB = 7 - high;
	int LSB = 7 - low;
	for (int i = LSB; i >= MSB; i--) { // from LSB to MSB
		// num & 1 = num's LSB (bitwise AND)
		dest[i] = (num & 1) ? '1' : '0';
		num >>= 1;
	}
	if (LSB == 7) dest[8] = '\0';
}
