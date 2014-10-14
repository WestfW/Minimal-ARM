/*
 * GetClockRate
 * Compute the clockrate for a give set of STM32f RCC variables
 * Only works when the PLL is used.
 */
.macro GetClockRate dest, clksrc=RCC_CFGR_PLLSRC_HSE, mult=RCC_CFGR_PLLMULL9, crystal=8000000
.if \clksrc == RCC_CFGR_PLLSRC_HSI_Div2
     .equ .L_clk, (\crystal/2)
.else
     .equ .L_clk, \crystal
.endif
.if \mult == RCC_CFGR_PLLMULL2
     .equ \dest, .L_clk*2
.endif
.if \mult == RCC_CFGR_PLLMULL3
     .equ \dest, .L_clk*3
.endif
.if \mult == RCC_CFGR_PLLMULL4
     .equ \dest, .L_clk*4
.endif
.if \mult == RCC_CFGR_PLLMULL5
     .equ \dest, .L_clk*5
.endif
.if \mult == RCC_CFGR_PLLMULL6
     .equ \dest, .L_clk*6
.endif
.if \mult == RCC_CFGR_PLLMULL7
     .equ \dest, .L_clk*7
.endif
.if \mult == RCC_CFGR_PLLMULL8
     .equ \dest, .L_clk*8
.endif
.if \mult == RCC_CFGR_PLLMULL9
     .equ \dest, .L_clk*9
.endif
.if \mult == RCC_CFGR_PLLMULL10
     .equ \dest, .L_clk*10
.endif
.if \mult == RCC_CFGR_PLLMULL11
     .equ \dest, .L_clk*11
.endif
.if \mult == RCC_CFGR_PLLMULL12
     .equ \dest, .L_clk*12
.endif
.if \mult == RCC_CFGR_PLLMULL13
     .equ \dest, .L_clk*13
.endif
.if \mult == RCC_CFGR_PLLMULL14
     .equ \dest, .L_clk*14
.endif
.if \mult == RCC_CFGR_PLLMULL15
     .equ \dest, .L_clk*15
.endif
.if \mult == RCC_CFGR_PLLMULL16
     .equ \dest, .L_clk*16
.endif
.endm

.if 0
	
.macro	ClockInit cpufreq=72000000, crystal=8000000
	ldr r0, =RCC_BASE		/* Clock control registers*/
  .if \crystal == 0
   /* Use internal clock (8MHz) */
    .if \cpufreq == 8000000
      .exitm
    .endif
    .L_xtalspeed = 8000000
    .L_pllsrc = RCC_CFGR_PLLSRC_HSI_Div2
    .L_clksrc = RCC_CFGR_SW_HSI   /* default */
    .L_pllclk = 4000000		/* PLL src is div2 */
  .else  /* Crystal not 0 */
/* Use external crystal */
    .L_clk = \crystal
    .L_xtalspeed = \crystal
    .L_pllsrc = RCC_CFGR_PLLSRC_HSE
    .L_clksrc = RCC_CFGR_SW_HSE
    .L_pllclk = crystal
    /*
     * Enable the oscillator for the external crystal, and wait
     * for it to finish starting up.
     */
    ldr r1, [r0, #RCC_CR]		/* get control reg contents */
    orr r1, #RCC_CR_HSEON		/* Turn on crystal oscillator */
    str r1, [r0, #RCC_CR]
0:	ldr r1, [r0, #RCC_CR]
     tst r1, #RCC_CR_HSERDY		/* wait for clock ready */
     beq.n 0b
.endif /* Crystal */
	
.if \cpufreq == .L_clk		/* Need PLL ? */
/* No PLL needed; just enable the HSE if it's turned on */
  .if .L_clksrc == RCC_CFGR_SW_HSE
	ldr r1, [r0, #RCC_CFGR]
	orr r1, #RCC_CFGR_SW_HSE 	/* Select HSE */
	str r1, [r0, #RCC_CFGR]
  .endif
.else /* cpufreq */
/* Need PLL; figure out the multiplier */
	.L_mult = \cpufreq/.L_pllclk
  .if .L_mult == 2
	.L_pllset = RCC_CHGR_PLLMULL2
  .elseif .L_mult == 3
	.L_pllset = RCC_CHGR_PLLMULL3
  .elseif .L_mult == 4
	.L_pllset = RCC_CHGR_PLLMULL4
  .elseif .L_mult == 5
	.L_pllset = RCC_CHGR_PLLMULL5
  .elseif .L_mult == 6
	.L_pllset = RCC_CHGR_PLLMULL6
  .elseif .L_mult == 7
	.L_pllset = RCC_CHGR_PLLMULL7
  .elseif .L_mult == 8
	.L_pllset = RCC_CHGR_PLLMULL8
  .elseif .L_mult == 9
	.L_pllset = RCC_CHGR_PLLMULL9
  .else
	.error unachievable clock rate \cpufreq in ClockInit Macro
  .endif
.endif /* cpufreq */
.endm
.endif

	