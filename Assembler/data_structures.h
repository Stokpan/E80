#ifndef DATA_STRUCTURE_H
#define DATA_STRUCTURE_H

#include "config.h"

#define SINGLE_CHAR_DELIMITERS "[\"],:" // ["],:
#define ALL_DELIMITERS "[\"],: \t\n\r\f\v\0" // above + whitespace & terminal

/* Stores a line from the assembly input */
struct LineNode {
	char line[MAX_LINE_LENGTH];
	struct LineNode *next;
};

/* Stores the pointers to the LineNode list, and related variables for
processing assembly input. */
struct InputHeader {
	struct LineNode *front;
	struct LineNode *rear;
	struct LineNode *current;
	char *chr; // tokenization candidate character at current->line
	char token[MAX_LINE_LENGTH];
	char previous[MAX_LINE_LENGTH]; // previous token for error context
	int line_number;
};

/* Symbol/value pair, indexed at the SymbolElement. */
struct SymbolElement {
	char *name;
	unsigned char val;
};

/* Stores an array of pointers to SymbolElements; this array is sorted after
the Symbol collection stage at main() to allow fast binary search. This header
includes the final ram/comment arrays where the translated code is printed. */
struct OutputHeader {
	unsigned char symbols;  // number of stored symbols
	struct SymbolElement symbol[MAX_SYMBOLS];
	unsigned int addr; // current instruction address
	char ram[255][9];
	char comment[255][MAX_LINE_LENGTH];
};

extern struct InputHeader In; // global input data structure
extern struct OutputHeader Out; // global output data structure
#define TOKEN In.token
#define PREVIOUS In.previous
#define RAM Out.ram[Out.addr]
#define COMMENT Out.comment[Out.addr] // advances to next comment with nextaddr()

/* Inserts s in the LineNode list, after the last node. */
void enqueue(const char *s);

/* Resets tokenization variables, moves the current pointer to the
first line, copies the first token to the TOKEN scratchpad and returns
a pointer to the first line. */
char* firstline();

/* Moves the current pointer to the next line, copies the first token to the
TOKEN scratchpad, and returns a pointer to the current line string. After the
last node, returns NULL and requires a call to firstline() to restart. */
char* nextline(void);

/* Moves to the next token in the current line, copies its characters to the
TOKEN scratchpad and returns a pointer to it. After the last token it returns
NULL. */
char* nexttoken(void);

/* Allocates memory of the symbol/name element and points the next index of
the Out.symbol array to it. Returns the current number of symbols. */
int addsymbol(const char* name, int value);

/* Sorts the symbols array according their linked SymbolElement names. */
void sortsymbols();

/* Searches name on the names linked on the symbols array and returns its
SymbolElement value. */
int symbolvalue(const char* name);

/* Moves to the next RAM address, checking for out-of-bounds error. */
void nextaddr();

#endif
