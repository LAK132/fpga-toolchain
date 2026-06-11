all: blink-mega65r3.cor blink-orange-crab.bit blink-tinyfpga-bx.bin

.PHONY: all

include Makefile.conf
TOOLCHAIN_PREFIX?=/usr/local
include $(TOOLCHAIN_PREFIX)/share/lakfpga/toolchain.mk

# 1: Target board name
# 2: Bitstream name
# 3: Bitstream suffix
# 4: Torii script (.py) to run
# 5: Optional Makefile build dependencies
# 6: Optional Torii environment arguments (WX="AB" YZ="CD" etc)

$(eval $(call DECLARE_MEGA65,\
mega65r3,\
blink,\
.bit,\
source/mega65r3.py,\
xc7a200t,\
fbg484-2,\
))

$(eval $(call DECLARE_ECP5,\
orange-crab,\
blink,\
.bit,\
source/orange_crab.py,\
))

$(eval $(call DECLARE_ICE40,\
tinyfpga-bx,\
blink,\
.bin,\
source/tinyfpga_bx.py,\
))

clean:
	rm -rf $(BUILD_DIR)
