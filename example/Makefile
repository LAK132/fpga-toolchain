include ../Makefile

BUILD_DIR=$(PWD)/build
BOARDS_DIR=$(PWD)/boards
SOURCE_DIR=$(PWD)/source

include ../board_def.mk

$(eval $(call DECLARE_XILINX_BOARD, \
mega65r3, artix7, xc7, xc7a200tfbg484-2, \
$(BOARDS_DIR)/mega65r3.xdc))

$(eval $(call DECLARE_VHDL_VERILOG_CORE, \
blink, "BLINK", "V1", \
blink, \
$(wildcard $(SOURCE_DIR)/*.v), \
$(wildcard $(SOURCE_DIR)/*.vhdl), blink))

include ../board_targets.mk
