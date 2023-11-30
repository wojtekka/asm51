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

#include <string.h>
#include "main.h"
#include "symbols.h"
#include "xmalloc.h"

struct symbol *symbols;
struct macro *macros;

/*
 * symbol_find()
 *
 * szuka definicji symbolu o podanej nazwie.
 */
struct symbol *symbol_find(const char *name)
{
	struct symbol *i;

	for (i = symbols; i; i = i->next)
		if (!strcasecmp(i->name, name))
			return i;

	return NULL;
}

/*
 * symbol_new()
 *
 * dodaje nowy symbol do listy.
 */
struct symbol *symbol_new(const char *name, int value, int type, int defined)
{
	struct symbol *i = xmalloc(sizeof(struct symbol)), *last;

	for (last = symbols; last && last->next; last = last->next)
		;

	i->name = xstrdup(name);
	i->defined = defined;
	i->value = value;
	i->type = type;
	i->next = NULL;

	if (!last)
		symbols = i;
	else
		last->next = i;

	return i;
}

/*
 * symbols_default()
 *
 * dodaje domy¶lne symbole dla 8051.
 */
void symbol_default(void)
{
	symbol_new("P0", 0x80, DATA, 1);
	symbol_new("SP", 0x81, DATA, 1);
	symbol_new("DPL", 0x82, DATA, 1);
	symbol_new("DPH", 0x83, DATA, 1);
	symbol_new("PCON", 0x87, DATA, 1);
	symbol_new("TCON", 0x88, DATA, 1);
	symbol_new("TMOD", 0x89, DATA, 1);
	symbol_new("TL0", 0x8a, DATA, 1);
	symbol_new("TL1", 0x8b, DATA, 1);
	symbol_new("TH0", 0x8c, DATA, 1);
	symbol_new("TH1", 0x8d, DATA, 1);
	symbol_new("P1", 0x90, DATA, 1);
	symbol_new("SCON", 0x98, DATA, 1);
	symbol_new("SBUF", 0x99, DATA, 1);
	symbol_new("P2", 0xa0, DATA, 1);
	symbol_new("IE", 0xa8, DATA, 1);
	symbol_new("P3", 0xb0, DATA, 1);
	symbol_new("IP", 0xb8, DATA, 1);
	symbol_new("PSW", 0xd0, DATA, 1);
	symbol_new("ACC", 0xe0, DATA, 1);
	symbol_new("B", 0xf0, DATA, 1);

	symbol_new("IT0", 0x88+0, BIT, 1);
	symbol_new("IE0", 0x88+1, BIT, 1);
	symbol_new("IT1", 0x88+2, BIT, 1);
	symbol_new("IE1", 0x88+3, BIT, 1);
	symbol_new("TR0", 0x88+4, BIT, 1);
	symbol_new("TF0", 0x88+5, BIT, 1);
	symbol_new("TR1", 0x88+6, BIT, 1);
	symbol_new("TF1", 0x88+7, BIT, 1);

	symbol_new("RI", 0x98+0, BIT, 1);
	symbol_new("TI", 0x98+1, BIT, 1);
	symbol_new("RB8", 0x98+2, BIT, 1);
	symbol_new("TB8", 0x98+3, BIT, 1);
	symbol_new("REN", 0x98+4, BIT, 1);
	symbol_new("SM2", 0x98+5, BIT, 1);
	symbol_new("SM1", 0x98+6, BIT, 1);
	symbol_new("SM0", 0x98+7, BIT, 1);

	symbol_new("EX0", 0xa8+0, BIT, 1);
	symbol_new("ET0", 0xa8+1, BIT, 1);
	symbol_new("EX1", 0xa8+2, BIT, 1);
	symbol_new("ET1", 0xa8+3, BIT, 1);
	symbol_new("ES", 0xa8+4, BIT, 1);
	symbol_new("EA", 0xa8+7, BIT, 1);

	symbol_new("RXD", 0xb0+0, BIT, 1);
	symbol_new("TXD", 0xb0+1, BIT, 1);
	symbol_new("INT0", 0xb0+2, BIT, 1);
	symbol_new("INT1", 0xb0+3, BIT, 1);
	symbol_new("T0", 0xb0+4, BIT, 1);
	symbol_new("T1", 0xb0+5, BIT, 1);
	symbol_new("WR", 0xb0+6, BIT, 1);
	symbol_new("RD", 0xb0+7, BIT, 1);

	symbol_new("PX0", 0xb8+0, BIT, 1);
	symbol_new("PT0", 0xb8+1, BIT, 1);
	symbol_new("PX1", 0xb8+2, BIT, 1);
	symbol_new("PT1", 0xb8+3, BIT, 1);
	symbol_new("PS", 0xb8+4, BIT, 1);
	
	symbol_new("P", 0xd0+0, BIT, 1);
	symbol_new("OV", 0xd0+2, BIT, 1);
	symbol_new("RS0", 0xd0+3, BIT, 1);
	symbol_new("RS1", 0xd0+4, BIT, 1);
	symbol_new("F0", 0xd0+5, BIT, 1);
	symbol_new("AC", 0xd0+6, BIT, 1);
	symbol_new("CY", 0xd0+7, BIT, 1);
}

/*
 * macro_find()
 *
 * szuka definicji makra o podanej nazwie.
 */
struct macro *macro_find(const char *name)
{
	struct macro *i;

	for (i = macros; i; i = i->next)
		if (!strcasecmp(i->name, name))
			return i;

	return NULL;
}

/*
 * macro_new()
 *
 * dodaje nowe makro do listy.
 */
struct macro *macro_new(const char *name, const char *value)
{
	struct macro *m = xmalloc(sizeof(struct macro)), *last;

	for (last = macros; last && last->next; last = last->next)
		;

	m->name = xstrdup(name);
	m->value = xstrdup(value);

	if (!last)
		macros = m;
	else
		last->next = m;

	if (verbosity)
		printf("defining macro %s: %s\n", name, value);

	return m;
}

/*
 * macro_free()
 *
 * zwalnia informacje o makrach.
 */
void macro_free(void)
{
	struct macro *m;

	for (m = macros; m; ) {
		m = m->next;
		xfree(m->name);
		xfree(m->value);
		xfree(m);
	}
}
		
