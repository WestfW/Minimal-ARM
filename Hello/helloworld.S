/*
 * Hello World on Serial port in ARM Assembler
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

	.equ WAITSTATES, FLASH_ACR_LATENCY_2
	.equ CLKSRC, RCC_CFGR_PLLSRC_HSE
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


UARTInit:
/*
 * Uart1 is on Port A9/A10
 * First Turn on clock for port A
 */
	ldr r0, =RCC_BASE+RCC_APB2ENR
	ldr r1, [r0]		/* old val */
	orr r1, #RCC_APB2ENR_IOPAEN /* enable PORTA clk */
	orr r1, #RCC_APB2ENR_USART1EN
	str r1, [r0]
/*
 * Set the pins appropriately (A9 as alt function output, A10 default to input)
 */
	mov r1, #((GPIO_MODE_OUT+GPIO_CNF_AFPP) << (9))  /* output bits */
	orr r1, #((GPIO_MODE_OUT+GPIO_CNF_PP) << (mybit))  /* Blink LED A5 */
	ldr r0, =GPIOA_BASE	/* GPIO_PORTF */
	str r1, [r0, #GPIO_CRL]  /* set bit to output */
/*
 * Set up the USART itself
 */
.if 0	
	ldr r0, =USART1_BASE
	ldr r1, =F_CPU/9600
	str r1, [r0, #USART_BRR]
	ldr r1, =USART_CR1_UE+USART_CR1_TE+USART_CR1_RE
	str r1, [r0, #USART_CR1]
	/* CR2 and CR2 are OK at their default values */
.endif
	bx lr


getcwait:
	bx lr

putchr:	
	ldr r1, =USART1_BASE		/* USART1 */
0:	 ldr r2, [r1, #USART_SR]	/* Get status register */
	 tst r2, #USART_SR_TXE
	 beq.n 0b			/* Wait for tx empty */
	str r0, [r1, #USART_DR]
	bx lr

	
putstri:
	mov  r2, lr
	ldrb r0, [r2], #1	/* Get next byte */

	bx lr


	.globl  _start
_start:	
	bl ClockInit
	bl SysTickInit
	bl UARTInit

Loop:
	 ldr r0, =GPIOA_BASE	/* GPIO_PORTF */
	 ldr r1, [r0, #GPIO_ODR] /* read DATA reg */
	 eor r1, #(1<<mybit)
	 str r1, [r0, #GPIO_ODR] /* write toggled bit */
	
	 mov r0, #'x'
@	 bl putchr
	
	 mov r1, #(4*1024*1024)	/* Delay count */
delay: 	  subs r1, #1		/* decrement */
	  bne.n delay
	
	b Loop

.if 0
	bl getcwait
	bl outstri
	.asciz "Hello World\r\n"
.endif

	
.end
