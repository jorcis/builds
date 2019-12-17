
include $(INC_MAKEFILE_PATH)/environment.mk

TARGET=factory
## bin liba (static) libso (dinamic)
TYPE=bin
DEBUG_LEVEL=4

INCLUDE:=\
	../source \
	../source/factory \
	../source/uart/nrf52840 \
	../source/uart/common \
	../config \

SOURCE:=\
	../source/test/main.cpp \
	../source/factory \

LIBRARY=\


ifeq ($(CXXENV), VARISCITE)
	DEFINE:=$(DEFINE) \
		__debug_messages__=1

	STDLIB:=\
		-lstdc++ \
		-lrt \

else ifeq ($(CXXENV), LINUX)
	DEFINE:=$(DEFINE) \
		__debug_messages__=1

	STDLIB:=\
		-lgtest \
		-lpthread

else ifeq ($(CXXENV), ARMGCC)

	INCLUDE:=$(INCLUDE) \
		$(SDK)/include \
		$(SDK)/modules/nrfx \
		$(SDK)/integration/nrfx \
		$(SDK)/modules/nrfx/drivers/src \

	SOURCE:=$(SOURCE) \
		../source/uart/nrf52840 \
		$(SDK)/modules/nrfx/drivers/src/nrfx_gpiote.c \
		$(SDK)/modules/nrfx/drivers/src/nrfx_timer.c \
		$(SDK)/modules/nrfx/mdk/system_nrf52840.c \
		$(SDK)/modules/nrfx/mdk/gcc_startup_nrf52840.S \

else ifeq ($(CXXENV), SEGGER)

	INCLUDE:=$(INCLUDE) \
		$(SDK)/include \
		$(SDK)/modules/nrfx \
		$(SDK)/integration/nrfx \
		$(SDK)/modules/nrfx/drivers/src \

	SOURCE:=$(SOURCE) \
		../source/uart/nrf52840 \
		$(SDK)/modules/nrfx/drivers/src/nrfx_gpiote.c \
		$(SDK)/modules/nrfx/drivers/src/nrfx_timer.c \
		$(SDK)/modules/nrfx/mdk/system_nrf52840.c \
		$(SDK)/modules/nrfx/mdk/ses_startup_nrf52840.s \
		$(SDK)/modules/nrfx/mdk/ses_startup_nrf_common.s \
		$(SEGGER_HOME)/source/thumb_crt0.s \

	LIBRARY:=$(LIBRARY) \
		$(SEGGER_HOME)/lib/libdebugio_mempoll_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
		$(SEGGER_HOME)/lib/libm_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
		$(SEGGER_HOME)/lib/libc_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
		$(SEGGER_HOME)/lib/libcpp_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
		$(SEGGER_HOME)/lib/libdebugio_v7em_fpv4_sp_d16_hard_t_le_eabi.a \
		$(SEGGER_HOME)/lib/libvfprintf_v7em_fpv4_sp_d16_hard_t_le_eabi.o \
		$(SEGGER_HOME)/lib/libvfscanf_v7em_fpv4_sp_d16_hard_t_le_eabi.o \

endif

ifeq ($(CXXENV), SEGGER)

	ifeq ($(DEBUG_LEVEL), 4)
		CXXFLAGS:=$(CXXFLAGS) \
			-DDEBUG "-D DEBUG_NRF"
	else
		CXXFLAGS:=$(CXXFLAGS) \
			-DNDEBUG
	endif

endif

ifeq ($(CXXENV), SEGGER)
	include $(INC_MAKEFILE_PATH)/build_segger.mk
else
	include $(INC_MAKEFILE_PATH)/build.mk
endif