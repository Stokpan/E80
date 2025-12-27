// Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "config.h"
#include "error_handler.h"
#include "data_structures.h"
#include "parse_functions.h"

struct InputHeader In = {0};
struct OutputHeader Out = {0};

void enqueue(const char* s)
{
	struct LineNode* new = malloc(sizeof(*new));
	if (!new) error(MEMORY_ALLOCATION_ERROR);
	// copy the string parameter to the reserved memory space
	strncpy(new->line, s, MAX_LINE_LENGTH);
	new->line[MAX_LINE_LENGTH - 1] = '\0'; // terminate, just to be sure
	new->next = NULL;
	if (!In.front) {
		In.front = new;
	} else {
		In.rear->next = new;
	}
	In.rear = new;
}

char* firstline(void)
{
	In.line_number = 0;
	In.chr = NULL;
	In.token[0] = '\0';
	return nextline(); // process the first line (and get the first token)
}

char* nextline(void)
{
	if (In.line_number == 0) {
		In.current = In.front;
	} else if (In.line_number > 0) {
		In.current = In.current->next;
	}

	if (In.current == NULL) {
		In.line_number = -1; // require restart by firstline() at this point
		In.chr = NULL;
	} else {
		In.line_number++;
		In.chr = In.current->line;
	}
	nexttoken();
	return In.chr;
}

char* nexttoken(void)
{
	// In.chr++ ⇒ advances to next character
	// *In.chr == '\\' && In.chr[1] == '"' ⇒ escaped quoted \" found
	// In.token[i++] = *In.chr++ ⇒ copies current character, and then advances

	strcpy(In.previous, In.token); // useful for error message context
	/* Token character index; declared as unsigned char because of its
	practical 255 limit. */
	unsigned char i = 0; // token character index
	In.token[0] = '\0';
	// all lines/tokens were processed or line is empty
	if (In.chr == NULL) return NULL;
	if (*In.chr == '\0') return NULL;
	while (isspace(*In.chr)) In.chr++; // skip leading whitespace
	if (*In.chr == '"') {
		// copy all quoted text, including the quotes
		In.token[i++] = *In.chr++; // opening quote
		while (*In.chr && *In.chr != '"') { // until closing quote or terminal
			if (*In.chr == '\\' && In.chr[1] == '"') In.chr++; // escaped quote
			In.token[i++] = *In.chr++;
		}
		if (*In.chr == '\0') error(UNCLOSED_STRING); // no closing quote found
		In.token[i++] = *In.chr++; // closing quote
	} else if (strchr(SINGLE_CHAR_DELIMITERS, *In.chr)) {
		// copy a single-character delimiter
		In.token[i++] = *In.chr++;
	} else {
		// copy all characters until hitting a delimiter or terminal
		while (!strchr(ALL_DELIMITERS, *In.chr)) In.token[i++] = *In.chr++;
	}
	In.token[i] = '\0'; // i++ was performed after the last copy
	return In.token;
}

int addlabel(const char* name, int value)
{
	if (Out.labels >= MAX_LABELS) error(MANY_LABELS);
	Out.label[Out.labels].name = malloc(strlen(name) +1); // +1 = terminator
	if (!Out.label[Out.labels].name) error(MEMORY_ALLOCATION_ERROR);
	strcpy(Out.label[Out.labels].name, name);
	Out.label[Out.labels].val = (unsigned char)value;
	Out.labels++;
	return Out.labels;
}

/* Compares the name field of LabelElement pointers a and b.
nameA > nameB ≡ 1, nameA < nameB ≡ -1, nameA = nameB ≡ 0. */
int comparelabels(const void* a, const void* b)
{
	char* nameA = ((struct LabelElement*)a)->name;
	char* nameB = ((struct LabelElement*)b)->name;
	return strcmp(nameA, nameB);
}

void sortlabels(void)
{
	qsort(
		Out.label, Out.labels, sizeof(struct LabelElement), comparelabels);
}

int findlabel(const char* name)
{
	struct LabelElement key = {.name = (char*)name};
	struct LabelElement* found = (struct LabelElement*) bsearch(
		&key, Out.label, Out.labels, sizeof(Out.label[0]), comparelabels);
	
	if (!found) return -1;
	// use pointer arithmetic to calculate the index by the distance
	// of the found element from the base address of the array
	int i = (int)(found - Out.label);
	// check for duplicates
	if (i > 0 && strcmp(Out.label[i-1].name, name) == 0)
		error(DUPLICATE_LABEL);
	if (i < Out.labels - 1 && strcmp(Out.label[i+1].name, name) == 0)
		error(DUPLICATE_LABEL);
	return i;
}

void nextaddr(void)
{
	Out.addr++;
	if (Out.addr > RAM_SIZE) error(RAM_LIMIT);
}
