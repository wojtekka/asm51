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

#ifndef __OUTPUT_H
#define __OUTPUT_H

int pass;				/* numer przebiegu (1 lub 2) */

int emit_pc;				/* tylko od odczytu */
void emit_init();
void emit_pc_inc(int count);
void emit_pc_set(int offset);
void emit_byte(unsigned char b);
void emit_word(unsigned short w);
void emit_dword(unsigned long d);
void emit_string(const char *s);
void emit_hex(const char *filename);
void emit_bin(const char *filename);

#endif /* __OUTPUT_H */
