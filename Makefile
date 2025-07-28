include config.mk

TARGS = md2ms md2man md2roff
MAN = doc/md2ms.1 doc/md2man.1 doc/md2roff.1
SRC = src/md2ms.l src/md2man.l src/md2roff.c src/util.c src/util.h

all: $(TARGS)

gen-examples: all
	$(shell ./md2man < README.md > examples/README.1)
	$(shell ./md2ms -nT README.md | groff -ms -Tpdf > examples/README.pdf)

md2roff:
	$(CC) $(LDFLAGS) -o md2roff src/md2roff.c

md2ms: src/util.o
	$(LEX) -o src/$@_lex.yy.c src/$@.l
	$(CC) $(CFLAGS) -o src/$@_lex.yy.o -c src/$@_lex.yy.c
	$(CC) $(LDFLAGS) $(LIBS) -o $@ src/$@_lex.yy.o $^

md2man: src/util.o
	$(LEX) -o src/$@_lex.yy.c src/$@.l
	$(CC) $(CFLAGS) -o src/$@_lex.yy.o -c src/$@_lex.yy.c
	$(CC) $(LDFLAGS) $(LIBS) -o $@ src/$@_lex.yy.o $^

src/util.o: src/util.c
	$(CC) $(CFLAGS) -o $@ -c $^

clean:
	rm -f md2ms md2man md2roff src/*lex.yy.o src/*lex.yy.c src/util.o md2

dist: clean
	mkdir -p dist
	cp -r doc/ dist/doc
	cp -r src/ dist/src
	cp config.mk LICENSE Makefile README.md dist/
	tar -czf md2roff-$(VERSION).tar.gz -C dist .
	rm -rf dist/

install: md2ms md2man md2roff
	cp md2roff md2ms md2man $(PREFIX)/bin
	cp doc/md2ms.1 doc/md2man.1 doc/md2roff.1 $(DESTDIR)$(MANPREFIX)/man1
	chmod 755 $(DESTDIR)$(PREFIX)/bin/md2roff
	chmod 755 $(DESTDIR)$(PREFIX)/bin/md2ms
	chmod 755 $(DESTDIR)$(PREFIX)/bin/md2man
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/md2roff.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/md2ms.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/md2man.1

test: md2ms md2man
	MD2MAN=$(shell pwd)/md2man MD2MS=$(shell pwd)/md2ms ./test/test.sh

uninstall:
	rm -f $(PREFIX)/bin/md2roff $(PREFIX)/bin/md2ms $(PREFIX)/bin/md2man \
		  $(MANPREFIX)/man1/md2roff.1 $(MANPREFIX)/man1/md2ms.1 \
		  $(MANPREFIX)/man1/md2man.1

.PHONY: all clean dist $(TARGS) install uninstall
