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

%option noyywrap
%option nounput

%{

#include <limits.h>
#include <string.h>
#include "main.h"
#include "xmalloc.h"
#include "parser.h"
#include "symbols.h"
#include "output.h"

#ifndef PATH_MAX
#  define PATH_MAX 4096
#endif

int lineno = 1;

static char *string;

#define MAX_INCLUDE_DEPTH 10
static YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
static char *filename_stack[MAX_INCLUDE_DEPTH];
static int lineno_stack[MAX_INCLUDE_DEPTH];
static int include_stack_ptr = 0;

/*
 * include()
 *
 * do³±cza do aktualnie kompilowane ¼ród³a inne.
 */
static void include(const char *new)
{
	char buf[PATH_MAX];

	if (include_stack_ptr >= MAX_INCLUDE_DEPTH) {
		if (pass == 1)
			error(_("includes nested too deeply"));
		return;
	}

	if (!(yyin = fopen(new, "r"))) {
		snprintf(buf, sizeof(buf), "%s/%s", DATADIR, new);

		if (!(yyin = fopen(buf, "r"))) {
			if (pass == 1)
				error(_("unable to include file `%s'"), new);
			return;
		}

		new = buf;
	}

	filename_stack[include_stack_ptr] = filename;
	lineno_stack[include_stack_ptr] = lineno;
	include_stack[include_stack_ptr++] = YY_CURRENT_BUFFER;

	filename = xstrdup(new);
	lineno = 1;

	yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));

	BEGIN(INITIAL);
}

/*
 * string_init()
 *
 * inicjuje nowy ci±g znaków.
 */
static void string_init()
{
	string = xmalloc(1);
	*string = 0;
}

/*
 * string_append()
 *
 * dodaje znak do zainicjowanego ci±gu znaków.
 */
static void string_append(int ch)
{
	if (ch < 0 || ch > 255) {
		if (pass == 1)
			yyerror(_("constant out of range"));
		return;
	}

	string = xrealloc(string, strlen(string) + 2);

	string[strlen(string) + 1] = 0;
	string[strlen(string)] = ch;
}
%}

SYMBOL	[a-z_][a-z0-9_]*
HEX	[0-9][0-9a-h]*h
BIN	[01]+b
DEC	[0-9]+

CHARS	[+*/&|.@,#-;]

%x s incl

%%

^$mod[0-9]+	include(yytext + 1);

^$include[ \t]+	BEGIN(incl);

<incl>[^ \t\n]+	include(yytext);

<<EOF>>		{
			if (include_stack_ptr > 0) {
				xfree(filename);
				lineno = lineno_stack[include_stack_ptr - 1];
				filename = filename_stack[include_stack_ptr - 1];
			}

			if (include_stack_ptr < 1)
				yyterminate();
			else {
				include_stack_ptr--;
				yy_delete_buffer(YY_CURRENT_BUFFER);
				yy_switch_to_buffer(include_stack[include_stack_ptr]);
			}
		}

^$[a-z]+	if (pass == 1) warning(_("ignoring directive `%s'"), yytext);

{BIN}		yylval.val = strtoul(yytext, NULL, 2); return VALUE;
{DEC}		yylval.val = strtoul(yytext, NULL, 10); return VALUE;
{HEX}		yylval.val = strtoul(yytext, NULL, 16); return VALUE;

{CHARS}		return yytext[0];

"\n"		lineno++; return '\n';

[ \t]+		/* ignoruj odstêpy miêdzy tokenami */

"\r"		/* ignoruj dosowe zakoñczenia linii */

;.*$		/* ignoruj komentarze */

\"		{ string_init(); BEGIN(s); }

<s>\"		{
			BEGIN(INITIAL);
			yylval.str = string;
			return STRING;
		}
		
<s>\n		if (pass == 1) yyerror(_("unterminated string constant"));

<s>\\[0-7]{1,3} string_append(strtoul(yytext + 1, NULL, 8));

<s>\\0x[0-9a-h]{2} string_append(strtoul(yytext + 3, NULL, 16));

<s>\\[0-9]+	if (pass == 1) yyerror(_("bad escape sequence"));

<s>\\n		string_append('\n');
<s>\\t		string_append('\t');
<s>\\r		string_append('\r');
<s>\\b		string_append('\b');
<s>\\f		string_append('\f');
<s>\\(.|\n)	string_append(yytext[1]);

<s>[^\\\n\"]+	{
			const char *p = yytext;

			for (p = yytext; *p; p++)
				string_append(*p);
		}

org		return ORG;
equ		return EQU;
end		return END;
db		return DB;
dw		return DW;
dd		return DD;
bit		return BIT_T;
data		return DATA_T;

lo8		return LOW;
hi8		return HIGH;
low		return LOW;
high		return HIGH;

acall		return ACALL;
add		return ADD;
addc		return ADDC;
ajmp		return AJMP;
anl		return ANL;
call		return CALL;
cjne		return CJNE;
clr		return CLR;
cpl		return CPL;
da		return DA;
dec		return DEC;
div		return DIV;
djnz		return DJNZ;
inc		return INC;
jb		return JB;
jbc		return JBC;
jc		return JC;
jmp		return JMP;
jnb		return JNB;
jnc		return JNC;
jnz		return JNZ;
jz		return JZ;
lcall		return LCALL;
ljmp		return LJMP;
mov		return MOV;
movc		return MOVC;
movx		return MOVX;
nop		return NOP;
mul		return MUL;
orl		return ORL;
pop		return POP;
push		return PUSH;
ret		return RET;
reti		return RETI;
rl		return RL;
rlc		return RLC;
rr		return RR;
rrc		return RRC;
setb		return SETB;
sjmp		return SJMP;
subb		return SUBB;
swap		return SWAP;
xch		return XCH;
xchd		return XCHD;
xrl		return XRL;

a		return A;
ab		return AB;
c		return C;
pc		return PC;
dptr		return DPTR;

r0		return R0;
r1		return R1;
r2		return R2;
r3		return R3;
r4		return R4;
r5		return R5;
r6		return R6;
r7		return R7;

{SYMBOL}	{
			struct symbol *i = symbol_find(yytext);

			if (!i)
				i = symbol_new(yytext, 0, CONST, 0);

			yylval.sym = i;

			return SYMBOL;
		}

.		if (pass == 1) error(_("invalid character `%c'"), yytext[0]);

%%

