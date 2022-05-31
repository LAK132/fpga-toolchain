include ../Makefile

BUILD_DIR=build
BOARDS_DIR=boards
TOOLS_DIR=tools
SRC_DIR=source
BIN_DIR=$(PWD)/bin

include ../board_def.mk

$(eval $(call DECLARE_XILINX_BOARD, mega65r3, artix7, xc7, xc7a200tfbg484-2))

include ../board_targets.mk

define BUILDER=
$$(BUILD_DIR)/blink.bit: $$(SRC_DIR)/blink.py | $$(XILINX_BIN_DIR)/$$($1_FPGA_PART).bin $$(YOSYS) $$(NEXTPNR_XILINX) $$(FASM2FRAMES) $$(XC7FRAMES2BIT) $$(XRAYENV) $$(XRAYDBDIR)/$$($1_FPGA_FAMILY)/$$($1_FPGA_PART)
	YOSYS="$$(YOSYS)" \
	NEXTPNR_XILINX="$$(NEXTPNR_XILINX)" \
	XRAYENV="$$(XRAYENV)" \
	FASM2FRAMES="$$(PWD)/../fasm2frames.sh" \
	ACTUALFASM2FRAMES="$$(FASM2FRAMES)" \
	XC7FRAMES2BIT="$$(XC7FRAMES2BIT)" \
	AMARANTH_nextpnr_db_dir="$$(XILINX_BIN_DIR)" \
	AMARANTH_prjxray_db_dir="$$(XRAYDBDIR)" \
	python3 $$(SRC_DIR)/blink.py
endef
$(foreach B,$(XILINX_BOARDS),$(eval $(call BUILDER,$B)))

BIT2CORE=$(BIN_DIR)/bit2core
bit2core $(BIT2CORE): $(TOOLS_DIR)/bit2core.c
	gcc $< -o $(BIT2CORE)

define BIT2CORE_BUILDER=
$1.cor: $$(BUILD_DIR)/$1.cor
$$(BUILD_DIR)/$1.cor: $$(BUILD_DIR)/blink.bit $$(BIT2CORE)
	$$(BIT2CORE) $1 $$< "ETHER BLINK" "V1" $$@
endef
$(foreach B,$(ALL_BOARDS),$(eval $(call BIT2CORE_BUILDER,$B)))
