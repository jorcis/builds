

ifeq ($(DEBUG_LEVEL),4)
	OUTPUT:=$(OUTPUT)/debug
	DEFINE:=$(DEFINE) \
		_DEBUG_LEVEL_=$(DEBUG_LEVEL) 
else
	OUTPUT:=$(OUTPUT)/release
endif

TOUTPUT:=$(OUTPUT)/$(TYPE)

DEFINES=$(addprefix -D,$(DEFINE))
UNDEFINES=$(addprefix -U,$(UNDEFINE))
INCLUDES=$(addprefix -I,$(INCLUDE))
LIBRARIES=$(LIBRARY)
ifeq ($(CXXENV), ARMGCC)
	LINKMAP=-Wl,-Map=${TOUTPUT}/$(TARGET).map
endif

C_SOURCES:=$(shell find -L $(SOURCE) -maxdepth 1 -name '*.c')
CPP_SOURCES:=$(shell find -L $(SOURCE) -maxdepth 1 -name '*.cpp')
ASM_SOURCES:=$(shell find -L $(SOURCE) -maxdepth 1 -name '*.s')
ASM_SOURCES:=$(ASM_SOURCES) $(shell find -L $(SOURCE) -maxdepth 1 -name '*.S')
ASM_SOURCES:=$(ASM_SOURCES) $(shell find -L $(SOURCE) -maxdepth 1 -name '*.asm')
HPP_SOURCES:=$(shell find -L $(INCLUDE) -maxdepth 1 -name '*.hpp')
H_SOURCES:=$(shell find -L $(INCLUDE) -maxdepth 1 -name '*.h')

C_OBJECTS:=$(addprefix $(OUTPUT)/obj/, $(addsuffix .o,$(notdir $(basename ${C_SOURCES}))))
CPP_OBJECTS:=$(addprefix $(OUTPUT)/obj/, $(addsuffix .o,$(notdir $(basename ${CPP_SOURCES}))))
ASM_OBJECTS:=$(addprefix $(OUTPUT)/obj/, $(addsuffix .o,$(notdir $(basename ${ASM_SOURCES}))))
ifneq ($(TYPE),$(subst lib,,$(TYPE)))
	C_OBJECTS:=$(subst $(OUTPUT)/obj/main.o,,$(C_OBJECTS))
	CPP_OBJECTS:=$(subst $(OUTPUT)/obj/main.o,,$(CPP_OBJECTS))
	ASM_OBJECTS:=$(subst $(OUTPUT)/obj/main.o,,$(ASM_OBJECTS))
endif
ifeq ($(TYPE),libso)
	LCXXFLAGS:=$(LCXXFLAGS) \
		-shared \
		-fPIC
endif
ifeq ($(TYPE),liba)
	LCXXFLAGS:=$(LCXXFLAGS) \
		-fPIC
endif

.PHONY: prelink link postlink

default: prelink link postlink

prelink:
	@mkdir -p $(OUTPUT)
	@mkdir -p $(OUTPUT)/bin
	@mkdir -p $(OUTPUT)/liba
	@mkdir -p $(OUTPUT)/libso
	@mkdir -p $(OUTPUT)/src
	@mkdir -p $(OUTPUT)/obj
	$(shell rm -f $(OUTPUT)/src/*.*)
	$(shell "./lnsrc.sh" $(OUTPUT)/src $(C_SOURCES))
	$(shell "./lnsrc.sh" $(OUTPUT)/src $(CPP_SOURCES))
	$(shell "./lnsrc.sh" $(OUTPUT)/src $(ASM_SOURCES))

link: $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS)
	@echo
	$(if $(CXX), $(CXX) $(LCXXFLAGS) $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS) $(LIBRARIES) $(LINKMAP) -o ${TOUTPUT}/$(TARGET)) $(STDLIB)
	@echo
	$(if $(SIZE), $(SIZE) ${TOUTPUT}/$(TARGET))
	$(if $(OBJCOPY), $(OBJCOPY) -O ihex ${TOUTPUT}/$(TARGET) ${TOUTPUT}/$(TARGET).hex)
	$(if $(OBJCOPY), $(OBJCOPY) -O binary $(TOUTPUT)/$(TARGET) ${TOUTPUT}/$(TARGET).bin)

$(OUTPUT)/obj/%.o: $(OUTPUT)/src/%.c $(HPP_SOURCES) $(H_SOURCES)
	$(CC) $(CXXFLAGS) -std=c99 $(DEFINES) $(UNDEFINES) $(INCLUDES) -o $@ $<

$(OUTPUT)/obj/%.o: $(OUTPUT)/src/%.cpp $(HPP_SOURCES) $(H_SOURCES)
	$(CXX) $(CXXFLAGS) -std=c++1z $(DEFINES) $(UNDEFINES) $(INCLUDES) -o $@ $<

$(OUTPUT)/obj/%.o: $(OUTPUT)/src/%.s
	$(CXX) $(ACXXFLAGS) -o $@ $<

postlink:
	$(shell find -L $(OUTPUT)/src -maxdepth 1 -type l -delete)

clean:
	$(shell rm -rvf $(OUTPUT)/src/*.*)
	$(shell rm -rvf $(OUTPUT)/obj/*.*)
	$(shell rm -rvf $(OUTPUT)/bin/*.*)
	$(shell rm -rvf $(OUTPUT)/lib/*.*)
