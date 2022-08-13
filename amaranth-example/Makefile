# make blink.mega65r3.cor
# make blink.orange-crab.bit

include ../Makefile

BUILD_DIR=$(PWD)/build
SOURCE_DIR=$(PWD)/source
BOARDS_DIR=$(SOURCE_DIR)/boards

include ../board_def.mk

$(eval $(call DECLARE_XILINX_BOARD, mega65r3, artix7, xc7, xc7a200tfbg484-2))
$(eval $(call DECLARE_LATTICE_BOARD, orange-crab, ECP5, LFE5U-25F-8MG285C))

$(eval $(call DECLARE_AMARANTH_CORE, \
blink, "BLINK", "V1", \
$(SOURCE_DIR)/blink.py, \
$(wildcard $(SOURCE_DIR)/*.py)))

include ../board_targets.mk
