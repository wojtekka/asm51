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
#include <errno.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include "main.h"
#include "xmalloc.h"
#include "output.h"
#include "symbols.h"

int errors = 0, warnings = 0;
int verbosity;
char *filename;

void yyerror(const char *s)
{
	if (!strcmp(s, "parse error"))
		s = _("parse error");

	fprintf(stderr, "%s:%d: %s\n", filename, lineno, s);
	exit(1);	
}

void error(const char *format, ...)
{
	va_list ap;

	fprintf(stderr, "%s:%d: ", filename, lineno);

	va_start(ap, format);
	vfprintf(stderr, format, ap);
	va_end(ap);

	fprintf(stderr, "\n");

	errors++;
}

void warning(const char *format, ...)
{
	va_list ap;

	fprintf(stderr, _("%s:%d: warning: "), filename, lineno);

	va_start(ap, format);
	vfprintf(stderr, format, ap);
	va_end(ap);

	fprintf(stderr, "\n");

	warnings++;
}

static void usage(const char *argv0, int error)
{
	FILE *f = (error) ? stderr : stdout;

	fprintf(f,
_("usage: %s [options] <inputfile>\n"
"\n"
"  -o <outputfile>  select different output file (default: inputfile.hex)\n"
"  -f <bin|hex>     select output file format (default: hex)\n"
"  -n               don't include default 8051 symbols\n"
"  -v               increase verbosity\n"
"  -V               print version\n"
"  -h               print this help message\n"
"\n"), argv0);
}

int main(int argc, char **argv)
{
	char *output = NULL;
	int format = 1, ch, no_symbol_default = 0;

	while ((ch = getopt(argc, argv, "o:f:nhvV")) != -1) {
		switch (ch) {
			case 'o':
				if (output) {
					fprintf(stderr, _("%s: cannot handle multiple output files\n"), argv[0]);
					exit(1);
				}
				output = xstrdup(optarg);
				break;
				
			case 'f':
				if (!strncasecmp(optarg, "bin", strlen(optarg)))
					format = 0;
				else if (!strncasecmp(optarg, "hex", strlen(optarg)))
					format = 1;
				else {
					fprintf(stderr, _("%s: unknown output format `%s'\n"), argv[0], optarg);
					exit(1);
				}
				break;
				
			case 'h':
				usage(argv[0], 0);
				exit(0);

			case 'n':
				no_symbol_default = 1;
				break;
			
			case 'v':
				verbosity++;
				break;

			case 'V':
				printf("%s %s\n%s\n%s\n", NAME, VERSION, COPYRIGHT, _(LICENSE));
				break;

			default:				
				break;
		}
	}

	if (optind >= argc) {
		fprintf(stderr, _("%s: insufficient parameters, type `%s -h' for help\n"), argv[0], argv[0]);
		exit(1);
	}

	if (optind < argc - 1) {
		fprintf(stderr, _("%s: too many parameters, type `%s -h' for help\n"), argv[0], argv[0]);
		exit(1);
	}
	
	filename = xstrdup(argv[optind]);
	
	if (!(yyin = fopen(filename, "r"))) {
		fprintf(stderr, "%s: %s\n", argv[1], strerror(errno));
		exit(2);
	}

	if (!no_symbol_default)
		symbol_default();

	if (verbosity)
		warning("first pass");

	pass = 1;

	yyparse();

	if (errors)
		exit(3);

	if (verbosity)
		warning("second pass");

	pass = 2;

	lineno = 1;

	rewind(yyin);
	emit_init();

	yyparse();

	if (errors)
		exit(3);

	fclose(yyin);	

	if (verbosity) {
		struct symbol *s;

		printf("declared symbols:\n");

		for (s = symbols; s; s = s->next) {
			if (s->defined)
				printf("  %s = %.4xh\n", s->name, s->value);
			else
				printf("  %s = ?\n", s->name);
		}
	}

	if (!output) {
		if (!strcasecmp(filename + strlen(filename) - 4, ".asm")) {
			output = xstrdup(filename);
			strcpy(output + strlen(output) - 4, (format) ? ".hex" : ".bin");
		} else {
			output = xmalloc(strlen(filename) + 5);
			sprintf(output, "%s.%s", filename, (format) ? "hex" : "bin");
		}
	}
				
	if (format)
		emit_hex(output);
	else
		emit_bin(output);

	xfree(output);

	return 0;
}
