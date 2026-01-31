// Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
// Error handler functions

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
		"3) Decimal 0-255 with no leading zeroes (eg. 15)\n"
		"Signed minimum is -128, -0b10000000, -0x80\n");
}

void printf_number_error(const char *s) {
	if (number(s) == HEX_ERROR) {
		fprintf(stderr,
			"Hexadecimals are limited to 2 digits (eg. 0xF or 0x1A).");
	} else if (number(s) == BIN_ERROR) {
		fprintf(stderr, "Binaries are limited to 8 digits (eg. 0b00101011).");
	} else if (number(s) == OCTAL_ERROR) {
		fprintf(stderr, "Leading zeroes are not allowed on decimal numbers.");
	} else if (number(s) == SIGNED_RANGE_ERROR) {
		fprintf(stderr, "Signed minimum is -128.");
	} else if (number(s) == RANGE_ERROR) {
		fprintf(stderr, "Unsigned numbers are limited to 0-255,");
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
			fprintf(stderr, "Expected an array element.");
		} else if (number(TOKEN) != NUMBER_ERROR) {
			printf_number_error(TOKEN);
		} else {
			fprintf(stderr, "'%s' is not a literal.\n", TOKEN);
			fprintf(stderr, "Example of an array: .DATA str 12, \"abc\", 0xAF, 0b1011.");
		}
		break;
	case SPEED:
		fprintf(stderr, "Speed must be between '%d' and '%d'.", MIN_SPEED, MAX_SPEED);
		break;
	case NUMBER:
		fprintf(stderr, "'%s' is not a valid number.\n", TOKEN);
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
		fprintf(stderr, "'%s' was unexpected.", TOKEN);
		break;
	case DIRECTIVE:
		fprintf(stderr, "'%s' is not a directive.", TOKEN);
		break;
	case INSTRUCTION_LABEL:
		fprintf(stderr, "'%s' is no instruction or label.", TOKEN);
		break;
	case INSTRUCTION_COLON:
		fprintf(stderr, "'%s' is no instruction, or missing a colon.", PREVIOUS);
		break;
	case INSTRUCTION:
		fprintf(stderr, "'%s' is no instruction.", TOKEN);
		break;
	case RESERVED:
		fprintf(stderr, "'%s' is reserved and cannot be used here.", TOKEN);
		break;
	case REGISTER:
		if (eq(TOKEN, "")) {
			fprintf(stderr,"Expected register after '%s'.", PREVIOUS);
		} else {
			fprintf(stderr, "'%s' is not a register.", TOKEN);
		}
		break;
	case VALUE:
		fprintf(stderr, "'%s' is not a number or label\n", TOKEN);
		printf_number_error(TOKEN);
		break;
	case COMMA:
		fprintf(stderr, "Comma expected after '%s'.", PREVIOUS);
		break;
	case LEFTBRACKET:
		fprintf(stderr, "LOAD/STORE requires a left bracket before '%s'.", TOKEN);
		break;
	case RIGHTBRACKET:
		fprintf(stderr, "LOAD/STORE requires a right bracket after '%s'.", PREVIOUS);
		break;
	case OP:
		if (eq(TOKEN, "")) {
			fprintf(stderr,"Expected number, label or register after comma.");
		} else {
			fprintf(stderr, "'%s' is not a number, label or register.\n", TOKEN);
			printf_number_error(TOKEN);
		}
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
