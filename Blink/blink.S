/*
 * BLINK in ARM Assembler
 * For ST32F103c8t6, perhaps
 * Aug - Sep 2014, by Bill Westfield - released to Public Domain.
 */

.include "stm32f103c8.asmh"
.include "westfwMacros.S"	
.syntax unified
.thumb

/*
 * Options settable by the user.
 ********************************************************************************
 */
	.equ STACKSIZE, 1024
	.equ HEAPSIZE, 8192
	.equ myport, GPIOA_BASE	/* must be portA... */
	.equ mybit, 5		/* PA5: arbitrary bit choice, for now. */

	.equ DODELAY, 1		/* if 0, just toggle at max loop speed. */
				/* if 1, blink at human-like speeds */
	.equ FASTTOGGLE, 0	/* Maximum effort high-speed pin toggle? */

	.equ WAITSTATES, FLASH_ACR_LATENCY_2

	.equ CLKSRC, RCC_CFGR_PLLSRC_HSE
@	.equ CLKSRC, RCC_CFGR_PLLSRC_HSI_Div2

	.equ PLLMULT, RCC_CFGR_PLLMULL9
@	.equ PLLMULT, 0		/* If 0, don't use the PLL */
				/*  Note that xxx PLLMULL2 is 0, so this structure */
				/*  doesn't support x2 clock configurations */

	GetClockRate F_CPU, clksrc=CLKSRC, mult=PLLMULT
/*
 ********************************************************************************
 */
	
/*
 * Initial vectors.
 *
 * The ARM needs at least two words at the start of the flash that
 * specify the initial stack pointer and the reset start address.
 */

        .globl  _Vectors
_Vectors: .word    SRAM_BASE+HEAPSIZE+STACKSIZE	/* Top of Stack */
	.word   _start + 1            /* Reset Handler (thumb!) */


/*
 * Initialize the clock to our max speed (72MHz), assuming an external 8MHz crystal.
 * This also involves configuring the flash for wait states, and dividing the APB1
 * (low speed peripheral bus) clock.
 */
ClockInit:
	/*
	 * Set the flash wait states - 1 at > 24MHz, 2 at >48MHz.
	 * (do this FIRST!)
	 */
	ldr r0, =FLASH_R_BASE		/* Flash control register */
	ldr r1, [r0, #FLASH_ACR]
	orr r1, #WAITSTATES		/* Set for appropriate wait states */
	str r1, [r0, #FLASH_ACR]

	/*
	 * Enable the oscillator for the external crystal, and wait
	 * for it to finish starting up.
	 */
	ldr r0, =RCC_BASE		/* Clock control registers*/
	ldr r1, [r0, #RCC_CR]		/* get control reg contents */
	orr r1, #RCC_CR_HSEON		/* Turn on crystal oscillator */
	str r1, [r0, #RCC_CR]
clklp:	ldr r1, [r0, #RCC_CR]
	 tst r1, #RCC_CR_HSERDY		/* wait for clock ready */
	 beq.n clklp

.if	PLLMULT
	/*
	 * Configure and enable the PLL,then start it and wait for lock.
	 */
	ldr r1, [r0, #RCC_CFGR]		/* Get clock config register */
	
	orr r1, #PLLMULT + CLKSRC	/* Multiply osc */
	
	orr r1, #RCC_CFGR_PPRE1_DIV2	/* But make sure APB1 is < 36MHz */
	str r1, [r0, #RCC_CFGR]
	ldr r1, [r0, #RCC_CR]		/* get control reg contents */
	orr r1, #RCC_CR_PLLON		/* Turn on PLL */
	str r1, [r0, #RCC_CR]		/* store */
plllp:	ldr r1, [r0, #RCC_CR]
	 tst r1, #RCC_CR_PLLRDY		/* wait for clock ready */
	 beq.n plllp

	/*
	 * Select the PLL output as our system clock
	 */
	ldr r1, [r0, #RCC_CFGR]
	orr r1, #RCC_CFGR_SW_PLL 	/* Select PLL */
	str r1, [r0, #RCC_CFGR]
.else
	ldr r1, [r0, #RCC_CFGR]
	orr r1, #RCC_CFGR_SW_HSE 	/* Select HSE */
	str r1, [r0, #RCC_CFGR]
.endif	
	
	bx lr  /* Return */
	

SysTickInit:
	bx lr  /* Return */


	.globl  _start
_start:	
/*
 * In order to use the GPIO ports, you first have to enable
 * a clock to that port.  This is done through the "Reset and
 * Clock Control (RCC) structure, but there are random different
 * registers/bits depending on which bus has the peripheral.
 *
 *  C equivalient: myClkCtrlReg |= myClkEnaBit;
 */
	bl ClockInit
	bl SysTickInit
	ldr r0, =RCC_BASE+RCC_APB2ENR
	ldr r1, [r0]		/* old val */
	orr r1, r1, #RCC_APB2ENR_IOPAEN /* enable PORTA clk */
	str r1, [r0]

/*
 * Now set up the GPIO pin for output.  Each pin is controlled
 * by 4 bits in the CRL or CRH register (depending on bit)
 *
 *  C equivalient: mygpio.CRx = MYGPIOMODE<<(myBitPos);
 */
initf:	mov r1, #((GPIO_MODE_OUT+GPIO_CNF_PP) << (mybit*4))  /* output bits */
	ldr r0, =GPIOA_BASE	/* GPIO_PORTF */
	str r1, [r0, #GPIO_CRL]  /* set bit to output */

/*
 * Now loop around and toggle the GPIO pin.
 * While the port has atomic set/reset ports, I'm going to just
 * do a non-atom read and xor.
 *
 *  C equivalient: while (1) { mygpio.ODR ^= 1<<mybit ; }
 */
.if FASTTOGGLE
	ldr r1,  [r0, #GPIO_ODR] /* read DATA reg */
	eor r1, r2, #(1<<mybit)
loop:
	 str r1, [r0, #GPIO_ODR] /* 1 write */
	 str r2, [r0, #GPIO_ODR] /* write */
	 str r1, [r0, #GPIO_ODR] /* 2 write */
	 str r2, [r0, #GPIO_ODR] /* write */
	 str r1, [r0, #GPIO_ODR] /* 3 write */
	 str r2, [r0, #GPIO_ODR] /* write */
	 str r1, [r0, #GPIO_ODR] /* 4 write */
	 str r2, [r0, #GPIO_ODR] /* write */
	 str r1, [r0, #GPIO_ODR] /* 5 write */
	 str r2, [r0, #GPIO_ODR] /* write */
	 str r1, [r0, #GPIO_ODR] /* 6 write */
	 str r2, [r0, #GPIO_ODR] /* write */
	 str r1, [r0, #GPIO_ODR] /* 7 write */
	 str r2, [r0, #GPIO_ODR] /* write */
	 str r1, [r0, #GPIO_ODR] /* 8 write */
	 str r2, [r0, #GPIO_ODR] /* write */
.else
/*
 * Delay loop.  I pick a constant that's a power of two so that
 * a single instruction with a shifted 8bit constant will be used.
 *
 *  C equivalient: for (uint32_t i=4096*1024; i != 0; i--) {}
 */
loop:
	ldr r1, [r0, #GPIO_ODR] /* read DATA reg */
	eor r1, #(1<<mybit)
	str r1, [r0, #GPIO_ODR] /* read DATA reg */
	
.if DODELAY
	 mov r1, #(4*1024*1024)	/* Delay count */
delay: 	  subs r1, #1		/* decrement */
	  bne.n delay
.endif
.endif /* FASTTOGGLE */
	
	 b.n loop

.end
