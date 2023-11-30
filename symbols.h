/* $Id$ */

/*
 *  (C) Copyright 2003-2023 Wojtek Kaniewski <wojtekka@toxygen.net>
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

#ifndef __SYMBOLS_H
#define __SYMBOLS_H

enum {
	CONST = 0,		/* constant */
	LABEL = 1,		/* label */
	BIT = 2,		/* bit address in internal RAM */
	DATA = 3		/* byte address in internal RAM */
};

struct symbol
{
	char *name;		/* symbol name */
	int value;		/* symbol value */
	int defined;		/* is the symbol defined? */
	int type;		/* symbol type */

	struct symbol *next;
};

extern struct symbol *symbols;

void symbol_default(void);
struct symbol *symbol_find(const char *name);
struct symbol *symbol_new(const char *name, int type, int value, int defined);


#endif /* __SYMBOLS_H */
