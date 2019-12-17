
SDK=/usr/src/nRF5_SDK_16.0.0
TARGET_BIN=eMod-interface
DEBUG_LEVEL=0
FINAL_DIRECTORY=output/segger/release
#SEGGER_HOME=/usr/opt/segger_embedded_studio_for_arm_4.22
SEGGER_HOME=/usr/share/segger_embedded_studio_for_arm_4.22
BIN_DIR=$(SEGGER_HOME)/gcc/arm-none-eabi/bin
DEBUG_FLAG="-DNDEBUG"
ifeq ("$(DEBUG_LEVEL)","4")
	FINAL_DIRECTORY=output/segger/debug
	DEBUG_FLAG=-DDEBUG "-D DEBUG_NRF"
endif

SEGGER_DEFINES=\
	NRF52840_XXAA \
	BOARD_PCA10056 \
	BSP_DEFINES_ONLY \
	FLOAT_ABI_HARD \
	INITIALIZE_USER_SECTIONS \
	NO_VTOR_CONFIG \
	NRFX_GPIOTE_ENABLED \

SEGGER_UNDEFINES=\
	DEBUG_NRF \
	DEBUG_NRF_USER

SEGGER_INCLUDES=\
	../source \
	../source/factory \
	../source/uart/nrf52840 \
	../source/uart/common \
	../config \
	$(SDK)/include \
	$(SDK)/modules/nrfx \
	$(SDK)/integration/nrfx \
	$(SDK)/modules/nrfx/drivers/src \

APP_SOURCES=\
	../source/test/main.cpp \
	../source/factory \
	../source/uart/nrf52840

SDK_SOURCES=\
	$(SDK)/modules/nrfx/drivers/src/nrfx_gpiote.c \
	$(SDK)/modules/nrfx/drivers/src/nrfx_timer.c \

SYSTEM_SOURCES=\
	$(SDK)/modules/nrfx/mdk/system_nrf52840.c \
	$(SDK)/modules/nrfx/mdk/ses_startup_nrf52840.s \
	$(SDK)/modules/nrfx/mdk/ses_startup_nrf_common.s \
	$(SEGGER_HOME)/source/thumb_crt0.s \

SEGGER_LIBRARIES=\
	$(SEGGER_HOME)/lib/libdebugio_mempoll_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
	$(SEGGER_HOME)/lib/libm_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
	$(SEGGER_HOME)/lib/libc_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
	$(SEGGER_HOME)/lib/libcpp_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
	$(SEGGER_HOME)/lib/libdebugio_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
	$(SEGGER_HOME)/lib/libvfprintf_v7em_fpv4_sp_d16_hard_t_le_eabi.o \
	$(SEGGER_HOME)/lib/libvfscanf_v7em_fpv4_sp_d16_hard_t_le_eabi.o \

COMMON_FLAGS=\
	-fmessage-length=0 \
	-fno-diagnostics-show-caret \
	-fno-exceptions \
	-mcpu=cortex-m4 \
	-mlittle-endian \
	-mfloat-abi=hard \
	-mfpu=fpv4-sp-d16 \
	-mthumb \
	-nostdinc \
	-isystem$(SEGGER_HOME)/include \
	-D__SIZEOF_WCHAR_T=4 \
	-D__ARM_ARCH_7EM__ \
	-D__SES_ARM \
	-D__ARM_ARCH_FPV4_SP_D16__ \
	-D__HEAP_SIZE__=8192 \
	-D__SES_VERSION=42200 \
	-D__GNU_LINKER \
	$(DEBUG_FLAG) \
	-quiet \

C_COMPILER_SEGGER_FLAGS=\
	-munaligned-access \
	-v \
	-g3 \
	-gpubnames \
	-fomit-frame-pointer \
	-fno-dwarf2-cfi-asm \
	-fno-builtin \
	-ffunction-sections \
	-fdata-sections \
	-fshort-enums \
	-fno-common \

S_COMPILER_SEGGER_FLAGS=\
	-E

ASSEMBLER_SEGGER_FLAGS=\
	-mcpu=cortex-m4 \
	-mlittle-endian \
	-mfloat-abi=hard \
	-mfpu=fpv4-sp-d16 \
	-mthumb \
	-g \
	-gdwarf-4 \

LINKER_FLAGS=\
	-X \
	--omagic \
	-eReset_Handler \
	--defsym=__vfprintf=__vfprintf_long \
	--defsym=__vfscanf=__vfscanf_long \
	-EL \
	-u_vectors \
	--emit-relocs \

LINKER_LD_FILE=../config/segger.ld

DEFINES=$(addprefix -D,$(SEGGER_DEFINES))
UNDEFINES=$(addprefix -U,$(SEGGER_UNDEFINES))
INCLUDES=$(addprefix -I,$(SEGGER_INCLUDES))
SOURCES=$(APP_SOURCES) $(SDK_SOURCES) $(SYSTEM_SOURCES)
#LIBRARIES=$(addprefix -l,$(SEGGER_LIBRARIES))
COMPILER=$(BIN_DIR)/cc1
ASSEMBLER=$(BIN_DIR)/as
LD_MAKER=$(SEGGER_HOME)/bin/mkld
LINKER=$(BIN_DIR)/ld
HEX_COPIER=$(BIN_DIR)/objcopy
C_COMPILER_FLAGS=$(COMMON_FLAGS) $(C_COMPILER_SEGGER_FLAGS)
S_COMPILER_FLAGS=$(COMMON_FLAGS) $(S_COMPILER_SEGGER_FLAGS)

