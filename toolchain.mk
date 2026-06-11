ifeq ($(dir $(lastword $(MAKEFILE_LIST))),./)
SELFDIR:=$(abspath $(PWD))
else
SELFDIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
endif

ifeq ($(SELFDIR),)
$(error Failed to set SELFDIR. \
	This may happen when running make with `sudo`, \
	try `sudo -E` instead)
endif

HOST_SYSTEM:=$(shell uname 2>/dev/null || echo Unknown)
# HOST_SYSTEM:=$(patsubst CYGWIN%,Cygwin,$(HOST_SYSTEM))
HOST_SYSTEM:=$(patsubst MSYS%,MSYS,$(HOST_SYSTEM))
HOST_SYSTEM:=$(patsubst MINGW%,MSYS,$(HOST_SYSTEM))
ifeq ($(HOST_SYSTEM),Linux)
ifneq ($(shell grep -a -h -i microsoft /proc/version),)
HOST_SYSTEM:=WSL
endif
endif
ifeq ($(HOST_SYSTEM),Unknown)
ifneq ($(OS),Windows_NT)
HOST_SYSTEM:=Windows
endif
endif
ifeq ($(HOST_SYSTEM),Unknown)
$(error Unable to determin host system)
endif
# Windows:      Windows
# Cygwin:       Windows with Linux-y build tools
# MSYS:         Native Windows binaries with Linux-y tools (https://stackoverflow.com/questions/37460073/msys-vs-mingw-internal-environment-variables)
# WSL:          Linux on Windows (this requires special handling for USB)
# Linux:        Linux
# Darwin:       Mac OS X

# It is recommended to use MSYS's UCRT shell (ucrt64.exe) over MSYS or MINGW

EXE:=
USB_EXE:=
DYN_LIB:=.so
STA_LIB:=.a
ifeq ($(HOST_SYSTEM),Windows)
EXE:=.exe
USB_EXE:=.exe
DYN_LIB:=.dll
STA_LIB:=.lib
endif
ifeq ($(HOST_SYSTEM),Cygwin)
EXE:=.exe
USB_EXE:=.exe
DYN_LIB:=.dll
STA_LIB:=.lib
endif
ifeq ($(HOST_SYSTEM),MSYS)
EXE:=.exe
USB_EXE:=.exe
DYN_LIB:=.dll
STA_LIB:=.lib
endif
ifeq ($(HOST_SYSTEM),WSL)
EXE:=
USB_EXE:=.exe
DYN_LIB:=.so
STA_LIB:=.a
endif

include $(SELFDIR)/Makefile.conf

INSTALL_PREFIX?=$(SELFDIR)/build
ARCHITECTURES?=XC7 ICE40 ECP5
BUILD_DIR?=build
# XC7FRAMES2BIT_OPTS?=--compressed

# openFPGALoader --list-cables
FLASH_CABLE?=bmd

ifeq ($(HOST_SYSTEM),WSL)
FLASH_PORT?=COM4
endif
ifeq ($(HOST_SYSTEM),Cygwin)
FLASH_PORT?=COM4
endif
ifeq ($(HOST_SYSTEM),MSYS)
FLASH_PORT?=COM4
endif
ifeq ($(HOST_SYSTEM),Windows)
FLASH_PORT?=COM4
endif
FLASH_PORT?=/dev/ttyACM0

TORII_OUTPUT_DIR=build

BINDIR=$(INSTALL_PREFIX)/bin
LIBDIR=$(INSTALL_PREFIX)/lib
INCDIR=$(INSTALL_PREFIX)/include
SHAREDIR=$(INSTALL_PREFIX)/share

ACTIVATE_VENV=$(BINDIR)/activate

GHDL=$(BINDIR)/ghdl$(EXE)

OPENFPGALOADER=$(BINDIR)/openFPGALoader$(USB_EXE)

CORETOOL=$(BINDIR)/coretool

NEXTPNR_ECP5=$(BINDIR)/nextpnr-ecp5$(EXE)
NEXTPNR_ICE40=$(BINDIR)/nextpnr-ice40$(EXE)
NEXTPNR_HIMBAECHEL_XILINX=$(BINDIR)/nextpnr-himbaechel-xilinx$(EXE)
NEXTPNR_SHARE=$(SHAREDIR)/nextpnr

ICEPACK=$(BINDIR)/icepack$(EXE)

ECPPACK=$(BINDIR)/ecppack$(EXE)

