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

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "xmalloc.h"
#include "output.h"
#include "symbols.h"

#define is8(x) (((x) & 0x00ff) == (x))
#define is11(x) (((x) & 0x07ff) == (x))
#define is16(x) (((x) & 0xffff) == (x))
#define isrel(x) ((x) >= -128 && (x) < 128)
#define isbm(x) (( ((x) >= 128) && !((x) & 0x07) ) || ((x) >= 0x20 && (x) < 0x40))

#define emit1(x) do { emit_byte(x); } while(0)
#define emit2(x,y) do { emit_byte(x); emit_byte(y); } while (0)
#define emit3(x,y,z) do { emit_byte(x); emit_byte(y); emit_byte(z); } while (0)
#define emit3w(x,y) do { emit_byte(x); emit_word(y); } while (0)

%}

%union {
	int val;
	char *str;
	struct symbol *sym;
}

%token <val> VALUE
%token <sym> SYMBOL
%token <str> STRING

%token ORG EQU DB DW DD END BIT_T DATA_T
%token LOW HIGH
%token ACALL ADD ADDC AJMP ANL CJNE CLR CPL DA DEC DIV DJNZ INC JB JBC JC JMP
%token JNB JNC JNZ JZ LCALL LJMP MOV MOVC MOVX NOP MUL ORL POP PUSH RET RETI
%token RL RLC RR RRC SETB SJMP SUBB SWAP XCH XCHD XRL
%token CALL JMP
%token A AB C PC DPTR
%token R0 R1 R2 R3 R4 R5 R6 R7

%left '+' '-'
%left '*' '/' '%'
%left '&' '|'

%%

file:	/* empty */
    |	lines
    ;

lines:	lines line
     |	line
     ;

line:	undef ':' ORG dexpr '\n'
    	{
		emit_pc_set($<val>3);
		$<sym>1->defined = 1;
		$<sym>1->value = emit_pc;
		$<sym>1->type = LABEL;
	}
    |	undef ':' instr '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = emit_pc;
		$<sym>1->type = LABEL;
		emit_pc_inc($<val>3);
	}
    |	undef ':' dir '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = emit_pc;
		$<sym>1->type = LABEL;
		emit_pc_inc($<val>3);
	}
    |	undef ':' '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = emit_pc;
		$<sym>1->type = LABEL;
	}
    |	undef ORG dexpr '\n'
    	{
		emit_pc_set($<val>3);
		$<sym>1->defined = 1;
		$<sym>1->value = emit_pc;
		$<sym>1->type = LABEL;
	}
    |	undef EQU expr '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = $<val>3;
		$<sym>1->type = CONST;
	}
    |	undef EQU bit '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = $<val>3;
		$<sym>1->type = BIT_T;
	}
    |	undef BIT_T bit '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = $<val>3;
		$<sym>1->type = BIT_T;
	}
    |	undef BIT_T expr '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = $<val>3;
		$<sym>1->type = BIT_T;
	}
    |	undef DATA_T expr '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = $<val>3;
		$<sym>1->type = DATA_T;
	}
    |	undef dir '\n'
    	{
		$<sym>1->defined = 1;
		$<sym>1->value = emit_pc;
		$<sym>1->type = LABEL;
		emit_pc_inc($<val>2);
	}
    |	dir '\n'
	{
		emit_pc_inc($<val>1);
	}
    |	instr '\n'
    	{
		emit_pc_inc($<val>1);
	}
    |	'\n'
    ;

undef:	SYMBOL
     	{
		if ($<sym>1->defined && pass == 1)
			warning(_("`%s' redefined"), $<sym>1->name);
		$<sym>$ = $<sym>1;
	}
     ;

dir:	DB bytes		{ $<val>$ = $<val>2; }
   |	DW words		{ $<val>$ = $<val>2; }
   |	DD dwords		{ $<val>$ = $<val>2; }
   |	ORG dexpr		{ emit_pc_set($<val>2); $<val>$ = 0; }
   |	END			{ YYACCEPT; }
   ;

