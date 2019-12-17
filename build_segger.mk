
ifeq ($(DEBUG_LEVEL),4)
	OUTPUT:=$(OUTPUT)/debug
else
	OUTPUT:=$(OUTPUT)/release
endif

TOUTPUT:=$(OUTPUT)/$(TYPE)

DEFINES=$(addprefix -D,$(DEFINE))
UNDEFINES=$(addprefix -U,$(UNDEFINE))
INCLUDES=$(addprefix -I,$(INCLUDE))
LIBRARIES=$(LIBRARY)
SOURCES=$(APP_SOURCES) $(SDK_SOURCES) $(SYSTEM_SOURCES)

C_SOURCES=$(shell find -L $(SOURCE) -maxdepth 1 -name '*.c')
CPP_SOURCES=$(shell find -L $(SOURCE) -maxdepth 1 -name '*.cpp')
ASM_SOURCES=$(shell find -L $(SOURCE) -maxdepth 1 -name '*.s')
HPP_SOURCES=$(shell find -L $(INCLUDE) -maxdepth 1 -name '*.hpp')
H_SOURCES=$(shell find -L $(INCLUDE) -maxdepth 1 -name '*.h')

C_OBJECTS:=$(addprefix $(OUTPUT)/obj/, $(addsuffix .o,$(notdir $(basename ${C_SOURCES}))))
CPP_OBJECTS:=$(addprefix $(OUTPUT)/obj/, $(addsuffix .o,$(notdir $(basename ${CPP_SOURCES}))))
ASM_OBJECTS:=$(addprefix $(OUTPUT)/obj/, $(addsuffix .o,$(notdir $(basename ${ASM_SOURCES}))))
ifeq ($(TYPE),lib)
	C_OBJECTS:=$(subst $(OUTPUT)/obj/main.o,,$(C_OBJECTS))
	CPP_OBJECTS:=$(subst $(OUTPUT)/obj/main.o,,$(CPP_OBJECTS))
	ASM_OBJECTS:=$(subst $(OUTPUT)/obj/main.o,,$(ASM_OBJECTS))
endif

.PHONY: prelink link postlink

default: prelink link postlink

prelink:
	@mkdir -p $(OUTPUT)
	@mkdir -p $(OUTPUT)/bin
	@mkdir -p $(OUTPUT)/src
	@mkdir -p $(OUTPUT)/obj
	$(shell rm -f $(OUTPUT)/src/*.*)
	$(shell cp -f $(INC_MAKEFILE_PATH)/segger.ld $(OUTPUT)/obj/$(TARGET).ld)
	$(shell "./lnsrc.sh" "$(OUTPUT)/src" $(C_SOURCES))
	$(shell "./lnsrc.sh" "$(OUTPUT)/src" $(CPP_SOURCES))
	$(shell "./lnsrc.sh" "$(OUTPUT)/src" $(ASM_SOURCES))

link: $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS)
	@echo
	$(LD) $(LCXXFLAGS) --gc-sections "-T$(OUTPUT)/obj/$(TARGET).ld" -Map $(TOUTPUT)/$(TARGET).map -o $(TOUTPUT)/$(TARGET).elf --start-group $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS) $(LIBRARIES) --end-group
	@echo
	$(OBJCOPY) $(OUTPUT)/bin/$(TARGET).elf $(OUTPUT)/bin/$(TARGET).hex -Oihex	

$(OUTPUT)/obj/%.o: $(OUTPUT)/src/%.c $(HPP_SOURCES) $(H_SOURCES)
	$(CC) $(CXXFLAGS) -mtp=soft -std=gnu99 $(DEFINES) $(UNDEFINES) $(INCLUDES) -MD $(OUTPUT)/obj/$(addsuffix .d,$(notdir $(basename $@))) -MQ $@ $< -o $(OUTPUT)/obj/$(addsuffix .asm,$(notdir $(basename $@)))
	$(AS) $(ACXXFLAGS) $(OUTPUT)/obj/$(addsuffix .asm,$(notdir $(basename $@))) -o $@

$(OUTPUT)/obj/%.o: $(OUTPUT)/src/%.cpp $(HPP_SOURCES) $(H_SOURCES)
	$(CXX) $(CXXFLAGS) -fno-rtti -mtp=soft -std=c++1z $(DEFINES) $(UNDEFINES) $(INCLUDES) -MD $(OUTPUT)/obj/$(addsuffix .d,$(notdir $(basename $@))) -MQ $@ $< -o $(OUTPUT)/obj/$(addsuffix .asm,$(notdir $(basename $@)))
	$(AS) $(ACXXFLAGS) $(OUTPUT)/obj/$(addsuffix .asm,$(notdir $(basename $@))) -o $@

$(OUTPUT)/obj/%.o: $(OUTPUT)/src/%.s
	$(CC) $(SCXXFLAGS) -lang-asm -MD $(OUTPUT)/obj/$(addsuffix .d,$(notdir $(basename $@))) -MQ $@ $< -o $(OUTPUT)/obj/$(addsuffix _PP.s,$(notdir $(basename $@)))
	$(AS) $(ACXXFLAGS) $(OUTPUT)/obj/$(addsuffix _PP.s,$(notdir $(basename $@))) -o $@

postlink:
	$(shell find -L $(OUTPUT)/src -maxdepth 1 -type l -delete)

clean:
	$(shell rm -rvf $(OUTPUT)/src/*.*)
	$(shell rm -rvf $(OUTPUT)/obj/*.*)
	$(shell rm -rvf $(OUTPUT)/bin/*.*)
	$(shell rm -rvf $(OUTPUT)/lib/*.*)
