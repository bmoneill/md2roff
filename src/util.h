#ifndef UTIL_H
#define UTIL_H

#include <stdio.h>

FILE *open_file(const char *, const char *);
char *strip_surround(char *, int);
char *strip_whitespace(char *);

#endif
