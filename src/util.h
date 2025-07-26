#ifndef UTIL_H
#define UTIL_H

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define MAX_CODEBLOCK_SIZE 65536
typedef struct {
	FILE *input;
	FILE *output;
	char *title;
	char *author;
	uint8_t flags;
} MD2RoffArgs;

typedef struct {
    char buffer[MAX_CODEBLOCK_SIZE];
    size_t length;
    bool active;
} CodeBlock;

FILE *open_file(const char *, const char *);
char *strip_surround(char *, int);
char *strip_whitespace(char *);

extern MD2RoffArgs args;
extern CodeBlock codeblock;

#endif
