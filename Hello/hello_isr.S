/*
 * Hello World via UART in ARM Assembler
 * For ST32F103c8t6, perhaps
 * Oct 2014, by Bill Westfield - released to Public Domain.
 */

.include "stm32f103c8.asmh"
.syntax unified
.thumb

/*
 * Options settable by the user.
 *****************************************************************************
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
 *****************************************************************************
	Data
 *****************************************************************************
 */
	.bss   /* Uninitialized RAM: we'll initialized it explicitly */
/*
 * There is 20k of RAM.
 */
memstart:	
/*
 * Space for RAM based IRQ table.
 * This should be at the start of RAM, or it will wind up
 * with "odd" alignment issues.
 */
newvectors:
CM3Vectors:	.space 16*4		/* CM3 vectors */
STMVectors:	.space 60*4		/* ST peripheral vectors */
	.equ NIRQS, (.-CM3Vectors)/4	/* Total number of IRQs. */
	
/*
 * Data structures for UART ISR.
 * (note: STRUCTDEF is defined in stm32f103c8.asmh, where it is mostly
 *  used to map structures onto chip registers.  However, there is no
 *  macro to actually allocate a structure!)
 */
	.equ UART_BUFSIZE, 32		/* Must be pwr of 2 */
	STRUCTDEF Q
	  uint8_ta BUF, UART_BUFSIZE
	  uint8_t HEAD
	  uint8_t TAIL
	  uint8_t CNT
	ENDSTRUCT

	_new_Q txqueue
	.balign 2
	_new_Q rxqueue

/*
 * Heap and stack
 */
	.align 4
heap:	.space HEAPSIZE
stack:	.space STACKSIZE
stackend:	
	
	.section .text
/*
 * Initial vectors.
 *
 * The ARM needs at least two words at the start of the flash that
 * specify the initial stack pointer and the reset start address.
 */

        .globl  _Vectors
_Vectors: .word stackend		/* Top of Stack */
	.word   _start + 1		/* Reset Handler (thumb!) */
	
/*
 * Utilty functions
 */

/*
 * Fill memory with a 32bit value.
 * value in R0, start address in R1, word count in R2.
 */
