include ../Makefile

BUILD_DIR=$(PWD)/build
SOURCE_DIR=$(PWD)/source
BOARDS_DIR=$(SOURCE_DIR)/boards

include ../board_def.mk

$(eval $(call DECLARE_XILINX_BOARD, mega65r3, artix7, xc7, xc7a200tfbg484-2))

$(eval $(call DECLARE_AMARANTH_CORE, \
blink, "BLINK", "V1", \
$(SOURCE_DIR)/blink.py, \
$(wildcard $(SOURCE_DIR)/*.py) \
$(wildcard $(SOURCE_DIR)/boards/*.py)))

include ../board_targets.mk