bytes:	bytes ',' data		{ emit_byte($<val>3); $<val>$ = $<val>1 + 1; }
     |	bytes ',' STRING	{ emit_string($<str>3); $<val>$ = $<val>1 + strlen($<str>3); xfree($<str>3); }
     |	data			{ emit_byte($<val>1); $<val>$ = 1; }
     |	STRING			{ emit_string($<str>1); $<val>$ = strlen($<str>1); xfree($<str>1); }
     ;

words:	words ',' data16	{ emit_word($<val>3); $<val>$ = $<val>1 + 2; }
     |	data16			{ emit_word($<val>1); $<val>$ = 2; }
     ;

dwords:	dwords ',' data32	{ emit_dword($<val>3); $<val>$ = $<val>1 + 4; }
      |	data32			{ emit_dword($<val>1); $<val>$ = 4; }
      ;

instr:	ACALL addr11		{ emit2(0x11 | (($<val>2 & 0x0700) >> 3), $<val>2 & 0x00ff); $<val>$ = 2; }
     |	AJMP addr11		{ emit2(0x01 | (($<val>2 & 0x0700) >> 3), $<val>2 & 0x00ff); $<val>$ = 2; }

     |	ADD A ',' '#' data	{ emit2(0x24, $<val>5); $<val>$ = 2; }
     |	ADD A ',' direct	{ emit2(0x25, $<val>4); $<val>$ = 2; }
     |	ADD A ',' '@' Ri	{ emit1(0x26 + $<val>5); $<val>$ = 1; }
     |	ADD A ',' Rn		{ emit1(0x28 + $<val>4); $<val>$ = 1; }

     |	ADDC A ',' '#' data	{ emit2(0x34, $<val>5); $<val>$ = 2; }
     |	ADDC A ',' direct	{ emit2(0x35, $<val>4); $<val>$ = 2; }
     |	ADDC A ',' '@' Ri	{ emit1(0x36 + $<val>5); $<val>$ = 1; }
     |	ADDC A ',' Rn		{ emit1(0x38 + $<val>4); $<val>$ = 1; }

     |	ANL A ',' '#' data	{ emit2(0x54, $<val>5); $<val>$ = 2; }
     |	ANL A ',' direct	{ emit2(0x55, $<val>4); $<val>$ = 2; }
     |	ANL A ',' '@' Ri	{ emit1(0x56 + $<val>5); $<val>$ = 1; }
     |	ANL A ',' Rn		{ emit1(0x58 + $<val>4); $<val>$ = 1; }
     |	ANL direct ',' A	{ emit2(0x52, $<val>2); $<val>$ = 2; }
     |	ANL direct ',' '#' data	{ emit3(0x53, $<val>2, $<val>5); $<val>$ = 3; }
     |	ANL C ',' direct	{ emit2(0x82, $<val>4); $<val>$ = 2; }
     |	ANL C ',' bit		{ emit2(0x82, $<val>4); $<val>$ = 2; }
     |	ANL C ',' '/' direct	{ emit2(0xb0, $<val>5); $<val>$ = 2; }
     |	ANL C ',' '/' bit	{ emit2(0xb0, $<val>5); $<val>$ = 2; }

     |	CALL addr16		{ emit3w(0x12, $<val>2); $<val>$ = 3; }

     |	CJNE A ',' '#' data ',' rel3	{ emit3(0xb4, $<val>5, $<val>7); $<val>$ = 3; }
     |	CJNE A ',' direct ',' rel3	{ emit3(0xb5, $<val>4, $<val>6); $<val>$ = 3; }
     |	CJNE '@' Ri ',' '#' data ',' rel3	{ emit3(0xb6 + $<val>3, $<val>6, $<val>8); $<val>$ = 3; }
     |	CJNE Rn ',' '#' data ',' rel3	{ emit3(0xb8 + $<val>2, $<val>5, $<val>7); $<val>$ = 3; }

     |	CLR A			{ emit1(0xe4); $<val>$ = 1; }
     |	CLR direct		{ emit2(0xc2, $<val>2); $<val>$ = 2; }
     |	CLR bit			{ emit2(0xc2, $<val>2); $<val>$ = 2; }
     |	CLR C			{ emit1(0xc3); $<val>$ = 1; }

     |	CPL A			{ emit1(0xf4); $<val>$ = 1; }
     |	CPL direct		{ emit2(0xb2, $<val>2); $<val>$ = 2; }
     |	CPL bit			{ emit2(0xb2, $<val>2); $<val>$ = 2; }
     |	CPL C			{ emit1(0xb3); $<val>$ = 1; }

     |	DA A			{ emit1(0xd4); $<val>$ = 1; }

     |	DEC A			{ emit1(0x14); $<val>$ = 1; }
     |	DEC direct		{ emit2(0x15, $<val>2); $<val>$ = 2; }
     |	DEC '@' Ri		{ emit1(0x16 + $<val>3); $<val>$ = 1; }
     |	DEC Rn			{ emit1(0x18 + $<val>2); $<val>$ = 1; }

     |	DIV AB			{ emit1(0x84); $<val>$ = 1; }

     |	DJNZ direct ',' rel3	{ emit3(0xd5, $<val>2, $<val>4); $<val>$ = 3; }
     |	DJNZ Rn ',' rel2	{ emit2(0xd8 + $<val>2, $<val>4); $<val>$ = 2; }

     |	INC A			{ emit1(0x04); $<val>$ = 1; }
     |	INC direct		{ emit2(0x05, $<val>2); $<val>$ = 2; }
     |	INC '@' Ri		{ emit1(0x06 + $<val>3); $<val>$ = 1; }
     |	INC Rn			{ emit1(0x08 + $<val>2); $<val>$ = 1; }
     |	INC DPTR		{ emit1(0xa3); $<val>$ = 1; }

     |	JBC direct ',' rel3	{ emit3(0x10, $<val>2, $<val>4); $<val>$ = 3; }
     |	JBC bit ',' rel3	{ emit3(0x10, $<val>2, $<val>4); $<val>$ = 3; }
     |	JB direct ',' rel3	{ emit3(0x20, $<val>2, $<val>4); $<val>$ = 3; }
     |	JB bit ',' rel3		{ emit3(0x20, $<val>2, $<val>4); $<val>$ = 3; }
     |	JNB direct ',' rel3	{ emit3(0x30, $<val>2, $<val>4); $<val>$ = 3; }
     |	JNB bit ',' rel3	{ emit3(0x30, $<val>2, $<val>4); $<val>$ = 3; }
     |	JC rel2			{ emit2(0x40, $<val>2); $<val>$ = 2; }
     |	JNC rel2		{ emit2(0x50, $<val>2); $<val>$ = 2; }
     |	JZ rel2			{ emit2(0x60, $<val>2); $<val>$ = 2; }
     |	JNZ rel2		{ emit2(0x70, $<val>2); $<val>$ = 2; }
     
     |	JMP dexpr		{
     					int rel = $<val>2 - (emit_pc + 2);

					if (isrel(rel)) {
						emit2(0x80, rel);
						$<val>$ = 2;
					} else {
						emit3w(0x02, $<val>2);
						$<val>$ = 3;
					}
				}
     
     |	JMP addr16		{ emit3w(0x02, $<val>2); $<val>$ = 3; }
     |	JMP '@' A '+' DPTR	{ emit1(0x73); $<val>$ = 1; }

     |	LCALL addr16		{ emit3w(0x12, $<val>2); $<val>$ = 3; }
     |	LJMP addr16		{ emit3w(0x02, $<val>2); $<val>$ = 3; }

     |	MOV A ',' '#' data	{ emit2(0x74, $<val>5); $<val>$ = 2; }     
     |	MOV A ',' direct	{ emit2(0xe5, $<val>4); $<val>$ = 2; }
     |	MOV A ',' Rn		{ emit1(0xe8 + $<val>4); $<val>$ = 1; }
     |	MOV A ',' '@' Rn	{ emit1(0xe6 + $<val>5); $<val>$ = 1; }
     |	MOV direct ',' A	{ emit2(0xf5, $<val>2); $<val>$ = 2; }
     |	MOV direct ',' '#' data	{ emit3(0x75, $<val>2, $<val>5); $<val>$ = 3; }
     |	MOV direct ',' '@' Ri	{ emit2(0x86 + $<val>5, $<val>2); $<val>$ = 2; }
     |	MOV direct ',' Rn	{ emit2(0x88 + $<val>4, $<val>2); $<val>$ = 2; }
     |	MOV direct ',' direct	{ emit3(0x85, $<val>4, $<val>2); $<val>$ = 3; }
     |	MOV '@' Ri ',' '#' data	{ emit2(0x76 + $<val>3, $<val>6); $<val>$ = 2; }
     |	MOV '@' Ri ',' A	{ emit1(0xf6 + $<val>3); $<val>$ = 1; }
     |	MOV '@' Ri ',' direct	{ emit2(0xa6 + $<val>3, $<val>5); $<val>$ = 2; }
     |	MOV Rn ',' '#' data	{ emit2(0x78 + $<val>2, $<val>5); $<val>$ = 2; }
     |	MOV Rn ',' A		{ emit1(0xf8 + $<val>2); $<val>$ = 1; }
     |	MOV Rn ',' direct	{ emit2(0xa8 + $<val>2, $<val>4); $<val>$ = 2; }

     |	MOV C ',' direct	{ emit2(0xa2, $<val>4); $<val>$ = 2; }
     |	MOV C ',' bit		{ emit2(0xa2, $<val>4); $<val>$ = 2; }
     |	MOV direct ',' C	{ emit2(0x92, $<val>2); $<val>$ = 2; }
     |	MOV bit ',' C		{ emit2(0x92, $<val>2); $<val>$ = 2; }

     |	MOV DPTR ',' '#' data16	{ emit3w(0x90, $<val>5); $<val>$ = 3; }
 
     |	MOVC A ',' '@' A '+' PC	{ emit1(0x83); $<val>$ = 1; }
     |	MOVC A ',' '@' A '+' DPTR	{ emit1(0x93); $<val>$ = 1; }
     |	MOVX '@' DPTR ',' A	{ emit1(0xf0); $<val>$ = 1; }
     |	MOVX A ',' '@' DPTR	{ emit1(0xe0); $<val>$ = 1; }
     |	MOVX '@' Ri ',' A	{ emit1(0xf2 + $<val>3); $<val>$ = 1; }
     |	MOVX A ',' '@' Ri	{ emit1(0xe2 + $<val>5); $<val>$ = 1; }

     |	MUL AB			{ emit1(0xa4); $<val>$ = 1; }

     |	NOP			{ emit1(0x00); $<val>$ = 1; }

     |	ORL A ',' '#' data	{ emit2(0x44, $<val>5); $<val>$ = 2; }
     |	ORL A ',' direct	{ emit2(0x45, $<val>4); $<val>$ = 2; }
     |	ORL A ',' '@' Ri	{ emit1(0x46 + $<val>5); $<val>$ = 1; }
     |	ORL A ',' Rn		{ emit1(0x48 + $<val>4); $<val>$ = 1; }
     |	ORL direct ',' A	{ emit2(0x42, $<val>2); $<val>$ = 2; }
     |	ORL direct ',' '#' data	{ emit3(0x43, $<val>2, $<val>5); $<val>$ = 3; }

     |	ORL C ',' direct	{ emit2(0x72, $<val>4); $<val>$ = 2; }
     |	ORL C ',' bit		{ emit2(0x72, $<val>4); $<val>$ = 2; }
     |	ORL C ',' '/' direct	{ emit2(0xa0, $<val>5); $<val>$ = 2; }
     |	ORL C ',' '/' bit	{ emit2(0xa0, $<val>5); $<val>$ = 2; }

     |	POP direct		{ emit2(0xd0, $<val>2); $<val>$ = 2; }
     |	PUSH direct		{ emit2(0xc0, $<val>2); $<val>$ = 2; }

     |	RET			{ emit1(0x22); $<val>$ = 1; }
     |	RETI			{ emit1(0x32); $<val>$ = 1; }

     |	RL A			{ emit1(0x23); $<val>$ = 1; }
     |	RLC A			{ emit1(0x33); $<val>$ = 1; }
     |	RR A			{ emit1(0x03); $<val>$ = 1; }
     |	RRC A			{ emit1(0x13); $<val>$ = 1; }
     
     |	SETB direct		{ emit2(0xd2, $<val>2); $<val>$ = 2; }
     |	SETB bit		{ emit2(0xd2, $<val>2); $<val>$ = 2; }
     |	SETB C			{ emit1(0xd3); $<val>$ = 1; }

     |	SJMP rel2		{ emit2(0x80, $<val>2); $<val>$ = 2; }
     
     |	SUBB A ',' '#' data	{ emit2(0x94, $<val>5); $<val>$ = 2; }
     |	SUBB A ',' direct	{ emit2(0x95, $<val>4); $<val>$ = 2; }
     |	SUBB A ',' '@' Ri	{ emit1(0x96 + $<val>5); $<val>$ = 1; }
     |	SUBB A ',' Rn		{ emit1(0x98 + $<val>4); $<val>$ = 1; }

     |	SWAP A			{ emit1(0xc4); $<val>$ = 1; }

     |	XCH A ',' direct	{ emit2(0xc5, $<val>4); $<val>$ = 2; }
     |	XCH A ',' '@' Ri	{ emit1(0xc6 + $<val>5); $<val>$ = 1; }
     |	XCH A ',' Rn		{ emit1(0xc8 + $<val>4); $<val>$ = 1; }

     |	XCHD A ',' '@' Ri	{ emit1(0xd6 + $<val>5); $<val>$ = 1; }

     |	XRL A ',' '#' data	{ emit2(0x64, $<val>5); $<val>$ = 2; }
     |	XRL A ',' direct	{ emit2(0x65, $<val>4); $<val>$ = 2; }
     |	XRL A ',' '@' Ri	{ emit1(0x66 + $<val>5); $<val>$ = 1; }
     |	XRL A ',' Rn		{ emit1(0x68 + $<val>4); $<val>$ = 1; }
     |	XRL direct ',' A	{ emit2(0x62, $<val>2); $<val>$ = 2; }
     |	XRL direct ',' '#' data	{ emit3(0x63, $<val>2, $<val>5); $<val>$ = 3; }

     ;

