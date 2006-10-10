# $Id$

prefix = $(DESTDIR)/usr/local
bindir = $(prefix)/bin
mandir = $(prefix)/share/man
datadir = $(prefix)/share/asm51

CC = gcc
NAME = asm51
VERSION = 0.2
OBJS = main.o parser.o lexer.o xmalloc.o output.o symbols.o
CFLAGS = -Wall -O2 -ggdb -DDATADIR=\"$(datadir)\"
BISON = bison
FLEX = flex
INSTALL = install
STRIP = strip
FILES = Makefile lexer.l main.[ch] parser.y output.[ch] symbols.[ch] xmalloc.[ch] asm51.1 asm51.pl.1 README mod51

all:	$(NAME)

$(NAME):	$(OBJS)
	$(CC) $(OBJS) -o $(NAME)

parser.c:	parser.y
	$(BISON) -d parser.y -o parser.c

lexer.c:	lexer.l
	$(FLEX) -i -olexer.c lexer.l

.PHONY:	install clean checkin strip tarball

strip:	$(NAME)
	$(STRIP) $(NAME) || true

install:	$(NAME)
	$(INSTALL) -d $(bindir)
	$(INSTALL) $(NAME) $(bindir)
	$(INSTALL) -d $(mandir)/man1
	$(INSTALL) -d $(mandir)/pl/man1
	$(INSTALL) -m 0644 asm51.1 $(mandir)/man1
	$(INSTALL) -m 0644 asm51.pl.1 $(mandir)/pl/man1/asm51.1
	$(INSTALL) -d $(datadir)
	$(INSTALL) -m 0644 mod51 $(datadir)

clean:
	rm -f *.o *.wo core $(NAME) lexer.c parser.[ch]

checkin:	clean
	ci -l -m. $(FILES)

tarball:	clean
	mkdir /tmp/asm51-$(VERSION)
	cp $(FILES) /tmp/asm51-$(VERSION)
	cd /tmp; tar zcvf $(PWD)/asm51-$(VERSION).tar.gz asm51-$(VERSION)
	rm -rf /tmp/asm51-$(VERSION)

