/*
 * Blink, for SAMD10 Xplained Mini, in assembler.
 *
 * How to build an pure assembler project in Atmel Studio.
 * 1) The ARM Assembler is the gcc assembler, which is part of the C toolchain.
 *    So start by creating a "C Executable project" with the correct device.
 * 2) Modify the project Properties in the Toolchain panel:
 *    - for ARM/GNU Preprocessing Assembler, define a symbol __ASSEMBLY__
 *    - for ARM/GNU Linker under "general", check the (3) boxes to NOT use the
 *       standard libraries, start-files, or default libraries (all of which are in C)
 * 3) Delete the .c files from the Device_Startup folder.  You'll need to replace all
 *    of the functionality that was there.  Also, we'll be using the linker scripts, which
 *    means you'll need to define the sections that they're expecting.  Particularly ".vectors"
 * 4) Delete main.c
 * 5) Populate the project with added .S files. These will be pre-processed by the C preprocessor.
 */

#include <pio/samd10d13am.h>   // These are almost correct, in that the contain __ASSEMBLY__ conditionals.
#include <instance/port.h>     //  But they still have trailing "U"s on a bunch of the constants.

/*
 * These values are copied from port.h, stripped of their trailing U, and moved to the
 *  0x60000000 "fast IOBUS" part of the address space.  Bleh :-(
 */
#define REG_PORT_DIRSET           (0x61004408) /** fast IOBUS PortA Data Direction Set */
#define REG_PORT_OUTTGL           (0x6100441C) /** fast IOBUS PortA Data Output Value Toggle */

.global main

/* Use Default clocks (1MHz) */
/* PORTA is enabled by default */
/* Note LED is connected to PA09 */

main:
	ldr r1, =REG_PORT_DIRSET  // address of port
	mov r2, #1
	lsl r2, #9		// bit 9
	str r2,[r1]		// Set direction

loop:
	ldr r1, =REG_PORT_OUTTGL
	str r2, [r1]		// Toggle output bit
	mov r1, #5		/* Delay count */
	lsl r1, #14		/* Multiply by big number! */
delay:
	sub r1, #1		/* decrement */
	bne delay
	b loop

.section .bss
stackstart: .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  /* A small stack! */
stackend:

.section ".vectors"
.global exceptiontable
exceptiontable:
	.word stackend  /* Initial Stack Pointer */
	.word main+1    /* Start address (+1 means "thumb mode") */

.end
