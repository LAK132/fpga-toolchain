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
VIVADO_PREFIX?=/opt/Xilinx
TORII_OUTPUT_DIR?=build

BINDIR=$(INSTALL_PREFIX)/bin
LIBDIR=$(INSTALL_PREFIX)/lib
SHAREDIR=$(INSTALL_PREFIX)/share

ACTIVATE_VENV=$(BINDIR)/activate

GHDL=$(BINDIR)/ghdl$(EXE)

ICEPACK=$(BINDIR)/icepack$(EXE)

OPENFPGALOADER=$(BINDIR)/openFPGALoader$(USB_EXE)

BIT2CORE=$(BINDIR)/bit2core$(EXE)

NEXTPNR_ECP5=$(BINDIR)/nextpnr-ecp5$(EXE)
NEXTPNR_ICE40=$(BINDIR)/nextpnr-ice40$(EXE)

ECPPACK=$(BINDIR)/ecppack$(EXE)

NEXTPNR_XILINX=$(BINDIR)/nextpnr-xilinx$(EXE)
NEXTPNR_XILINX_SHARE=$(SHAREDIR)/nextpnr-xilinx
NEXTPNR_XILINX_PYTHON=$(NEXTPNR_XILINX_SHARE)/python
NEXTPNR_XILINX_META=$(NEXTPNR_XILINX_SHARE)/meta
BBAEXPORT=$(NEXTPNR_XILINX_PYTHON)/bbaexport.py
BBASM=$(BINDIR)/bbasm$(EXE)

FASM2FRAMES=$(BINDIR)/fasm2frames$(EXE)
XC7FRAMES2BIT=$(BINDIR)/xc7frames2bit$(EXE)
XRAY_SHARE_DIR=$(SHAREDIR)/prjxray
XRAYDBDIR=$(XRAY_SHARE_DIR)/database
XRAYENV=$(XRAY_SHARE_DIR)/prjxray_env.sh
NEXTPNRDBDIR=$(XRAY_SHARE_DIR)/build

YOSYS=$(BINDIR)/yosys$(EXE)

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
FLASH_PORT?=/dev/ttyUSB1

# --- generic targets ---

define DECLARE_CORE=
$(strip $2)-$(strip $1)$(strip $3): build/$(strip $1)/$(strip $2)/$(TORII_OUTPUT_DIR)/top$(strip $3)
	cp -f $$< $$@

jtag-flash-$(strip $2)-$(strip $1): $(strip $2)-$(strip $1)$(strip $3) | $$(OPENFPGALOADER)
ifeq ($$(HOST_SYSTEM),WSL)
	( cmd.exe /c `wslpath -w $$(OPENFPGALOADER)` --bitstream `wslpath -w $$<` --cable $$(FLASH_CABLE) --device $$(FLASH_PORT) )
else
	$$(OPENFPGALOADER) --bitstream $$< --cable $$(FLASH_CABLE) --device $$(FLASH_PORT)
endif

build/$(strip $1)/$(strip $2):
	mkdir -p $$@

build/$(strip $1)/$(strip $2)/$(TORII_OUTPUT_DIR)/top$(strip $3): \
$4 $5 | build/$(strip $1)/$(strip $2) \
$$(YOSYS) \
$$(NEXTPNR_XILINX) $$(XRAYENV) $$(FASM2FRAMES) $$(XC7FRAMES2BIT) \
$$(NEXTPNR_ECP5) $$(ECPPACK) \
$$(NEXTPNR_ICE40) $$(ICEPACK)
	( cd build/$(strip $1)/$(strip $2) && . $$(ACTIVATE_VENV) && \
	$6 \
	YOSYS="$$(YOSYS)" \
	NEXTPNR_XILINX="$$(NEXTPNR_XILINX)" \
	TORII_ENV_YOSYS_NEXTPNR="$$(XRAYENV)" \
	FASM2FRAMES="$$(FASM2FRAMES)" \
	XC7FRAMES2BIT="$$(XC7FRAMES2BIT)" \
	TORII_NEXTPNR_DB_DIR="$$(NEXTPNRDBDIR)" \
	TORII_PRJXRAY_DB_DIR="$$(XRAYDBDIR)" \
	TORII_XC7FRAMES2BIT_OPTS="--compressed" \
	NEXTPNR_ECP5="$$(NEXTPNR_ECP5)"\
	ECPPACK="$$(ECPPACK)" \
	NEXTPNR_ICE40="$$(NEXTPNR_ICE40)" \
	ICEPACK="$$(ICEPACK)" \
	python3 $$(abspath $$<) )
endef

# --- Xilinx specific targets ---

$(NEXTPNRDBDIR):
	mkdir -p $@

define PRJXRAY_PART_BUILDER=
$$(NEXTPNRDBDIR)/%.bba: | $$(NEXTPNRDBDIR) $$(XRAYDBDIR)/$1/%
	( . $$(ACTIVATE_VENV) && python3 $$(BBAEXPORT) --metadata $$(NEXTPNR_XILINX_META)/$1 --xray $$(XRAYDBDIR)/$1 --device $$* --bba $$@ )

$$(NEXTPNRDBDIR)/%.bin: $$(NEXTPNRDBDIR)/%.bba | $$(NEXTPNRDBDIR)
	$$(BBASM) --le $$< $$@

$1-%.bba:
	$$(MAKE) $$(NEXTPNRDBDIR)/$$*.bba
$1-%.bin:
	$$(MAKE) $$(NEXTPNRDBDIR)/$$*.bin
$1-%:
	$$(MAKE) $$(NEXTPNRDBDIR)/$$*.bin
endef

$(foreach F,artix7 kintex7 spartan7 zynq7,$(eval $(call PRJXRAY_PART_BUILDER,$F)))