expr:	'(' expr ')'		{ $<val>$ = $<val>2; }
    |	'-' expr		{ $<val>$ = -$<val>2; }
    |	LOW expr		{ $<val>$ = $<val>2 & 0x00ff; }
    |	HIGH expr		{ $<val>$ = ($<val>2 & 0xff00) >> 8; }
    |	expr '&' expr		{ $<val>$ = $<val>1 & $<val>3; }
    |	expr '|' expr		{ $<val>$ = $<val>1 | $<val>3; }
    |	expr '*' expr		{ $<val>$ = $<val>1 * $<val>3; }
    |	expr '/' expr		{ $<val>$ = $<val>1 / $<val>3; }
    |	expr '%' expr		{ $<val>$ = $<val>1 % $<val>3; }
    |	expr '-' expr		{ $<val>$ = $<val>1 - $<val>3; }
    |	expr '+' expr		{ $<val>$ = $<val>1 + $<val>3; }
    |	expr '>' '>' expr	{ $<val>$ = $<val>1 >> $<val>4; }
    |	expr '<' '<' expr	{ $<val>$ = $<val>1 << $<val>4; }
    |	VALUE			{ $<val>$ = $<val>1; }
    |	'$'			{ $<val>$ = emit_pc; }
    |	SYMBOL
    	{
		if (!$<sym>1->defined && pass == 2)
			error(_("`%s' undefined"), $<sym>1->name);
		$<val>$ = $<sym>$->value;
	}
    ;

