ifeq ($(dir $(lastword $(MAKEFILE_LIST))),./)
SELFDIR := $(abspath $(PWD))
else
SELFDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
endif

ifeq ($(SELFDIR),)
$(error Failed to set SELFDIR. \
	This may happen when running make with `sudo`, \
	try `sudo -E` instead)
endif

include $(SELFDIR)/Makefile.conf

INSTALL_PREFIX?=$(SELFDIR)/build
VIVADO_PREFIX?=/opt/Xilinx
AMARANTH_OUTPUT_DIR?=build

BINDIR=$(INSTALL_PREFIX)/bin
LIBDIR=$(INSTALL_PREFIX)/lib
SHAREDIR=$(INSTALL_PREFIX)/share

GHDL=$(BINDIR)/ghdl

ICEPACK=$(BINDIR)/icepack

BIT2CORE=$(BINDIR)/bit2core

NEXTPNR_ECP5=$(BINDIR)/nextpnr-ecp5
NEXTPNR_ICE40=$(BINDIR)/nextpnr-ice40

ECPPACK=$(BINDIR)/ecppack

NEXTPNR_XILINX=$(BINDIR)/nextpnr-xilinx
NEXTPNR_XILINX_SHARE=$(SHAREDIR)/nextpnr-xilinx
NEXTPNR_XILINX_PYTHON=$(NEXTPNR_XILINX_SHARE)/python
NEXTPNR_XILINX_META=$(NEXTPNR_XILINX_SHARE)/meta
BBAEXPORT=$(NEXTPNR_XILINX_PYTHON)/bbaexport.py
BBASM=$(BINDIR)/bbasm

FASM2FRAMES=$(BINDIR)/fasm2frames
XC7FRAMES2BIT=$(BINDIR)/xc7frames2bit
XRAY_SHARE_DIR=$(SHAREDIR)/prjxray
XRAYDBDIR=$(XRAY_SHARE_DIR)/database
XRAYENV=$(XRAY_SHARE_DIR)/prjxray_env.sh
NEXTPNRDBDIR=$(XRAY_SHARE_DIR)/build

YOSYS=$(BINDIR)/yosys

define DECLARE_CORE=
$(strip $1).$(strip $2)$(strip $3): build/$(strip $1)/$(strip $2)/$(AMARANTH_OUTPUT_DIR)/top$(strip $3)
	cp -f $$< $$@

build/$(strip $1)/$(strip $2):
	mkdir -p $$@

build/$(strip $1)/$(strip $2)/$(AMARANTH_OUTPUT_DIR)/top$(strip $3): \
$4 $5 | build/$(strip $1)/$(strip $2) \
$$(YOSYS) \
$$(NEXTPNR_XILINX) $$(XRAYENV) $$(FASM2FRAMES) $$(XC7FRAMES2BIT) \
$$(NEXTPNR_ECP5) $$(ECPPACK) \
$$(NEXTPNR_ICE40) $$(ICEPACK)
	( cd build/$(strip $1)/$(strip $2) && \
	$6 \
	YOSYS="$$(YOSYS)" \
	NEXTPNR_XILINX="$$(NEXTPNR_XILINX)" \
	AMARANTH_ENV_YOSYS_NEXTPNR="$$(XRAYENV)" \
	FASM2FRAMES="$$(FASM2FRAMES)" \
	XC7FRAMES2BIT="$$(XC7FRAMES2BIT)" \
	AMARANTH_nextpnr_db_dir="$$(NEXTPNRDBDIR)" \
	AMARANTH_prjxray_db_dir="$$(XRAYDBDIR)" \
	AMARANTH_xc7frames2bit_opts="--compressed" \
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
	python3 $$(BBAEXPORT) --metadata $$(NEXTPNR_XILINX_META)/$1 --xray $$(XRAYDBDIR)/$1 --device $$* --bba $$@

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
