
CXX=g++
CC=gcc

TARGET_BIN=eMod-factory
DEBUG_LEVEL=4
FINAL_DIRECTORY=output/linux/release
ifeq ("$(DEBUG_LEVEL)","4")
	FINAL_DIRECTORY=output/linux/debug
endif

LINUX_DEFINES=\
	_DEBUG_LEVEL_=$(DEBUG_LEVEL) \
	__linux__ \
	__debug_messages__=1

LINUX_UNDEFINES=\

LINUX_INCLUDES=\
	../source/test \
	../source/factory \

APP_SOURCES=\
	../source/test \
	../source/factory \

LINUX_SOURCES=\
	
LINUX_LIBRARIES=\
	gtest \
	pthread

COMMON_FLAGS=\
	-c \
	-g \
	-fno-exceptions \
	-Wall \
	-Wextra 

LINUX_FLAGS=\

DEFINES=$(addprefix -D,$(LINUX_DEFINES))
UNDEFINES=$(addprefix -U,$(LINUX_UNDEFINES))
INCLUDES=$(addprefix -I,$(LINUX_INCLUDES))
SOURCES=$(APP_SOURCES) $(LINUX_SOURCES)
LIBRARIES=$(addprefix -l,$(LINUX_LIBRARIES))
COMPILER_FLAGS=$(COMMON_FLAGS) $(LINUX_FLAGS)
LINKER_FLAGS=

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
	$(CC) $(COMPILER_FLAGS) -std=c++1z $(DEFINES) $(UNDEFINES) $(INCLUDES) -o $@ $<

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.cpp  $(HPP_SOURCES) $(H_SOURCES)
	$(CXX) $(COMPILER_FLAGS) -std=c++1z $(DEFINES) $(UNDEFINES) $(INCLUDES) -o $@ $<

$(FINAL_DIRECTORY)/obj/%.o: $(FINAL_DIRECTORY)/src/%.s
	$(CXX) $(COMPILER_FLAGS) -lang-asm -o $@ $<

postlink:
	$(shell find -L $(FINAL_DIRECTORY)/src -maxdepth 1 -type l -delete)

clean:
	$(shell rm -f $(FINAL_DIRECTORY)/obj/*)
