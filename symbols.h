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

#ifndef __SYMBOLS_H
#define __SYMBOLS_H

enum {
	CONST = 0,		/* sta³a liczbowa */
	LABEL = 1,		/* etykieta */
	BIT = 2,		/* adres bit w wewnêtrznej pamiêci danych */
	DATA = 3		/* adres bajtu w wewnêtrznej pamiêci danych */
};

struct symbol
{
	char *name;		/* nazwa symbolu */
	int value;		/* warto¶æ */
	int defined;		/* czy jest zdefiniowany? */
	int type;		/* typ symbolu */

	struct symbol *next;
};

struct symbol *symbols;

void symbol_default();
struct symbol *symbol_find(const char *name);
struct symbol *symbol_new(const char *name, int type, int value, int defined);


struct macro
{
	char *name;		/* nazwa makra */
	char *value;		/* tre¶æ makra */

	struct macro *next;
};

struct macro *macros;

struct macro *macro_find(const char *name);
struct macro *macro_new(const char *name, const char *value);
void macro_free();

#endif /* __SYMBOLS_H */
