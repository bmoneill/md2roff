#include "util.h"

#include <stddef.h>
#include <stdlib.h>
#include <string.h>

MD2RoffArgs args = {
    .input = NULL,
    .output = NULL,
    .title = NULL,
    .author = NULL,
    .flags = 0
};

CodeBlock codeblock = {
    .buffer = {0},
    .length = 0,
    .active = false
};

FILE *open_file(const char *path, const char *flags) {
	FILE *f = fopen(path, flags);
	if (!f) {
		fprintf(stderr, "Error: Can't open file at path %s\n", path);
		exit(EXIT_FAILURE);
	}
	return f;
}

char *strip_surround(char *str, int len) {
	str[strlen(str) - len] = '\0';
	return strip_whitespace(&str[len]);
}

char *strip_whitespace(char *str) {
	int i;
	for (i = 0; i < strlen(str); i++) {
		if (str[i] != ' ' && str[i] != '\t')
			return &str[i];
	}
	return NULL;
}
