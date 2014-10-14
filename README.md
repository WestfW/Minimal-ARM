Minimal-ARM
===========

Minimalist ARM Cortex Microcontroller development, in assembler.

We constantly hear that 32bit microcontrollers (and ARM Cortex-M chips in particular) are going to replace aging 8-bit architectures.   And yet, there seems to be a steep startup curve in begining to work with such chips.  Usually, the vendors will want to you install gigabytes worth of fancy "Integrated Development Environment", "Standard Peripheral Libraries", compilers and debugging tools.  Many of these are in fact only "limited evaluation" versions of toolsets that they hope you'll eventually spend money on.  Another choice is to install and configure Open Source Software toolchains, but these are similarly large, not to mention complicated to set up.

Can't we just spend a couple minutes downloading a command-line assembler, so we can program these new chips from the ground up, one instruction at a time, like we used to do for 8-bit chips?  And if we ARE willing to do that, what advantages might we see, compared to what certainly looks like "bloat" in the average "normally written" C application for an ARM Microcontroller?

This repository is inspired, and largely extracted, from several discussions on the EEVBlog Forums:
- [One Dollar One Minute ARM Development](http://www.eevblog.com/forum/microcontrollers/one-dollar-one-minute-arm-development/)
- [STM32: Ghetto Style](http://www.eevblog.com/forum/microcontrollers/stm32-ghetto-style/)
