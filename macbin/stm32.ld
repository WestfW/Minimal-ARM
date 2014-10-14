/* update for STM32f103c8 - 64k flash, 20k RAM */

MEMORY
{
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 20K
  rom (rx)  : ORIGIN = 0x08000000, LENGTH = 64K
}
SECTIONS
{
    .  = 0x08000000;         /* From 0x08000000 */
    .text : 
    {
        *(vectors)    /* Vector table */
        *(.text)      /* Program code */
        *(.rodata)    /* Read only data */
    } >rom

    .  = 0x20000000;  /* From 0x20000000 */      
    .data : 
    {
        *(.data)      /* Data memory */
    } >ram AT > rom

    .bss :
    {
        *(.bss)       /* Zero-filled run time allocate data memory */
    } >ram AT > rom
} 
