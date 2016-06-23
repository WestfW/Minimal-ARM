################################################################################
# Automatically-generated file. Do not edit!
################################################################################

SHELL := cmd.exe
RM := rm -rf

USER_OBJS :=

LIBS := 
PROJ := 

O_SRCS := 
C_SRCS := 
S_SRCS := 
S_UPPER_SRCS := 
OBJ_SRCS := 
ASM_SRCS := 
PREPROCESSING_SRCS := 
OBJS := 
OBJS_AS_ARGS := 
C_DEPS := 
C_DEPS_AS_ARGS := 
EXECUTABLES := 
OUTPUT_FILE_PATH :=
OUTPUT_FILE_PATH_AS_ARGS :=
AVR_APP_PATH :=$$$AVR_APP_PATH$$$
QUOTE := "
ADDITIONAL_DEPENDENCIES:=
OUTPUT_FILE_DEP:=
LIB_DEP:=
LINKER_SCRIPT_DEP:=

# Every subdirectory with source files must be described here
SUBDIRS :=  \
../Device_Startup/


# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += 


PREPROCESSING_SRCS +=  \
../main.S


ASM_SRCS += 


OBJS +=  \
main.o

OBJS_AS_ARGS +=  \
main.o

C_DEPS +=  \
main.d

C_DEPS_AS_ARGS +=  \
main.d

OUTPUT_FILE_PATH +=samd10asmBlink.elf

OUTPUT_FILE_PATH_AS_ARGS +=samd10asmBlink.elf

ADDITIONAL_DEPENDENCIES:=

OUTPUT_FILE_DEP:= ./makedep.mk

LIB_DEP+= 

LINKER_SCRIPT_DEP+=  \
../Device_Startup/samd10d14am_flash.ld \
../Device_Startup/samd10d14am_sram.ld


# AVR32/GNU C Compiler



# AVR32/GNU Preprocessing Assembler

./%.o: .././%.S
	@echo Building file: $<
	@echo Invoking: ARM/GNU Preprocessing Assembler : 4.9.3
	$(QUOTE)C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-gcc.exe$(QUOTE) -mthumb -x assembler-with-cpp -c -mcpu=cortex-m0plus -I "C:\Program Files\Atmel\Studio\7.0\Packs\atmel\SAMD10_DFP\1.0.31\include" -I "C:\Program Files\Atmel\Studio\7.0\Packs\arm\cmsis\4.2.0\CMSIS\Include"  -MD -MP -MF "$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)" -D__SAMD10D14AM__ -D__ASSEMBLY__  -Wa,-g   -o "$@" "$<" 
	@echo Finished building: $<
	

./%.o: .././%.sx
	@echo Building file: $<
	@echo Invoking: ARM/GNU Preprocessing Assembler : 4.9.3
	$(QUOTE)C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-gcc.exe$(QUOTE) -mthumb -x assembler-with-cpp -c -mcpu=cortex-m0plus -I "C:\Program Files\Atmel\Studio\7.0\Packs\atmel\SAMD10_DFP\1.0.31\include" -I "C:\Program Files\Atmel\Studio\7.0\Packs\arm\cmsis\4.2.0\CMSIS\Include"  -MD -MP -MF "$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)" -D__SAMD10D14AM__ -D__ASSEMBLY__  -Wa,-g   -o "$@" "$<" 
	@echo Finished building: $<
	



# AVR32/GNU Assembler




ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

# Add inputs and outputs from these tool invocations to the build variables 

# All Target
all: $(OUTPUT_FILE_PATH) $(ADDITIONAL_DEPENDENCIES)

$(OUTPUT_FILE_PATH): $(OBJS) $(USER_OBJS) $(OUTPUT_FILE_DEP) $(LIB_DEP) $(LINKER_SCRIPT_DEP)
	@echo Building target: $@
	@echo Invoking: ARM/GNU Linker : 4.9.3
	$(QUOTE)C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-gcc.exe$(QUOTE) -o$(OUTPUT_FILE_PATH_AS_ARGS) $(OBJS_AS_ARGS) $(USER_OBJS) $(LIBS) -mthumb -nostartfiles -nodefaultlibs -nostdlib -Wl,-Map="samd10asmBlink.map" -Wl,--start-group -lm  -Wl,--end-group -L"..\\Device_Startup"  -Wl,--gc-sections -mcpu=cortex-m0plus -Tsamd10d14am_flash.ld  
	@echo Finished building target: $@
	"C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-objcopy.exe" -O binary "samd10asmBlink.elf" "samd10asmBlink.bin"
	"C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-objcopy.exe" -O ihex -R .eeprom -R .fuse -R .lock -R .signature  "samd10asmBlink.elf" "samd10asmBlink.hex"
	"C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-objcopy.exe" -j .eeprom --set-section-flags=.eeprom=alloc,load --change-section-lma .eeprom=0 --no-change-warnings -O binary "samd10asmBlink.elf" "samd10asmBlink.eep" || exit 0
	"C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-objdump.exe" -h -S "samd10asmBlink.elf" > "samd10asmBlink.lss"
	"C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-objcopy.exe" -O srec -R .eeprom -R .fuse -R .lock -R .signature  "samd10asmBlink.elf" "samd10asmBlink.srec"
	"C:\Program Files\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin\arm-none-eabi-size.exe" "samd10asmBlink.elf"
	
	





# Other Targets
clean:
	-$(RM) $(OBJS_AS_ARGS) $(EXECUTABLES)  
	-$(RM) $(C_DEPS_AS_ARGS)   
	rm -rf "samd10asmBlink.elf" "samd10asmBlink.a" "samd10asmBlink.hex" "samd10asmBlink.bin" "samd10asmBlink.lss" "samd10asmBlink.eep" "samd10asmBlink.map" "samd10asmBlink.srec"
	