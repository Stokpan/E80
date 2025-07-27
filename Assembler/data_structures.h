#ifndef DATA_STRUCTURES_H
#define DATA_STRUCTURES_H

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

/* Label/value pair, indexed at the LabelElement. */
struct LabelElement {
	char *name;
	unsigned char val;
};

/* Stores an array of pointers to LabelElements; this array is sorted during
the Label collection stage at main() to allow fast binary search. This header
includes the final ram/comment arrays where the translated code is printed. */
struct OutputHeader {
	unsigned char labels;  // number of stored labels
	struct LabelElement label[MAX_LABELS];
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

/* Allocates memory for the label element and points the next index of
the Out.label array to it. Returns the current number of labels. */
int addlabel(const char* name, int value);

/* Sorts the labels array according their linked LabelElement names. */
void sortlabels();

/* Searches 'name' on the LabelElement names, as they are linked with
the sorted labels array, and returns its LabelElement value. */
int labelvalue(const char* name);

/* Moves to the next RAM address, checking for out-of-bounds error. */
void nextaddr();

#endif
