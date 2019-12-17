

#compilers
ifeq ($(CXXENV), ARMGCC)
	CXX:=arm-none-eabi-g++
	CC:=arm-none-eabi-gcc
	SIZE:=arm-none-eabi-size
	OBJCOPY:=arm-none-eabi-objcopy
	SDK:=/usr/src/nRF5_SDK_16.0.0
	OUTPUT:=output/armgcc
	BOOST:=/usr/src/boost_1_71_0
else ifeq ($(CXXENV), SEGGER)
	SEGGER_HOME:=/usr/share/segger_embedded_studio_for_arm_4.22
	CXX:=$(SEGGER_HOME)/gcc/arm-none-eabi/bin/cc1plus
	CC:=$(SEGGER_HOME)/gcc/arm-none-eabi/bin/cc1
	OBJCOPY:=$(SEGGER_HOME)/gcc/arm-none-eabi/bin/objcopy
	LD:=$(SEGGER_HOME)/gcc/arm-none-eabi/bin/ld
	AS:=$(SEGGER_HOME)/gcc/arm-none-eabi/bin/as
	SDK:=/usr/src/nRF5_SDK_16.0.0
	OUTPUT:=output/segger
	BOOST:=/usr/src/boost_1_71_0
else ifeq ($(CXXENV), VARISCITE)
	CXX:=arm-fslc-linux-gnueabi-g++
	CC:=arm-fslc-linux-gnueabi-gcc
	OUTPUT:=output/variscite
	BOOST:=/usr/src/boost_1_71_0
else ifeq ($(CXXENV), LINUX)
	CXX:=g++
	CC:=gcc
	OUTPUT:=output/linux
	BOOST:=/usr/src/boost_1_71_0
endif

#defines includes and others
ifdef SDK
	DEFINE=\
		_DEBUG_LEVEL_=$(DEBUG_LEVEL) \
		NRF52840_XXAA \
		BOARD_PCA10056 \
		BSP_DEFINES_ONLY \
		FLOAT_ABI_HARD \
		INITIALIZE_USER_SECTIONS \
		NO_VTOR_CONFIG \
		NRFX_GPIOTE_ENABLED \

	UNDEFINE=\
		DEBUG_NRF \
		DEBUG_NRF_USER
endif


ifeq ($(CXXENV), VARISCITE)
	DEFINE=\
		__linux__ \
		__variscite__

	CXXFLAGS=\
		-march=armv7-a \
		-mthumb \
		-mfpu=neon \
		-mfloat-abi=hard \
		--sysroot="/opt/fslc-framebuffer/2.6.2/sysroots/armv7at2hf-neon-fslc-linux-gnueabi" \

	LCXXFLAGS:=$(CXXFLAGS) \
		-L/opt/fslc-framebuffer/2.6.2/sysroots/armv7at2hf-neon-fslc-linux-gnueabi/usr/lib \

	CXXFLAGS:=$(CXXFLAGS) \
		-c \
		-g \
		-fno-exceptions \
		-Wall \
		-Wextra \

else ifeq ($(CXXENV), LINUX)	
	DEFINE=\
		__linux__ \

	CXXFLAGS=\
		-c \
		-g \
		-fno-exceptions \
		-Wall \
		-Wextra 

	LCXXFLAGS:=\

else ifeq ($(CXXENV), ARMGCC)
	CXXFLAGS=\
		-mcpu=cortex-m4 \
		-mthumb \
		-mabi=aapcs \
		-mfloat-abi=hard \
		-mfpu=fpv4-sp-d16 \
		-O3 \
		-g3 \

	LCXXFLAGS:=$(CXXFLAGS) \
		-L$(SDK)/modules/nrfx/mdk \
		-T$(INC_MAKEFILE_PATH)/armgcc.ld \
		-Wl,--gc-sections \
		--specs=nosys.specs \
		-lc \
		-lnosys \
		-lm \

	CXXFLAGS:=$(CXXFLAGS)\
		-Wall \
		-Wextra \
		-ffunction-sections \
		-fdata-sections \
		-fno-strict-aliasing \
		-fno-builtin \
		-fshort-enums \
		-fno-exceptions \
		-MP \
		-MD \
		-c \
		-D__HEAP_SIZE=8192 \
		-D__STACK_SIZE=8192 \

	ACXXFLAGS:=$(CXXFLAGS) \
		-x assembler-with-cpp 

else ifeq ($(CXXENV), SEGGER)
	CXXFLAGS=\
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
		-quiet \

	ACXXFLAGS:=\
		-mcpu=cortex-m4 \
		-mlittle-endian \
		-mfloat-abi=hard \
		-mfpu=fpv4-sp-d16 \
		-mthumb \
		-g \
		-gdwarf-4 \

	SCXXFLAGS:=$(CXXFLAGS) \
		-E
		
	CXXFLAGS:=$(CXXFLAGS) \
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

	LCXXFLAGS:=\
		-X \
		--omagic \
		-eReset_Handler \
		--defsym=__vfprintf=__vfprintf_long \
		--defsym=__vfscanf=__vfscanf_long \
		-EL \
		-u_vectors \
		--emit-relocs \

endif

