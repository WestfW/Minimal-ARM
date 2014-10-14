@echo off
del t.lst
del t.elf
del t.hex
del t.o
arm-none-eabi-as -o t.o t.s
arm-none-eabi-ld -T stm32.ld -o t.elf t.o
arm-none-eabi-objdump -D t.elf > t.lst
arm-none-eabi-objcopy -O ihex t.elf t.hex
type t.lst
type t.hex
pause