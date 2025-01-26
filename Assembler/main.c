#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "error_handler.h"
#include "data_structures.h"
#include "parse_functions.h"

int main(int argc, char *argv[])
{
	char str[MAX_LINE_LENGTH] = {0}; // scratchpad string
	char instr[MAX_LINE_LENGTH] = {0}; // current instruction
	char title[MAX_LINE_LENGTH] = {0}; // .TITLE string (optional)
	int frequency = DEFAULT_FREQ; // .FREQUENCY value
	char simdip[9] = "00000000"; // .SIMDIP value
	int reg, reg2; // register address
	int n; // scratchpad index or value
	int data_space; // address after the last instruction
	int len, spaces; // formatting helpers
	char* CtrlD = NULL; //
	FILE* asm_input = stdin; // fopen("test.asm", "r");
	FILE* vhdl_template = fopen(TEMPLATE, "r");
	if (!vhdl_template) error(OPEN_TEMPLATE);
	
	/* Starting message (hide if /Q switch is enabled) */
	if (argc < 2 || (strcmp(argv[1],"/Q") && strcmp(argv[1],"/q"))) {
		fprintf(stderr,
			"E80 CPU Assembler v1.0 - July 2025, Panos Stokas\n\n"
			"Translates an E80-assembly program to firmware VHDL code.\n\n"
			"E80ASM [/Q]\n\n"
			"  /Q          Silent mode, hides this message.\n\n"
			"I/O is handled via stdin/stdout. Eg. to read 'program.asm'\n"
			"and write the result to 'firmware.vhd', type:\n\n"
			"e80asm < program.asm > firmware.vhd\n\n"
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

	/* Collect symbols (names and labels).
	Symbol/value pairs are added to the "Out" structure. Error checking is
	minimal in this stage. */
	fprintf(stderr, "Collecting symbols... ");
	Out.addr = 0; // current memory address in the global "Out" structure
	firstline(); // go to the first token of the queued code
	while (In.current) { // read until the last line
		if (eq(TOKEN, ".NAME")) {
			// <directive> ::= ".NAME" <s+> <identifier> <s+> <number>
			strcpy(str, nexttoken()); // <identifier>
			if (!identifier(str)) error(IDENTIFIER);
			n = number(nexttoken()); // <number>
			if (n < 0) error(NUMBER); // error codes = negative values
			addsymbol(str, n); // includes a check for duplicates
		} else if (instr_size1(TOKEN)) {
			nextaddr(); // combines Out.addr++ and ram limit check
		} else if (instr_size2(TOKEN)) {
			nextaddr();
			nextaddr(); // two-word instructions
		} else if (identifier(TOKEN)) {
			// <label> ::= <identifier> <s*> ":"
			strcpy(str, TOKEN);
			if (eq(nexttoken(), ":")) {
				addsymbol(str, Out.addr);
				// check the next token instead of the next line to allow
				// for <codeline> ::= <[label]> <[\n]> <[instruction]>
				nexttoken();
				continue;
			}
		}
		nextline();
	}
	data_space = Out.addr; // for checking collisions with program code

	// print symbol-value pairs prior to sorting
	if (Out.symbols == 0) fprintf(stderr, "None.");
	for (n = 0; n < Out.symbols; n++) {
		fprintf(stderr,
			"\n- %s = %d", Out.symbol[n].name, Out.symbol[n].val);
	}
	fprintf(stderr, "\n");
	sortsymbols(); // sort by name for binary search on symbolvalue()

	/* Parse directives.
	E80 is designed according to the Neumann model where machine code and data
	are stored in the same area. However, .DATA arrays are checked against
	overwriting program code. */
	fprintf(stderr, "Parsing directives... ");
	firstline();
	while (In.current) {
		if (eq(TOKEN, ".TITLE")) {
			// <directive> ::= ".TITLE" <s+> <quoted_string>
			if (title[0]) error(DUPLICATE_TITLE); // previously set
			nexttoken();
			if (TOKEN[0] != '"') error(UNQUOTED_TITLE);
			strncpy(title, TOKEN + 1, strlen(TOKEN) - 2); // unquote
		} else if (eq(TOKEN, ".DATA")) {
			// <directive> ::= ".DATA" <s+> <value> <s+> <array>
			n = value(nexttoken());
			if (n < 0) error(DATA_ADDRESS);
			if (n < data_space) error(DATA_SPACE);
			// write data on the RAM starting from address n
			Out.addr = n;
			do {
				if (!array_element(nexttoken())) error(ARRAY_ELEMENT);
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
		} else if (eq(TOKEN, ".FREQUENCY")) {
			// <directive> ::= ".FREQUENCY" <s+> <number>
			// <number> is an exception here, it's not restricted to 1 byte
			frequency = (int)strtol(nexttoken(), NULL, 10);
			if (frequency < MIN_FREQ || frequency > MAX_FREQ) error(FREQUENCY);
		} else if (eq(TOKEN, ".SIMDIP")) {
			// <directive> ::= ".SIMDIP" <s+> <value>
			bitcopy(simdip, value(nexttoken()), 7, 0);
		} else if (eq(TOKEN, ".NAME")) {
			// already processed during symbol collection
			nexttoken();
			nexttoken();
		} else if (!eq(TOKEN, "")) {
			// a non empty token which is not a directive ⇒ end of directives
			break;
		}
		if (nexttoken()) error(EXTRANEOUS);
		nextline();
	}
	fprintf(stderr, "OK.\n");
	
	/* Parse instructions according to the BNF syntax rules.
	The parser functions (instr_argumentless, instr_n, etc) handle syntax
	checking, translation and write the opcode to the "Out" structure's	array.
	The remaining bits are filled by the code below. The RAM and COMMENT
	macros specify a string element at Out.addr. Each binary instruction is
	followed by a comment with its assembly mnemonic. For two-word instructions
	the first part will not have a comment. Comments therefore are used to
	differentiate between one and two word instructions and allows to create
	well-formatted VHDL code where each instruction is writen in one line. */
	fprintf(stderr, "Parsing instructions... ");
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
			// <[instruction]>  ::= <instr_n> <s+> <n>
			strcpy(instr, TOKEN);
			n = value(nexttoken());
			if (n < 0) error(VALUE);
			nextaddr();
			bitcopy(RAM, n, 7, 0); // <n>
			sprintf(COMMENT, "%s %d", instr, n);
			nextaddr();
		} else if (instr_op1(TOKEN)) {
			// <[instruction]>  ::= <instr_op1> <s+> <op>
			strcpy(instr, TOKEN);
			nexttoken();
			n = value(TOKEN);
			reg = regnum(TOKEN);
			if (n >= 0) {
				// op1 is a direct n address
				strcpy(&RAM[7], "0");
				nextaddr();
				bitcopy(RAM, n, 7, 0); // <n> in Instr2
				sprintf(COMMENT, "%s %d", instr, n);
				nextaddr();
			} else if (reg >= 0) {
				// op1 is a register address
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
			// <[instruction]>  ::= <instr_reg_op2> <s+> <reg> <,> <op2>
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
				// op2 is an immediate n value
				bitcopy(RAM, reg, 3, 0); // <reg> in Instr1[3:0]
				nextaddr();
				bitcopy(RAM, n, 7, 0); // <n> in Instr2
				sprintf(COMMENT, "%s%d", str, n);
			} else if (reg2 >= 0) {
				// op2 is a register address (reg2)
				strcpy(&RAM[4], "1000");
				nextaddr();
				bitcopy(RAM, reg, 7, 4); // <reg> in Instr2[7:4]
				bitcopy(RAM, reg2, 3, 0); // <reg2> in Instr2[3:0]
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
			// <[instruction]>  ::= <instr_reg_n> <s+> <reg> <,> <n>
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
			sprintf(COMMENT, "%s R%d, %d", instr, reg, n);
			nextaddr();
		} else if (symbolvalue(TOKEN) >= 0) {
			// <[label]> ::= <identifier> <s*> ":" | ""
			if (!eq(nexttoken(), ":")) error(COLON);
			nexttoken();
			continue;
		} else if (!eq(TOKEN, "")) {
			error(UNKNOWN);
		}
		if (nexttoken()) error(EXTRANEOUS);
		nextline();
	}
	fprintf(stderr, "OK.\n\n");

	/* Print the converted VHDL code using the template file.
	Each instruction reserves one line, followed by a comment specifying the
	original mnemonic (in which references to symbols have been translated
	to specific values or addresses). Title and frequency are also printed
	on their specific placeholders. */
	while (fgets(str, MAX_LINE_LENGTH, vhdl_template) != NULL) {
		if (strstr(str, "E80 Firmware")) {
			if (!eq(title,"")) {
				printf("-- %s\n", title);
			} else {
				printf(str);
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
				if (len < 15) {
					// space after the address in the 1st part of the line
					// this allows for 1-3 address digits
					spaces = 4 - len;
				} else {
					// space after the address in the 2nd part of the line
					spaces = 23 - len;
				}
				// write the VHDL assignment of the word after the address
				sprintf(str + len, "%*c=> \"%s\", ", spaces, ' ', RAM);
				if (!eq(COMMENT, "")) {
					// comments are written after single-word instructions
					// or after the 2nd part of two-word instructions
					len = strlen(str);
					// streamline comments for both instruction types
					spaces = 39 - len;
					sprintf(str + len, "%*c-- %s", spaces, ' ', COMMENT);
					puts(str);
					str[0] = 0; // prepare for new line
				}
			}
		} else {
			printf(str); // unmodified template lines
		}
	}

	return NO_ERROR;
}
