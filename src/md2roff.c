/**
 * @file md2roff.c
 * @brief wrapper for md2man and md2ms
 * @author Ben O'Neill <ben@oneill.sh>
 *
 * @copyright Copyright (c) 2022-2025 Ben O'Neill <ben@oneill.sh>.
 * This work is released under the terms of the MIT License. See
 * LICENSE.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MD2MS "md2roff -ms"
#define MD2MAN "md2roff -man"

int main(int argc, char *argv[]) {

	if (argc > 1) {
	    if (!strcmp(argv[1], "-ms")) {
	        argv[1] = (char *) malloc(strlen(MD2MS));
			strcpy(argv[1], MD2MS);
	        execvp("md2ms", &argv[1]);
	    } else if (!strcmp(argv[1], "-man")) {
	        argv[1] = (char *) malloc(strlen(MD2MAN));
			strcpy(argv[1], MD2MAN);
	        execvp("md2man", &argv[1]);
	    }
	}

    printf("Usage: %s [-ms|-man] [args]\n", argv[0]);
    return 0;
}
