/* $Id$ */

/*
 *  (C) Copyright 2003 Wojtek Kaniewski <wojtekka@irc.pl>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License Version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __MAIN_H
#define __MAIN_H

#include <stdio.h>

#define NAME "asm51"
#define VERSION "0.1"
#define COPYRIGHT "(C) Copyright 2003 Wojtek Kaniewski <wojtekka@irc.pl>"
#define LICENSE "Released under the terms of the GNU GPL version 2 license"

#define _(s) (s)

FILE *yyin;
int yylex();
int yyparse();
void yyerror(const char *s);
void error(const char *format, ...);
void warning(const char *format, ...);
char *filename;

int lineno;

int verbosity;

#endif /* __MAIN_H */
