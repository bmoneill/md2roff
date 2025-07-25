VERSION = $(shell (git describe --tags || git rev-parse --short HEAD) 2>/dev/null)

PREFIX = /usr/local
MANPREFIX = $(PREFIX)/share/man

CPPFLAGS =
CFLAGS   = -std=gnu99 -pedantic -Werror -I$(SRCPREFIX) -O2 $(CPPFLAGS)
LDFLAGS  = $(CFLAGS) -s

CC = gcc
LEX = lex