dexpr:	'(' dexpr ')'		{ $<val>$ = $<val>2; }
     |	'-' dexpr		{ $<val>$ = -$<val>2; }
     |	LOW dexpr		{ $<val>$ = $<val>2 & 0x00ff; }
     |	HIGH dexpr		{ $<val>$ = ($<val>2 & 0xff00) >> 8; }
     |	dexpr '&' dexpr		{ $<val>$ = $<val>1 & $<val>3; }
     |	dexpr '|' dexpr		{ $<val>$ = $<val>1 | $<val>3; }
     |	dexpr '*' dexpr		{ $<val>$ = $<val>1 * $<val>3; }
     |	dexpr '/' dexpr		{ $<val>$ = $<val>1 / $<val>3; }
     |	dexpr '%' dexpr		{ $<val>$ = $<val>1 % $<val>3; }
     |	dexpr '-' dexpr		{ $<val>$ = $<val>1 - $<val>3; }
     |	dexpr '+' dexpr		{ $<val>$ = $<val>1 + $<val>3; }
     |	dexpr '>' '>' dexpr	{ $<val>$ = $<val>1 >> $<val>4; }
     |	dexpr '<' '<' dexpr	{ $<val>$ = $<val>1 << $<val>4; }
     |	VALUE			{ $<val>$ = $<val>1; }
     |	'$'			{ $<val>$ = emit_pc; }
     |	SYMBOL
    	{
		if (!$<sym>1->defined)
			error(_("`%s' undefined"), $<sym>1->name);
		$<val>$ = $<sym>$->value;
	}
     ;

