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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "main.h"

static void out_of_memory(const char *func, size_t size)
{
	fprintf(stderr, "%s(%d): %s\n", func, size, _("out of memory"));
	exit(1);
}

void *xmalloc(size_t size)
{
	void *tmp = malloc(size);

	if (!tmp)
		out_of_memory("malloc", size);

	/* na wszelki wypadek wyczy¶æ bufor */
	memset(tmp, 0, size);
	
	return tmp;
}

void xfree(void *ptr)
{
	if (ptr)
		free(ptr);
}

void *xrealloc(void *ptr, size_t size)
{
	void *tmp = realloc(ptr, size);

	if (!tmp)
		out_of_memory("realloc", size);

	return tmp;
}

char *xstrdup(const char *s)
{
	char *tmp;

	if (!s)
		return NULL;

	if (!(tmp = strdup(s)))
		out_of_memory("strdup", strlen(s) + 1);

	return tmp;
}


