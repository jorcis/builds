CXX=arm-none-eabi-g++
CC=arm-none-eabi-gcc
SIZE=arm-none-eabi-size
OBJCOPY=arm-none-eabi-objcopy

SDK=/usr/src/nRF5_SDK_16.0.0
BOOST=/usr/src/boost_1_71_0
TARGET_BIN=eMod-factory
DEBUG_LEVEL=0
FINAL_DIRECTORY=output/armgcc/release
ifeq ("$(DEBUG_LEVEL)","4")
	FINAL_DIRECTORY=output/arm/debug
endif

ARMGCC_DEFINES=\
	_DEBUG_LEVEL_=$(DEBUG_LEVEL) \
	NRF52840_XXAA \
	BOARD_PCA10056 \
	BSP_DEFINES_ONLY \
	FLOAT_ABI_HARD \
	INITIALIZE_USER_SECTIONS \
	NO_VTOR_CONFIG \
	NRFX_GPIOTE_ENABLED 

ARMGCC_UNDEFINES=\
	DEBUG_NRF \
	DEBUG_NRF_USER

ARMGCC_INCLUDES=\
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
	$(SDK)/modules/nrfx/mdk/gcc_startup_nrf52840.S \

ARMGCC_LIBRARIES=\

COMMON_FLAGS=\
	-mcpu=cortex-m4 \
	-mthumb \
	-mabi=aapcs \
	-mfloat-abi=hard \
	-mfpu=fpv4-sp-d16 \
	-O3 \
	-g3 \

LINKER_FLAGS=\
	-L$(SDK)/modules/nrfx/mdk \
	-Wl,--gc-sections \
	--specs=nosys.specs \
	-lc \
	-lnosys \
	-lm \

ACOMPILER_FLAGS=\
	-MP \
	-MD \
	-c \
	-D__HEAP_SIZE=8192 \
	-D__STACK_SIZE=8192 \

CCOMPILER_FLAGS=\
	-Wall \
	-Wextra \
	-ffunction-sections \
	-fdata-sections \
	-fno-strict-aliasing \
	-fno-builtin \
	-fshort-enums \
	-fno-exceptions \

DEFINES=$(addprefix -D,$(ARMGCC_DEFINES))
UNDEFINES=$(addprefix -U,$(ARMGCC_UNDEFINES))
INCLUDES=$(addprefix -I,$(ARMGCC_INCLUDES))
SOURCES=$(APP_SOURCES) $(SDK_SOURCES) $(SYSTEM_SOURCES)
LIBRARIES=$(addprefix -l,$(ARMGCC_LIBRARIES))

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
	$(shell "./lnsrc.sh" $(FINAL_DIRECTORY)/src $(C_SOURCES))
	$(shell "./lnsrc.sh" $(FINAL_DIRECTORY)/src $(CPP_SOURCES))
	$(shell "./lnsrc.sh" $(FINAL_DIRECTORY)/src $(ASM_SOURCES))

link: $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS)
	@echo
	$(if $(CXX), ($(CXX) $(COMMON_FLAGS) $(LINKER_FLAGS) $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS) $(LIBRARIES) -Wl,-Map=${FINAL_DIRECTORY}/bin/$(TARGET_BIN).map -o ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).out), $(CXX) $(COMMON_FLAGS) $(LINKER_FLAGS) $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS) $(LIBRARIES) -Wl,-Map=${FINAL_DIRECTORY}/bin/$(TARGET_BIN).map -o ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).out )	
	@echo
	$(if $(SIZE), $(SIZE) ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).out)
	$(if $(OBJCOPY), $(OBJCOPY) -O ihex ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).out ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).hex)
	$(if $(OBJCOPY), $(OBJCOPY) -O binary ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).out ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).bin)

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.c $(HPP_SOURCES) $(H_SOURCES)
	$(CC) $(COMMON_FLAGS) -std=c99 $(ACOMPILER_FLAGS) $(CCOMPILER_FLAGS) $(DEFINES) $(UNDEFINES) $(INCLUDES) -o $@ $<

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.cpp $(HPP_SOURCES) $(H_SOURCES)
	$(CXX) $(COMMON_FLAGS) -std=c++1z $(ACOMPILER_FLAGS) $(CCOMPILER_FLAGS) $(DEFINES) $(UNDEFINES) $(INCLUDES) -o $@ $<

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.s
	$(CXX) -x assembler-with-cpp $(COMMON_FLAGS) $(ACOMPILER_FLAGS) -o $@ $<

postlink:
	$(shell find -L $(FINAL_DIRECTORY)/src -maxdepth 1 -type l -delete)


