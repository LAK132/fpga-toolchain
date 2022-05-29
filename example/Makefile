include ../Makefile

BIN_DIR=bin
BOARDS_DIR=boards
TOOLS_DIR=tools
VERILOG_SRC_DIR=verilog
VHDL_SRC_DIR=vhdl

include ../board_def.mk

$(eval $(call DECLARE_XILINX_BOARD, \
mega65r3, artix7, xc7, xc7a200tfbg484-2, \
$(BOARDS_DIR)/mega65r3.xdc, \
blink, \
$(wildcard $(VHDL_SRC_DIR)/*.v), \
$(wildcard $(VHDL_SRC_DIR)/*.vhdl), blink))

include ../board_targets.mk

BIT2CORE=$(BIN_DIR)/bit2core
bit2core $(BIT2CORE): $(TOOLS_DIR)/bit2core.c
	gcc $< -o $(BIT2CORE)

define BIT2CORE_BUILDER=
$$(BIN_DIR)/$1.cor: $$(BIN_DIR)/$1.bit $$(BIT2CORE)
	$$(BIT2CORE) $1 $$< "BLINK" "V1" $$@
endef
$(foreach B,$(ALL_BOARDS),$(eval $(call BIT2CORE_BUILDER,$B)))
