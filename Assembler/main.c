// Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "error_handler.h"
#include "data_structures.h"
#include "parse_functions.h"

int main(int argc, char *argv[])
{
	fprintf(stderr, "Assembling... ");
	
	char str[MAX_LINE_LENGTH] = {0}; // scratchpad string
	char instr[MAX_LINE_LENGTH] = {0}; // current instruction
	char title[MAX_LINE_LENGTH] = {0}; // .TITLE string (optional)
	int frequency = DEFAULT_FREQ; // .FREQUENCY value
	char simdip[9] = "00000000"; // .SIMDIP value
	int reg, reg2; // register address
	int n; // scratchpad index or value
	int len, spaces; // formatting helpers
	char* CtrlD = NULL; // check if Ctrl+D is pressed
	FILE* asm_input = stdin; // fopen("test.e80asm", "r");
	FILE* vhdl_template = fopen(TEMPLATE, "r");
	if (!vhdl_template) error(OPEN_TEMPLATE);
	
	/* Starting message (hide if /Q switch is enabled) */
	if (argc < 2 || (strcmp(argv[1],"/Q") && strcmp(argv[1],"/q"))) {
		fprintf(stderr,
			"E80 CPU Assembler v1.7 - January 2026, Panos Stokas\n\n"
			"Translates an E80-assembly program to firmware VHDL code.\n\n"
			"E80ASM [/Q]\n\n"
			"  /Q          Silent mode, hides this message.\n\n"
			"I/O is handled via stdin/stdout. Eg. to read 'program.e80asm'\n"
			"and write the result to 'firmware.vhd', type:\n\n"
			"e80asm < program.e80asm > firmware.vhd\n\n"
			"You can also paste your code here and then press\n"
			"Ctrl-D & [Enter] to translate it, or Ctrl-C to exit.\n\n");
	}

	/* Read lines from stdin until EOF or end-of-transmit (Ctrl-D). */
	while (!CtrlD && fgets(str, MAX_LINE_LENGTH, asm_input)) {
		 if ((CtrlD = strchr(str, 4))) { // end of transmit found
			*CtrlD = 0; // replace end of transmit with terminal
		} else if (!strchr(str, '\n') && !feof(asm_input)) {
			// a line without a newline character, is either the last line or
			// it exceeds the maximum supported size.
			error(MAX_LENGTH_EXCEEDED);
		}
		trim(str); // trim whitespace and comments
		enqueue(str); // store the line in the global "In" structure
	}

	/* Collect labels (symbols).
	Label/value pairs are added to the "Out" structure. Error checking is
	minimal in this stage. */
	Out.addr = 0; // current memory address in the global "Out" structure
	firstline(); // go to the first token of the queued code
	while (In.current) { // read until the last line
		if (eq(TOKEN, ".LABEL")) {
			// <directive> ::= ".LABEL" <s+> <label> <s+> <number>
			strcpy(str, nexttoken()); // <label>
			if (!label(str)) error(LABEL);
			n = number(nexttoken()); // <number>
			if (n < 0) error(NUMBER); // error codes = negative values
			addlabel(str, n);
		} else if (eq(TOKEN, ".DATA")) {
			// <directive> ::= ".DATA" <s+> <label> <s+> <array>
			strcpy(str, nexttoken()); // <label>
			if (!label(str)) error(LABEL);
			addlabel(str, 0); // data labels are calculated in the next stage
		} else if (instr_size1(TOKEN)) {
			nextaddr(); // combines Out.addr++ and ram limit check
		} else if (instr_size2(TOKEN)) {
			nextaddr();
			nextaddr(); // two-word instructions
		} else if (label(TOKEN)) {
			// consequtive labels are not allowed
			if (Out.labels > 0 && Out.label[Out.labels-1].val == Out.addr) {
				error(INSTRUCTION);
			}
			strcpy(str, TOKEN);
			// catch missing colons now, otherwise most instruction typos
			// will be regarded as labels, causing syntactically correct
			// but misleading errors at use sites during the second pass
			if (!eq(nexttoken(), ":")) error(INSTRUCTION_COLON);
			addlabel(str, Out.addr);
			// check the next token instead of the next line to process
			// <label:> <instruction> cases
			nexttoken();
			continue;
		}
		nextline();
	}
	
	sortlabels(); // to allow bsearch in findlabel

	/* Parse directives.
	E80 is designed according to the Neumann model where machine code and data
	are stored in the same area. However, .DATA arrays are checked against
	overwriting program code. */
	firstline();
	while (In.current) {
		if (eq(TOKEN, ".TITLE")) {
			// <directive> ::= ".TITLE" <s+> <quoted_string>
			if (title[0]) error(DUPLICATE_TITLE); // previously set
			nexttoken();
			if (TOKEN[0] != '"') error(UNQUOTED_TITLE);
			strncpy(title, TOKEN + 1, strlen(TOKEN) - 2); // unquote
		} else if (eq(TOKEN, ".FREQUENCY")) {
			// <directive> ::= ".FREQUENCY" <s+> <number>
			// <number> is an exception here, it's not restricted to 1 byte
			frequency = (int)strtol(nexttoken(), NULL, 10);
			if (frequency < MIN_FREQ || frequency > MAX_FREQ) error(FREQUENCY);
		} else if (eq(TOKEN, ".SIMDIP")) {
			// <directive> ::= ".SIMDIP" <s+> <value>
			bitcopy(simdip, value(nexttoken()), 7, 0);
		} else if (eq(TOKEN, ".LABEL")) {
			findlabel(nexttoken()); // includes dupe checking
			nexttoken(); // number was checked during symbol collection
		} else if (eq(TOKEN, ".DATA")) {
			// <directive> ::= ".DATA" <s+> <label> <s+> <array>
			Out.label[findlabel(nexttoken())].val = Out.addr;
			do {
				nexttoken();
				if (!array_element(TOKEN)) error(ARRAY_ELEMENT);
				// <array_element> ::= <number> | <quoted_string>
				if (TOKEN[0] != '"') {
					// <number>, write on the RAM as 8 bits
					bitcopy(RAM, value(TOKEN), 7, 0);
					// add the original number as a comment
					sprintf(COMMENT, "%s", TOKEN);
					nextaddr();
				} else {
					// <quoted_string> ::= "\"" <char+> "\""
					// skip quotes and write each character's ASCII
					// value on the RAM as 8 bits
					for (unsigned int i = 1; i < strlen(TOKEN) -1; i++) {
						bitcopy(RAM, (int)TOKEN[i], 7, 0);
						// add each character as a comment
						sprintf(COMMENT, "'%c' (%d)", TOKEN[i], TOKEN[i]);
						nextaddr();
					}
				}
				// <array> ::= <array_element> | <array_element> <,> <array>
			} while (eq(nexttoken(), ","));
			if (!eq(TOKEN, "")) error(COMMA);
		} else if (TOKEN[0] == '.') {
			error(DIRECTIVE);
		} else if (!eq(TOKEN, "")) {
			// a non empty token which is not a directive ⇒ end of directives
			break;
		}
		if (nexttoken()) error(EXTRANEOUS);
		nextline();
	}
	
	/* Parse instructions according to the BNF syntax rules.
	The parser functions (instr_argumentless, instr_n, etc) handle syntax
	checking, translation and write the opcode to the "Out" structure's	array.
	The remaining bits are filled by the code below. The RAM and COMMENT
	macros specify a string element at Out.addr. Each binary instruction is
	followed by a comment with its assembly mnemonic. For two-word instructions
	the first part will not have a comment. Comments therefore are used to
	differentiate between one and two word instructions and allows to create
	well-formatted VHDL code where each instruction is writen in one line. */
	Out.addr = 0;
	while (In.current) {
		if ((instr_noarg(TOKEN))) {
			// <[instruction]> ::= <instr_noarg>
			sprintf(COMMENT, "%s", TOKEN);
			nextaddr();
		} else if (instr_reg(TOKEN)) {
			// <[instruction]> ::= <instr_reg> <s+> <reg>
			strcpy(instr, TOKEN);
			reg = regnum(nexttoken());
			if (reg < 0) error(REGISTER);
			bitcopy(RAM, reg, 2, 0); // <reg> in Instr1[2:0]
			sprintf(COMMENT, "%s R%d", instr, reg);
			nextaddr();
		} else if (instr_n(TOKEN)) {
			// <[instruction]>  ::= <instr_n> <s+> <value>
			strcpy(instr, TOKEN);
			n = value(nexttoken());
			if (n < 0) error(VALUE);
			nextaddr();
			bitcopy(RAM, n, 7, 0); // <value>
			sprintf(COMMENT, "%s %d", instr, n);
			nextaddr();
		} else if (instr_op1(TOKEN)) {
			// <[instruction]>  ::= <instr_op1> <s+> <op>
			strcpy(instr, TOKEN);
			nexttoken();
			n = value(TOKEN);
			reg = regnum(TOKEN);
			if (n >= 0) {
				// op1 = <value>
				strcpy(&RAM[7], "0");
				nextaddr();
				bitcopy(RAM, n, 7, 0); // <number> in Instr2
				sprintf(COMMENT, "%s %d", instr, n);
				nextaddr();
			} else if (reg >= 0) {
				// op1 = <reg>
				strcpy(&RAM[7], "1");
				nextaddr();
				strcpy(&RAM[0], "00000");
				bitcopy(RAM, reg, 3, 0); // <reg> in Instr2[2:0]
				sprintf(COMMENT, "%s R%d", instr, reg);
				nextaddr();
			} else {
				error(OP);
			}
		} else if (instr_reg_op2(TOKEN)) {
			// <instruction> ::= <instr_reg_op2> <s+> <reg> <,> <op2>
			char bracket_op2 = load_store(TOKEN); // op2 must be bracketed
			strcpy(instr, TOKEN);
			reg = regnum(nexttoken());
			if (reg < 0) error(REGISTER);
			if (!eq(nexttoken(), ",")) error(COMMA);
			str[0] = 0; // clear scratchpad string
			sprintf(str, "%s R%d, ", instr, reg);
			nexttoken();
			if (bracket_op2) {
				if (!eq(TOKEN,"[")) error(LEFTBRACKET);
				sprintf(str+strlen(str),"[");
				nexttoken();
			}
			n = value(TOKEN);
			reg2 = regnum(TOKEN);
			if (n >= 0) {
				// op2 = <value>
				bitcopy(RAM, reg, 3, 0); // <reg> in Instr1[3:0]
				nextaddr();
				bitcopy(RAM, n, 7, 0); // <number> in Instr2
				if (n < 128 || bracket_op2) {
					sprintf(COMMENT, "%s%d", str, n);
				} else {
					// signed equivalent for non-address
					sprintf(COMMENT, "%s%d (-%d)", str, n, 256-n);
				}
			} else if (reg2 >= 0) {
				// op2 = <reg>
				strcpy(&RAM[4], "1000");
				nextaddr();
				bitcopy(RAM, reg, 7, 4); // <reg> in Instr2[7:4]
				bitcopy(RAM, reg2, 3, 0); // <reg> (op2) in Instr2[3:0]
				sprintf(COMMENT, "%sR%d", str, reg2);
			} else {
				error(OP);
			}
			if (bracket_op2) {
				if (!eq(nexttoken(),"]")) error(RIGHTBRACKET);
				sprintf(COMMENT+strlen(COMMENT), "]");
			}
			nextaddr();
		} else if (instr_reg_n(TOKEN)) {
			// <instruction> ::= <instr_reg_n> <s+> <reg> <,> <value>
			strcpy(instr, TOKEN);
			reg = regnum(nexttoken());
			if (reg < 0) error(REGISTER);
			if (!eq(nexttoken(), ",")) error(COMMA);
			nexttoken();
			n = value(TOKEN);
			if (n < 0) error(VALUE);
			bitcopy(RAM, reg, 2, 0);
			nextaddr();
			bitcopy(RAM, n, 7, 0);
			if (n < 128) {
				sprintf(COMMENT, "%s R%d, %d", instr, reg, n);
			} else {
				// signed equivalent
				sprintf(COMMENT, "%s R%d, %d (-%d)", instr, reg, n, 256-n);
			}
			nextaddr();
		} else if (findlabel(TOKEN) != -1) { // includes dupe checking
			// label syntax was checked during symbol collection
			nexttoken();
			nexttoken();
			continue;
		} else if (!eq(TOKEN, "")) {
			error(INSTRUCTION_LABEL);
		}
		if (nexttoken()) error(EXTRANEOUS);
		nextline();
	}

	/* Print the converted VHDL code using the template file.
	Each instruction reserves one line, followed by a comment specifying the
	instruction in hex and the disassembled mnemonic.
	Title and frequency are also printed on their specific placeholders. */
	char hex[5] = {0}; // bin to hex conversion string (max 4 digits)
	while (fgets(str, MAX_LINE_LENGTH, vhdl_template) != NULL) {
		if (strstr(str, "TITLE_PLACEHOLDER")) {
			printf("-- ");
			if (!eq(title,"")) {
				printf("%s\n", title);
			} else {
				printf("%s\n", DEFAULT_TITLE);
			}
		} else if (strstr(str, "DefaultFrequency")) {
			printf(str, frequency); // template contains %d specifier
		} else if (strstr(str, "SimDIP")) {
			printf(str, simdip); // template contains %s specifier
		} else if (strstr(str, "MACHINE_CODE_PLACEHOLDER")) {
			str[0] = 0; // clear scratchpad string
			for (Out.addr = 0; Out.addr < RAM_SIZE; Out.addr++) {
				if (eq(RAM, "")) continue; // handled by OTHERS in VHDL
				len = strlen(str);
				/* Write the instruction address in the end of the current
				line; this allows for two-word instructions to have
				both parts in the same line, such as:
				addr => "instr1", addr+1 => "instr2" -- comment
				or, for single-word instructions:
				addr => "instr1",                    -- comment. */
				sprintf(str + len, "%d", Out.addr);
				len = strlen(str);
				n = (unsigned) strtoul(RAM, NULL, 2); // for the hex conversion
				if (len < 15) {
					// space after the address in the 1st part of the line
					// this allows for 1-3 address digits
					spaces = 4 - len;
					// write the hexadecimal conversion of the binary instruction
					// or "data" if the word is from .DATA
					if (COMMENT[0] && COMMENT[0] < 57) {
						// comment is data (starts from quote or number)
						strcpy(hex,"data");
					} else {
						sprintf(hex, "%02X", n); // instr1 to hex part of comment
					}
				} else {
					// space after the address in the 2nd part of the line
					spaces = 23 - len;
					sprintf(hex + 2, "%02X", n); // instr2 to hex part of comment
				}
				// write the VHDL assignment of the word after the address
				sprintf(str + len, "%*c=> \"%s\", ", spaces, ' ', RAM);
				// write the hex conversion of the instruction part
				if (!eq(COMMENT, "")) {
					// comments are written after single-word instructions
					// or after the 2nd part of two-word instructions
					len = strlen(str);
					// streamline comments for both instruction types
					spaces = 39 - len;
					sprintf(str + len, "%*c-- %-6s%s", spaces, ' ', hex, COMMENT);
					puts(str);
					str[0] = 0; // prepare for new line
					hex[0] = 0; // prepare for new hex conversion
				}
			}
		} else {
			printf(str); // unmodified template lines
		}
	}

	fprintf(stderr, "Done.\n");
	return NO_ERROR;
}
