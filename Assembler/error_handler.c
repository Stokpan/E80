// Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>

#include <stdio.h>
#include <stdlib.h>
#include "error_handler.h"
#include "data_structures.h"
#include "parse_functions.h"

void printf_number_format_help(void) {
	fprintf(stderr,
		"Numbers can either be:\n"
		"1) Hexadecimal preceded by 0x, up to 2 digits (eg. 0x0F)\n"
		"2) Binary preceded by 0b, up to 8 digits (eg. 0b00001111)\n"
		"3) Decimal 0-255 with no leading zeroes (eg. 15)\n");
}

void printf_val_help(void) {
	if (number(TOKEN) == HEX_ERROR) {
		fprintf(stderr,
			"Hexadecimals are limited to 2 digits (eg. 0xF or 0x1A)\n");
	} else if (number(TOKEN) == BIN_ERROR) {
		fprintf(stderr,
			"Binary numbers are limited to 8 digits (eg. 0b00101011)\n");
	} else if (number(TOKEN) == OCTAL_ERROR) {
		fprintf(stderr, "Leading zeroes are not allowed on decimal numbers\n");
	} else if (number(TOKEN) == RANGE_ERROR) {
		fprintf(stderr, "Decimal numbers are limited to unsigned 0-255");
	} else if (!label(TOKEN)) {
		fprintf(stderr,
			"It contains letters, but labels must start with a letter and"
			" followed by letters, numbers and underscores");
	} else {
		fprintf(stderr,
			"Labels must be defined in .LABEL directives"
			" or between instructions, followed by a colon\n");
	}
}

/* Terminates execution, printing a message and returns an error code. */
void error(enum ErrorCode errorlevel)
{
	fprintf(stderr,	"\n******************************************************\n");
	if (In.line_number) {
		fprintf(stderr,
			"Error in line %d : %s\n", In.line_number, In.current->line);
	}

	switch (errorlevel) {
	case OPEN_TEMPLATE:
		fprintf(stderr, "Error! Can't open the template file '%s'", TEMPLATE);
		break;
	case MAX_LENGTH_EXCEEDED:
		fprintf(stderr, "Line exceeds maximum %d characters.", MAX_LINE_LENGTH);
		break;
	case LABEL:
		fprintf(stderr, "'%s' is not a valid label.", TOKEN);
		break;
	case EMPTY_STRING:
		fprintf(stderr, "Empty strings are not permitted.");
		break;
	case UNCLOSED_STRING:
		fprintf(stderr, "Quote expected after string '%s'.", TOKEN);
		break;
	case ARRAY_ELEMENT:
		if (eq(TOKEN,"")) {
			fprintf(stderr, "Expected an array element.\n");
		} else {
			fprintf(stderr, "'%s' is not a literal.\n", TOKEN);
		}
		fprintf(stderr,
			"Example of an array: .DATA 100 12, \"abc\", 0xAF, 0b1011\n"
			"Quotes can be escaped in strings, eg: \"a\\\"b\"\n");
		printf_number_format_help();
		break;
	case FREQUENCY:
		fprintf(stderr,
			"Frequency must be a number between '%d' and '%d' deciHertz.\n",
			MIN_FREQ, MAX_FREQ);
		break;
	case NUMBER:
		fprintf(stderr, "'%s' is not a number between 0 and 255.\n", TOKEN);
		printf_number_format_help();
		break;
	case MANY_LABELS:
		puts("Maximum number of labels reached");
		break;
	case DUPLICATE_LABEL:
		fprintf(stderr, "This label has been set in a previous line.");
		break;
	case MEMORY_ALLOCATION_ERROR:
		puts("Memory allocation error!");
		break;
	case EXTRANEOUS:
		fprintf(stderr, "'%s' was unexpected", TOKEN);
		break;
	case DIRECTIVE:
		fprintf(stderr, "'%s' is not a directive", TOKEN);
		break;
	case INSTRUCTION_LABEL:
		fprintf(stderr, "'%s' is no instruction or label", TOKEN);
		break;
	case INSTRUCTION_COLON:
		fprintf(stderr, "'%s' is no instruction, or missing a colon", PREVIOUS);
		break;
	case INSTRUCTION:
		fprintf(stderr, "'%s' is no instruction", TOKEN);
		break;
	case RESERVED:
		fprintf(stderr, "'%s' is reserved and cannot be used here", TOKEN);
		break;
	case REGISTER:
		if (eq(TOKEN, "")) {
			fprintf(stderr,"Expected register after '%s'", PREVIOUS);
		} else {
			fprintf(stderr, "'%s' is not a register;"
			" allowed registers are R0-R7", TOKEN);
		}
		break;
	case VALUE:
		fprintf(stderr, "'%s' is not a number or label", TOKEN);
		break;
	case COMMA:
		fprintf(stderr, "Comma expected after '%s'", PREVIOUS);
		break;
	case LEFTBRACKET:
		fprintf(stderr, "LOAD/STORE requires a left bracket before '%s'", TOKEN);
		break;
	case RIGHTBRACKET:
		fprintf(stderr, "LOAD/STORE requires a right bracket"
				" after '%s'", PREVIOUS);
		break;
	case OP:
		if (eq(TOKEN, "")) {
			fprintf(stderr,"Expected number, label or register after comma");
		} else {
			fprintf(stderr, "'%s' is not number, label or register.", TOKEN);
		}
		break;
	case DATA_ADDRESS:
		fprintf(stderr, "'%s' is not a valid address or label.", TOKEN);
		printf_val_help();
		break;
	case DATA_SPACE:
		fprintf(stderr, "'%s' is an address in program code.", TOKEN);
		break;
	case RAM_LIMIT:
		fprintf(stderr, "%d-byte RAM limit exceeded.", RAM_SIZE);
		break;
	case UNQUOTED_TITLE:
		fprintf(stderr, "Quoted title string expected.");
		break;
	case DUPLICATE_TITLE:
		fprintf(stderr, "Only one .TITLE directive is allowed.");
		break;
	default:
		break;
	}
	fprintf(stderr,	"\n******************************************************\n");
	
	exit(errorlevel);
}
