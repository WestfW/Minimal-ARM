/*
 * Hello World via UART in ARM Assembler
 * For ST32F103c8t6, perhaps
 * Aug - Sep 2014, by Bill Westfield - released to Public Domain.
 */

.include "stm32f103c8.asmh"
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
	.equ WAITSTATES, FLASH_ACR_LATENCY_2

	.equ CLKSRC, RCC_CFGR_PLLSRC_HSE

	.equ PLLMULT, RCC_CFGR_PLLMULL9
@	.equ PLLMULT, 0		/* If 0, don't use the PLL */
				/*  Note that xxx PLLMULL2 is 0, so this structure */
				/*  doesn't support x2 clock configurations */

	.equ F_CPU, 72000000
/*
 ********************************************************************************
 */
	.segment .text
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
	

/*
 * UART (USART) utility functions
 */
	
UARTInit:
/*
 * Uart1 is on Port A9/A10
 * First Turn on clock for port A, including Alternate Functions, and UART
 * rcc->apb2enr = iopaen|afioen|usart1en ;
 */
	ldr r0, =RCC_BASE
	ldr r1, [r0, #RCC_APB2ENR]		/* old val */
	orr r1, #RCC_APB2ENR_IOPAEN|RCC_APB2ENR_AFIOEN /* enable PORTA, AltFunc clk */
	orr r1, #RCC_APB2ENR_USART1EN
	str r1, [r0, #RCC_APB2ENR]
	
/*
 * Set the pins appropriately (A9 as alt function output, A10 default to input)
 */
	ldr r0, =GPIOA_BASE	/* GPIO_PORTA */
	ldr r1, [r0, #GPIO_CRH]	
	bic r1, ( (0xF << ((9-8)*4)) | (0xF << ((10-8)*4)) )
	orr r1, #((GPIO_MODE_OUT50MHz+GPIO_CNF_AFPP) << ((9-8)*4))  /* output bit */
	orr r1, #((GPIO_MODE_IN+GPIO_CNF_FLOAT) << ((10-8)*4))  /* input bit */
	str r1, [r0, #GPIO_CRH]  /* set io bit modes */
/*
 * Set up the USART itself
 */
	ldr r0, =USART1_BASE
	ldr r1, =F_CPU/115200
	str.w r1, [r0, #USART_BRR]
	mov r1, #USART_CR1_TE+USART_CR1_RE  /* Enable TX and RX */
	orr r1, #USART_CR1_UE		    /* Enable USART as a whole */
	str.w r1, [r0, #USART_CR1]
	/* CR2 and CR2 are OK at their default values */
	bx lr
	

/*
 * putchr
 * Send a single byte to the uart, waiting for it to be ready, if necessary
 */
putchr:
	ldr r1, =USART1_BASE		/* USART1 */
0:	 ldr.w r2, [r1, #USART_SR]	/* Get status register */
	 tst r2, #USART_SR_TXE
	 beq.n 0b			/* Wait for tx empty */
	str.w r0, [r1, #USART_DR]
	bx lr


/*
 * getchr
 * Read a single byte from the UART, waiting as needed.
 */
getchr:
	ldr r1, =USART1_BASE
0:	ldr.w r2, [r1, #USART_SR]
	 tst r2, #USART_SR_RXNE
	 beq.n 0b
	ldr.w r0, [r1, #USART_DR]
	bx lr

/*
 * putstri
 * output a zero-terminated string that is stored immediately following the call
 * instruction.  Note thumb indirect jump addresses are always odd.
 */
putstri:
	sub lr, #1		/* back up LR one, because THUMB. */
psl:	ldrb r0, [lr], #1	/* Get next byte */
	tst r0, r0		/* Terminating null? */
	beq.n strend
		/* Have data */
	  push {lr}
	  bl putchr		/* Send the byte */
	  pop {lr}
	  b.n psl		/* Loop for more */
strend:	add lr, #1
	tst lr, #1		/* Check low bit of return address. */
	bne.n 2f		/* (needs to end in 1 for THUMB */
	add lr, #1
2:	bx lr

/*
 * Output a decimal number from r0.
 * (classic recursive algorithm!)
 */
decout: push {lr}
	movs r2, #0x0A		/* 10 */
	udiv r1, r0, r2		/* r1 = r0/r2 */
	mls r2, r1, r2, r0	/* r1 = r0 - r1*r2  (mod 10) */
	push {r2}		/* Save remainder */
	movs r0, r1		/* move quotient back into r0 */
	beq decout2		/* Done?  Start printing */
	bl decout		/* recurse */
decout2:
	pop {r0}		/* get digit */
	adds r0, #'0'		/* Convert to ascii */
	bl putchr
	pop {pc}		/* unwind */


/*
 * Delay loop.  I pick a constant that's a power of two so that
 * a single instruction with a shifted 8bit constant will be used.
 *
 *  C equivalient: for (uint32_t i=4096*1024; i != 0; i--) {}
 */
delay:
.if DODELAY
	 mov r1, #(4*1024*1024)	/* Delay count */
0: 	  subs r1, #1		/* decrement */
	  bne.n 0b
.endif
	bx lr
	
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
	bl ClockInit		/* Set clock to 72MHz */
	ldr r0, =RCC_BASE+RCC_APB2ENR
	ldr r1, [r0]		/* old val */
	orr r1, r1, #RCC_APB2ENR_IOPAEN /* enable PORTA clk for blinking*/
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
	
	bl UARTInit		/* Initialize UART */


/*
 * Now loop around and toggle the GPIO pin, and output our hello
 */
	
loop:
	ldr r0, =GPIOA_BASE	/* GPIO_PORTF */
	ldr r1, [r0, #GPIO_ODR] /* read DATA reg */
	eor r1, #(1<<mybit)
	str r1, [r0, #GPIO_ODR] /* read DATA reg */

	bl putstri
	 .asciz "Hello World\r\n"
	 .align 2

0:	bl getchr
	bl decout
	movs r0, #' '
	bl putchr

	b.n loop

.end