data:	expr
    	{
		if (!is8($<val>1) && pass == 2)
			error(_("data exceeds 8 bits"));
	}
    ;

data16:	expr
      	{
		if (!is16($<val>1) && pass == 2)
			error(_("data exceeds 16 bits"));
	}
      ;

data32:	expr
      ;

addr11:	expr
      	{
		if (!is11($<val>1) && pass == 2)
			error(_("address exceeds 11 bits"));
	}
      ;

addr16:	expr
      	{
		if (!is16($<val>1) && pass == 2)
			error(_("address exceeds 16 bits"));
	}
      ;

rel2:	expr
   	{
		int diff = $<val>1 - (emit_pc + 2);
		
		if (!isrel(diff) && pass == 2)
			error(_("relative jump exceeds -128/+127 bytes"));

		$<val>$ = diff;
	}
   ;

rel3:	expr
   	{
		int diff = $<val>1 - (emit_pc + 3);

		if (!isrel(diff) && pass == 2)
			error(_("relative jump exceeds -128/+127 bytes"));

		$<val>$ = diff;
	}
   ;

direct:	dexpr
    	{
		if (!is8($<val>1) && pass == 2)
			error(_("address exceeds 8 bits"));
		$<val>$ = $<val>1;
	}
      ;

bit:	direct '.' VALUE
   	{
		if (!is8($<val>1) || !isbm($<val>1))
			error(_("location outside bit addressable area"));
		if ($<val>3 < 0 || $<val>3 > 7)
			error(_("invalid bit index"));

			
		if ($<val>1 < 128)
			$<val>$ = (($<val>1 - 0x20) << 3) | $<val>3;
		else
			$<val>$ = $<val>1 | $<val>3;
	}	
   ;

Rn:	R0	{ $<val>$ = 0; }
  |	R1	{ $<val>$ = 1; }
  |	R2	{ $<val>$ = 2; }
  |	R3	{ $<val>$ = 3; }
  |	R4	{ $<val>$ = 4; }
  |	R5	{ $<val>$ = 5; }
  |	R6	{ $<val>$ = 6; }
  |	R7	{ $<val>$ = 7; }
  ;

Ri:	R0	{ $<val>$ = 0; }
  |	R1	{ $<val>$ = 1; }
  ;

%%

