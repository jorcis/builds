
CXX=arm-fslc-linux-gnueabi-g++
CC=arm-fslc-linux-gnueabi-gcc

TARGET_BIN=eMod-factory
DEBUG_LEVEL=4
FINAL_DIRECTORY=output/variscite/release
ifeq ("$(DEBUG_LEVEL)","4")
	FINAL_DIRECTORY=output/variscite/debug
endif

VARISCITE_DEFINES=\
	_DEBUG_LEVEL_=$(DEBUG_LEVEL) \
	__debug_messages__=1 \
	__linux__ \
	__variscite__

VARISCITE_UNDEFINES=\

VARISCITE_INCLUDES=\
	../source/test \
	../source/factory \

APP_SOURCES=\
	../source/test/main.cpp \
	../source/factory \

VARISCITE_SOURCES=\
	
VARISCITE_LIBRARIES=\
	stdc++ \
	rt \

COMMON_FLAGS=\
	-march=armv7-a \
	-mthumb \
	-mfpu=neon \
	-mfloat-abi=hard \
	--sysroot="/opt/fslc-framebuffer/2.6.2/sysroots/armv7at2hf-neon-fslc-linux-gnueabi" \

CCOMPILER_FLAGS=\
	-c \
	-g \
	-fno-exceptions \
	-Wall \
	-Wextra \

LCOMPILER_FLAGS=\
	-L/opt/fslc-framebuffer/2.6.2/sysroots/armv7at2hf-neon-fslc-linux-gnueabi/usr/lib \

VARISCITE_FLAGS=\

DEFINES=$(addprefix -D,$(VARISCITE_DEFINES))
UNDEFINES=$(addprefix -U,$(VARISCITE_UNDEFINES))
INCLUDES=$(addprefix -I,$(VARISCITE_INCLUDES))
SOURCES=$(APP_SOURCES) $(VARISCITE_SOURCES)
LIBRARIES=$(addprefix -l,$(VARISCITE_LIBRARIES))
COMPILER_FLAGS=$(COMMON_FLAGS) $(CCOMPILER_FLAGS) $(VARISCITE_FLAGS)
LINKER_FLAGS=$(COMMON_FLAGS) $(LCOMPILER_FLAGS)

C_SOURCES=$(shell find -L $(SOURCES) -maxdepth 1 -name '*.c')
CPP_SOURCES=$(shell find -L $(SOURCES) -maxdepth 1 -name '*.cpp')
ASM_SOURCES=$(shell find -L $(SOURCES) -maxdepth 1 -name '*.s')
HPP_SOURCES=$(shell find -L $(VARISCITE_INCLUDES) -maxdepth 1 -name '*.hpp')
H_SOURCES=$(shell find -L $(VARISCITE_INCLUDES) -maxdepth 1 -name '*.h')

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
	$(shell "./lnsrc.sh" "$(FINAL_DIRECTORY)/src" $(C_SOURCES))
	$(shell "./lnsrc.sh" "$(FINAL_DIRECTORY)/src" $(CPP_SOURCES))
	$(shell "./lnsrc.sh" "$(FINAL_DIRECTORY)/src" $(ASM_SOURCES))

link: $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS)
	@echo
	$(CXX) $(LINKER_FLAGS) -o ${FINAL_DIRECTORY}/bin/$(TARGET_BIN) $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS) $(LIBRARIES)
	@echo
	$(if $(SIZE), $(SIZE) ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).out)
	$(if $(OBJCOPY), $(OBJCOPY) -O ihex ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).out ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).hex)
	$(if $(OBJCOPY), $(OBJCOPY) -O binary ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).out ${FINAL_DIRECTORY}/bin/$(TARGET_BIN).bin)

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.c  $(HPP_SOURCES) $(H_SOURCES)
	$(CC) $(COMPILER_FLAGS) -std=c99 $(DEFINES) $(UNDEFINES) $(INCLUDES) -o $@ $<

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.cpp  $(HPP_SOURCES) $(H_SOURCES)
	$(CXX) $(COMPILER_FLAGS) -std=c++1z $(DEFINES) $(UNDEFINES) $(INCLUDES) -o $@ $<

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.s
	$(CXX) $(COMPILER_FLAGS) -lang-asm -o $@ $<

postlink:
	$(shell find -L $(FINAL_DIRECTORY)/src -maxdepth 1 -type l -delete)

clean:
	$(shell rm -f $(FINAL_DIRECTORY)/obj/*)
