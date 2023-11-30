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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "main.h"
#include "output.h"

unsigned char emit_buf[65536], emit_used[8192];
int emit_pc, emit_pc2;
int pass;

#define emit_used_set(i) do { emit_used[(i) >> 3] |= 1 << ((i) & 7); } while(0)
#define emit_used_get(i) (emit_used[(i) >> 3] & (1 << ((i) & 7)))

/*
 * emit_init()
 *
 * inicjalizacja bufora wyj¶ciowego.
 */
void emit_init(void)
{
	emit_pc = emit_pc2 = 0;

	memset(emit_buf, 255, sizeof(emit_buf));
	memset(emit_used, 0, sizeof(emit_used));
}

/*
 * emit_pc_inc()
 *
 * zwiêksza wska¼nik programu o podan± ilo¶æ bajtów.
 */
void emit_pc_inc(int count)
{
	emit_pc += count;
	emit_pc2 = emit_pc;
}

/*
 * emit_pc_set()
 *
 * ustawia wska¼nik programu na podan± warto¶æ.
 */
void emit_pc_set(int offset)
{
	emit_pc = emit_pc2 = offset;
}

/*
 * emit_byte()
 *
 * dopisuje do bufora wyj¶ciowego jeden bajt.
 */
void emit_byte(unsigned char b)
{
	static int warned = 0;

	if (emit_pc2 > 65535)
		error(_("program exceeds 64kB"));

	if (pass == 2) {
		if (emit_used_get(emit_pc2) && warned < 5) {
			warning(_("overlapping code at %.4xh"), emit_pc2);
			warned++;

			if (warned == 5)
				warning(_("(suppressing further warnings)"));
		}

		emit_buf[emit_pc2] = b;
		emit_used_set(emit_pc2);
	}

	emit_pc2++;
}

/*
 * emit_word()
 *
 * dopisuje do bufora wyj¶ciowego jedno s³owo.
 */
void emit_word(unsigned short w)
{
	emit_byte((w & 0xff00) >> 8);
	emit_byte(w & 0x00ff);
}

/*
 * emit_dword()
 *
 * dopisuje do bufora wyj¶ciowego jedno podwójne s³owo.
 */
void emit_dword(unsigned long d)
{
	emit_word((d & 0xffff0000L) >> 16);
	emit_word(d & 0x0000ffffL);
}

/*
 * emit_string()
 *
 * dopisuje do bufora wyj¶ciowego ci±g bajtów zakoñczony bajtem 0.
 */
void emit_string(const char *s)
{
	for (; *s; s++)
		emit_byte(*s);
}

/*
 * emit_bit()
 *
 * zapisuje bufor wyj¶ciowy w formacie binarnym.
 */
void emit_bin(const char *filename)
{
	int fd, size = 0, i;
	
	unlink(filename);
	
	if ((fd = open(filename, O_CREAT | O_EXCL | O_WRONLY, 0644)) == -1) {
		fprintf(stderr, "%s: %s\n", filename, strerror(errno));
		exit(1);
	}

	for (i = 0; i < 65536; i++) {
		if (emit_used_get(i))
			size = i + 1;
	}

	if (write(fd, emit_buf, size) != size) {
		fprintf(stderr, "%s: %s\n", filename, strerror(errno));
		exit(1);
	}

	if (close(fd) == -1) {
		fprintf(stderr, "%s: %s\n", filename, strerror(errno));
		exit(1);
	}
}

/*
 * emit_hex()
 *
 * zapisuje bufor wyj¶ciowy w formacie Intel HEX.
 */
void emit_hex(const char *filename)
{
	FILE *f = fopen(filename, "w");
	int i;

	if (!f) {
		fprintf(stderr, "%s: %s\n", filename, strerror(errno));
		exit(1);
	}

	for (i = 0; i < 65536; ) {
		int size = 0;

		while (!emit_used_get(i) && i < 65536)
			i++;

		if (i > 65535)
			break;

		while (emit_used_get(i + size) && i + size < 65536)
			size++;

		if (verbosity)
			printf("output: occupied block at %.4Xh of size %.4Xh\n", i, size);

		while (size > 0) {
			unsigned char csum = 0;
			int j, chunk = (size > 16) ? 16 : size;

			fprintf(f, ":%.2X%.4X00", chunk, i);
			csum += chunk;
			csum += (i >> 8) & 255;
			csum += i & 255;
			
			for (j = 0; j < chunk; j++, i++) {
				fprintf(f, "%.2X", emit_buf[i]);
				csum += emit_buf[i];
			}

			fprintf(f, "%.2X\r\n", (256 - csum) % 256);

			size -= chunk;
		}
	}

	fprintf(f, ":00000001FF\r\n");

	fclose(f);
}