FASM2FRAMES=$(BINDIR)/fasm2frames
XC7FRAMES2BIT=$(BINDIR)/xc7frames2bit$(EXE)
XRAY_SHARE_DIR=$(SHAREDIR)/prjxray
XRAY_DB_DIR=$(XRAY_SHARE_DIR)/database
XRAY_ENV=$(XRAY_SHARE_DIR)/prjxray_env.sh

YOSYS=$(BINDIR)/yosys$(EXE)

VENV_PYTHON3=$(BINDIR)/python3$(EXE)

ARCH_XC7_DEPS=$(NEXTPNR_HIMBAECHEL_XILINX) $(XRAY_ENV) $(FASM2FRAMES) $(XC7FRAMES2BIT) $(CORETOOL)
ARCH_XC7_ENVS=\
NEXTPNR_HIMBAECHEL_XILINX="$(NEXTPNR_HIMBAECHEL_XILINX)"\
TORII_ENV_YOSYS_NEXTPNR="$(XRAY_ENV)" \
FASM2FRAMES="$(FASM2FRAMES)" \
XC7FRAMES2BIT="$(XC7FRAMES2BIT)" \
TORII_NEXTPNR_HIMBAECHEL_DB_DIR="$(NEXTPNR_SHARE)/himbaechel/xilinx" \
TORII_PRJXRAY_DB_DIR="$(XRAY_DB_DIR)" \
TORII_XC7FRAMES2BIT_OPTS="$(XC7FRAMES2BIT_OPTS)"

ARCH_ICE40_DEPS=$(NEXTPNR_ICE40) $(ICEPACK)
ARCH_ICE40_ENVS=NEXTPNR_ICE40="$(NEXTPNR_ICE40)" ICEPACK="$(ICEPACK)"

ARCH_ECP5_DEPS=$(NEXTPNR_ECP5) $(ECPPACK)
ARCH_ECP5_ENVS=NEXTPNR_ECP5="$(NEXTPNR_ECP5)" ECPPACK="$(ECPPACK)"

ALL_ARCH_DEPS=$(ACTIVATE_VENV) $(GHDL) $(YOSYS) $(foreach A,$(ARCHITECTURES),$(ARCH_$(strip $A)_DEPS) )
ALL_ARCH_ENVS=YOSYS="$(YOSYS)" $(foreach A,$(ARCHITECTURES),$(ARCH_$(strip $A)_ENVS) )

# --- generic targets ---

define DECLARE_CORE=
.PHONY: $(strip $2)-$(strip $1)$(strip $3)
$(strip $2)-$(strip $1)$(strip $3): $$(BUILD_DIR)/$(strip $1)/$(strip $2)/$$(TORII_OUTPUT_DIR)/top$(strip $3)
	cp -f $$< $$@

.PHONY: jtag-flash-$(strip $2)-$(strip $1)
jtag-flash-$(strip $2)-$(strip $1): $(strip $2)-$(strip $1)$(strip $3) | $$(OPENFPGALOADER)
ifeq ($$(HOST_SYSTEM),WSL)
	( cmd.exe /c `wslpath -w $$(OPENFPGALOADER)` --bitstream `wslpath -w $$<` --cable $$(FLASH_CABLE) --device $$(FLASH_PORT) 2> `wslpath -w $$(BUILD_DIR)/flash.log` )
else
	$$(OPENFPGALOADER) --bitstream $$< --cable $$(FLASH_CABLE) --device $$(FLASH_PORT) 2> $$(BUILD_DIR)/flash.log
endif

$$(BUILD_DIR)/$(strip $1)/$(strip $2):
	mkdir -p $$@

.PHONY: $$(BUILD_DIR)/$(strip $1)/$(strip $2)/$$(TORII_OUTPUT_DIR)/top$(strip $3)
$$(BUILD_DIR)/$(strip $1)/$(strip $2)/$$(TORII_OUTPUT_DIR)/top$(strip $3): $4 | $$(BUILD_DIR)/$(strip $1)/$(strip $2) $$(ALL_ARCH_DEPS)
	( cd $$(BUILD_DIR)/$(strip $1)/$(strip $2) && . $$(ACTIVATE_VENV) && $5 $$(ALL_ARCH_ENVS) $$(VENV_PYTHON3) $$(abspath $$<) )
endef

define DECLARE_MEGA65_CORE=
$(call DECLARE_CORE,$1,$2,$3,$4,$5)

.PHONY: $(strip $2)-$(strip $1).cor
$(strip $2)-$(strip $1).cor: $(strip $2)-$(strip $1)$(strip $3) | $$(CORETOOL)
	$$(CORETOOL) --build $$@ --bit $$< --target $(strip $1) --bit-name $(strip $2) --bit-version 1 --force
endef