C_SOURCES=$(shell find -L $(SOURCES) -maxdepth 1 -name '*.c')
CPP_SOURCES=$(shell find -L $(SOURCES) -maxdepth 1 -name '*.cpp')
ASM_SOURCES=$(shell find -L $(SOURCES) -maxdepth 1 -name '*.s')
HPP_SOURCES=$(shell find -L $(LINUX_INCLUDES) -maxdepth 1 -name '*.hpp')
H_SOURCES=$(shell find -L $(LINUX_INCLUDES) -maxdepth 1 -name '*.h')

C_OBJECTS=$(addprefix $(FINAL_DIRECTORY)/obj/, $(addsuffix .o,$(notdir $(basename ${C_SOURCES}))))
CPP_OBJECTS=$(addprefix $(FINAL_DIRECTORY)/obj/, $(addsuffix .o,$(notdir $(basename ${CPP_SOURCES}))))
ASM_OBJECTS=$(addprefix $(FINAL_DIRECTORY)/obj/, $(addsuffix .o,$(notdir $(basename ${ASM_SOURCES}))))


default: prelink link postlink

prelink:
	@mkdir -p $(FINAL_DIRECTORY)
	@mkdir -p $(FINAL_DIRECTORY)/bin
	@mkdir -p $(FINAL_DIRECTORY)/src
	@mkdir -p $(FINAL_DIRECTORY)/obj
	$(shell rm -f $(FINAL_DIRECTORY)/src/*.*)
	$(shell cp -f $(LINKER_LD_FILE) $(FINAL_DIRECTORY)/bin/$(TARGET_BIN).ld)
	$(shell "./lnsrc.sh" "$(FINAL_DIRECTORY)/src" $(C_SOURCES))
	$(shell "./lnsrc.sh" "$(FINAL_DIRECTORY)/src" $(CPP_SOURCES))
	$(shell "./lnsrc.sh" "$(FINAL_DIRECTORY)/src" $(ASM_SOURCES))

link: $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS)
	@echo
	$(LINKER) $(LINKER_FLAGS) --gc-sections "-T$(FINAL_DIRECTORY)/bin/$(TARGET_BIN).ld" -Map $(FINAL_DIRECTORY)/bin/$(TARGET_BIN).map -o $(FINAL_DIRECTORY)/bin/$(TARGET_BIN).elf --start-group $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS) $(SEGGER_LIBRARIES) --end-group
	@echo
	$(HEX_COPIER) $(FINAL_DIRECTORY)/bin/$(TARGET_BIN).elf $(FINAL_DIRECTORY)/bin/$(TARGET_BIN).hex -Oihex	

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.c $(HPP_SOURCES) $(H_SOURCES)
	$(COMPILER) $(C_COMPILER_FLAGS) -mtp=soft -std=gnu99 $(DEFINES) $(UNDEFINES) $(INCLUDES) -MD $(FINAL_DIRECTORY)/obj/$(addsuffix .d,$(notdir $(basename $@))) -MQ $@ $< -o $(FINAL_DIRECTORY)/obj/$(addsuffix .asm,$(notdir $(basename $@)))
	$(ASSEMBLER) $(ASSEMBLER_SEGGER_FLAGS) $(FINAL_DIRECTORY)/obj/$(addsuffix .asm,$(notdir $(basename $@))) -o $@

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.cpp $(HPP_SOURCES) $(H_SOURCES)
	$(COMPILER)plus $(C_COMPILER_FLAGS) -fno-rtti -mtp=soft -std=c++1z $(DEFINES) $(UNDEFINES) $(INCLUDES) -MD $(FINAL_DIRECTORY)/obj/$(addsuffix .d,$(notdir $(basename $@))) -MQ $@ $< -o $(FINAL_DIRECTORY)/obj/$(addsuffix .asm,$(notdir $(basename $@)))
	$(ASSEMBLER) $(ASSEMBLER_SEGGER_FLAGS) $(FINAL_DIRECTORY)/obj/$(addsuffix .asm,$(notdir $(basename $@))) -o $@

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.s
	$(COMPILER) $(S_COMPILER_FLAGS) -lang-asm -MD $(FINAL_DIRECTORY)/obj/$(addsuffix .d,$(notdir $(basename $@))) -MQ $@ $< -o $(FINAL_DIRECTORY)/obj/$(addsuffix _PP.s,$(notdir $(basename $@)))
	$(ASSEMBLER) $(ASSEMBLER_SEGGER_FLAGS) $(FINAL_DIRECTORY)/obj/$(addsuffix _PP.s,$(notdir $(basename $@))) -o $@

postlink:
	$(shell find -L $(FINAL_DIRECTORY)/src -maxdepth 1 -type l -delete)


