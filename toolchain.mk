ifeq ($(dir $(lastword $(MAKEFILE_LIST))),./)
SELFDIR := $(abspath $(PWD))
else
SELFDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
endif

include $(SELFDIR)/Makefile.conf

INSTALL_PREFIX?=$(SELFDIR)/build
VIVADO_PREFIX?=/opt/Xilinx

BINDIR=$(INSTALL_PREFIX)/bin
LIBDIR=$(INSTALL_PREFIX)/lib
SHAREDIR=$(INSTALL_PREFIX)/share

GHDL=$(BINDIR)/ghdl

NEXTPNR_ECP5=$(BINDIR)/nextpnr-ecp5

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
$1: $2 $3 | $$(YOSYS) $$(NEXTPNR_XILINX) $$(NEXTPNR_ECP5) $$(ECPPACK)
	$4 \
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
	python3 $$<
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
