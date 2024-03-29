asm51
=====

It is a simple two-pass assembler for 8051 family CPUs. Its features are:

* compatibility with most DOS assemblers,
* support for directives like EQU, ORG, DB, END, etc.
* Intel syntax,
* binary or Intel HEX output.

It was written as a student project.

Tested with
-----------

* GNU Make 4.4, gcc 13.1.1, GNU Bison 3.8.2, flex 2.6.4

Changes
-------

* 0.7 (2023-11-30) - fixed compilation with recent toolchain
* 0.6 (2006-10-10) - fixed compilation with flex 2.5.33 (Adrian Czerniak)
* 0.5 (2004-06-16) - fixed DB with strings
* 0.4 (2004-01-20) - Intel-HEX checksum fixed
* 0.3 (2003-12-09) - added support for character constants and C-style hex and bin values (eg. 0xff, 0b11111111)
* 0.2 (2003-12-04) - fixed CJNE, redefinition of constants is allowed
* 0.1 (2003-11-02) - initial release

License
-------

(C) Copyright 2003-2023 Wojtek Kaniewski <wojtekka@toxygen.net>

Released under the terms of GNU GPL version 2 license

