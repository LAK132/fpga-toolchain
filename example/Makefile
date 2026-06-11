include Makefile.conf
TOOLCHAIN_PREFIX?=/usr/local
include $(TOOLCHAIN_PREFIX)/share/lakfpga/toolchain.mk

.PHONY: all-ECP5 all-ICE40 all-XC7 all
all-ECP5: blink-tinyfpga-bx.bin
all-ICE40: blink-orange-crab.bit
all-XC7: blink-mega65r3.cor verilog-blink-mega65r3.cor vhdl-blink-mega65r3.cor
all: $(foreach A,$(ARCHITECTURES),all-$(strip $A) )

# 1: Target board name
# 2: Bitstream name
# 3: Bitstream suffix
# 4: Torii script (.py) to run (followed by optional Makefile build dependencies, space separated)
# 5: Optional Torii environment arguments (WX="AB" YZ="CD" etc)

$(eval $(call DECLARE_MEGA65_CORE,\
mega65r3,\
blink,\
.bit,\
source/mega65r3.py,\
))

$(eval $(call DECLARE_MEGA65_CORE,\
mega65r3,\
verilog-blink,\
.bit,\
source/mega65r3.py,\
))

$(eval $(call DECLARE_MEGA65_CORE,\
mega65r3,\
vhdl-blink,\
.bit,\
source/mega65r3.py,\
))

$(eval $(call DECLARE_CORE,\
orange-crab,\
blink,\
.bit,\
source/orange_crab.py,\
))

$(eval $(call DECLARE_CORE,\
tinyfpga-bx,\
blink,\
.bin,\
source/tinyfpga_bx.py,\
))

clean:
	rm -rf $(BUILD_DIR)