memfill:
	subs r2, #1
	str r0, [r1, r2, lsl #2]
	bne.n memfill		/* Loop */
	bx lr

/*
 * Delay loop.  I pick a constant that's a power of two so that
 * a single instruction with a shifted 8bit constant will be used.
 *
 *  C equivalient: for (uint32_t i=4096*1024; i != 0; i--) {}
 */
delay:	
.if DODELAY
	 mov r1, #(2*1024*1024)	/* Delay count */
0: 	  subs r1, #1		/* decrement */
	  bne.n 0b
.endif
	bx lr

/*
 * get a byte (return in R0) from FIFO Queue (R1)
 * return with Z set if no data is available.
 * Play nice with all registers.
 */
q_get:
	ldrb r0, [r1, #Q_CNT]		/* Check for empty */
	movs r0,r0
	beq.n qg_exit
	push {r2}
	subs r0, #1
	strb r0,  [r1, #Q_CNT]		/* update count */
	ldrb r2, [r1, #Q_TAIL]
	ldrb r0, [r1, r2]		/* Get byte from tail */
	adds r2, #1			/* Note: result never zero! */
	and r2, #UART_BUFSIZE-1
	strb r2, [r1, #Q_TAIL]
	pop {r2}
qg_exit:
	bx lr

/*
 * Put a byte (r0) into a FIFO queue (r1)
 * return with Z set if queue is full.
 * Play nice with all registers.
 */
q_put:	push {r2, lr}
	ldrb r2,[r1, #Q_CNT]		/* Get count */
	cmp r2, #UART_BUFSIZE
	bge.n qp_exit			/* queue is full */
	adds r2, #1
	strb r2, [r1, #Q_CNT]		/* update count */ 
	ldrb r2, [r1, #Q_HEAD]
	strb r0, [r1, r2]		/* Add byte */
	adds r2, #1			/* Never zero ! */
	and r2, #UART_BUFSIZE-1
	strb r2, [r1, #Q_HEAD]		/* update head */
qp_exit:
	pop {r2, pc}



/*
 * Initialize the clock to our max speed (72MHz), assuming an external 8MHz
 * crystal. This also involves configuring the flash for wait states, and
 * dividing the APB1 (low speed peripheral bus) clock.
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
`	 * Select the PLL output as our system clock
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

	ldr r0, =STMVectors		/* Set up UART ISR */
	adr r1, UARTISR+1
	str r1, [r0, #USART1_IRQn*4]
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
	orr r1, USART_CR1_RXNEIE	    /* Interrupt */
	str.w r1, [r0, #USART_CR1]
	/* CR2 and CR2 are OK at their default values */
	bx lr

UARTTXON:
	push {r2, lr}
	ldr r2, =USART1_BASE
	ldr r0, [r2, #USART_CR1]
	orr r0, #USART_CR1_TXEIE	/* Enable interrupts */
	str r0, [r2, #USART_CR1]
	pop {r2, pc}

/*
 * putchri
 * Send a single byte to the uart, via the tx FIFO queue, waiting for
 * it to be ready, if necessary.
 * Note the implementation of the "critical section"
 */

putchri:
	push {r2,lr}
	mrs r2, PRIMASK		/* Save interrupt status */
	ldr r1, =txqueue
0:	cpsid i			/* disable interrupts */
	bl q_put
	msr PRIMASK, r2		/* restore previous interrupt status */
	beq.n 0b		/* Queue was full */
	bl UARTTXON
	pop {r2, pc}
	
/*
 * getchr
 * Read a single byte from the UART, waiting as needed.
 */

getchri:  /* Like getchr, only read from ISR FIFO queue */
	push {r2, lr}
	mrs r2, PRIMASK
	ldr r1, =rxqueue
0:	cpsid i			/* disable interrupts */
	bl q_get
	msr PRIMASK, r2
	beq.n 0b
	pop {r2, pc}

	.ltorg

/*
 * putstri
 * output a zero-terminated string that is stored immediately following the
 * call instruction.  Note thumb indirect jump addresses are always odd.
 */
putstri:
	subs lr, #1		/* back up LR one, because THUMB. */
psl:	ldrb r0, [lr], #1	/* Get next byte */
	cbz r0, strend		/* Terminating null? */
		/* Have data */
	  push {lr}
	  bl putchri		/* Send the byte */
	  pop {lr}
	  b.n psl		/* Loop for more */
strend:	adds lr, #1
	tst lr, #1		/* Check low bit of return address. */
	bne.n 2f		/* (needs to end in 1 for THUMB */
	adds lr, #1
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
	beq 0f			/* Done?  Start printing */
	bl decout		/* recurse */
0:	pop {r0}		/* get digit */
	adds r0, #'0'		/* Convert to ascii */
	bl putchri
	pop {pc}		/* unwind */

	.ltorg /* Stick the literals from functions here */
	
/*
 *****************************************************************************
 */

USART1_IRQn = 37
USART1_ISRR = NVIC_ISER + 4*(USART1_IRQn/32)  /* Word in ISER array */
USART1_IEB = 1 << (USART1_IRQn & 0x1F)	    /* Bit in the word */

ISRInit:
	push {lr}
	adr r0, badint+1	/* Get our ISR Function (Thumb Mode!) */
	ldr r1, =newvectors
	mov r2, #NIRQS
	bl memfill

	ldr r0,=SCB_BASE	/* System Control Block */
	/* r1 still has newvectors */
	str r1, [r0, #SCB_VTOR]	/* Set new ISR base */
	
	ldr r0, =NVIC_BASE		/* Enable UART interrupts */
	ldr r1, [r0, #USART1_ISRR]
	orr r1, #USART1_IEB
	str r1, [r0, #USART1_ISRR]
	
	cpsie i			/* Enable Interrupts */
	pop {pc}

/*
 * UART ISR
 * For received data, move data from the uart DR to the rxqueue.
 * For transmit, since the interrupt condition is "tx reg empty", we
 *  have to turn of tx interrupts when there is no more data (because
 *  when there is no data, the tx reg is always empty.)
 */
UARTISR:
	push {lr}
	ldr r2,=USART1_BASE
	ldr.w r3,[r2, #USART_SR]	/* Get Status */
	tst.w r3,#USART_SR_RXNE		/* RX Data ? */
	beq.n uisr_tx
	 ldr.w r0, [r2, #USART_DR]	/* Get the data */
	 ldr r1, =rxqueue		/* Get Queue ptr */
	 bl q_put			/* Add byte to queue */
uisr_tx:
	ldr.w r3,[r2, #USART_SR]	/* Get Status */
	tst.w r3, #USART_SR_TXE		/* TX Empty ? */
	beq.n uisr_exit
	 ldr r1, =txqueue
	 bl q_get			/* Get a byte */
	 bne.n uisr_send		/* Was there data ? */
	  /* tx Queue is empty; disable interrupts */
	  ldr.w r3, [r2, #USART_CR1]
	  bic r3, #USART_CR1_TXEIE
	  str r3, [r2, #USART_CR1]
	  pop {pc}			/* return */
uisr_send:
	 str r0, [r2, USART_DR]		/* Output char */
uisr_exit:	
	pop {pc}


/*
 * Default interrupt/fault handler.
 * Turn off the interrupts we think we have on and spin
 */

badint:	/* Come here on bad interrupts */
	push {lr}
	ldr r1, =USART1_BASE
	ldr r0, [r1, #USART_CR1]	/* Get config reg */
	bic r0, #(USART_CR1_IDLEIE|USART_CR1_RXNEIE | USART_CR1_TXEIE | USART_CR1_TCIE)
	str r0, [r1, #USART_CR1]	/* disable usart interrupts */
0:
	ldr r0, =GPIOA_BASE	/* GPIO_PORTF */
	ldr r1, [r0, #GPIO_ODR] /* read DATA reg */
	eor r1, #(1<<mybit)
	str r1, [r0, #GPIO_ODR] /* write DATA reg */
	bl delay
0:	b.n 0b				/* spin */

	.ltorg

/*
 * Main program.
 * Send out the "Hello World" message.  Then wait for input characters,
 * and every time we get one, output its decimal value and another hello
 * world message.  Toggle an LED on PortA with each character.
 */
	
	.globl  _start
_start:	
main: /* In case you were looking for it */
/*
 * In order to use the GPIO ports, you first have to enable
 * a clock to that port.  This is done through the "Reset and
 * Clock Control (RCC) structure, but there are random different
 * registers/bits depending on which bus has the peripheral.
 *
 *  C equivalient: myClkCtrlReg |= myClkEnaBit;
 */
	bl ClockInit		/* Set clock to 72MHz */

	movs r0, #0
	ldr r1, =memstart
	ldr r2, =((stack-memstart)/4)
	bl memfill

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
	
	bl ISRInit		/* Set up a vector table in RAM */

	bl UARTInit		/* Initialize UART */

/*
 * Now loop around and toggle the GPIO pin, and output our hello
 */
	
loop:
	ldr r0, =GPIOA_BASE	/* GPIO_PORTF */
	ldr r1, [r0, #GPIO_ODR] /* read DATA reg */
	eor r1, #(1<<mybit)
	str r1, [r0, #GPIO_ODR] /* write DATA reg */

	bl putstri
	 .asciz "Hello World more than BUFSIZE characters long\r\n"
	 .balign 2

0:	bl getchri
	bl decout
	movs r0, #' '
	bl putchri

	b.n loop

.end
