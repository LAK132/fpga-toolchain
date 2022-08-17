all: mega65r3.blink.cor orange-crab.blink.bit tinyfpga-bx.blink.bin

.PHONY: all

include Makefile.conf
TOOLCHAIN_PREFIX?=/usr/local
include $(TOOLCHAIN_PREFIX)/share/lakfpga/toolchain.mk

# 1: Target board name
# 2: Bitstream name
# 3: Bitstream suffix
# 4: Amaranth script (.py) to run
# 5: Optional Makefile build dependencies
# 6: Optional Amaranth environment arguments (WX="AB" YZ="CD" etc)

$(eval $(call DECLARE_CORE,\
mega65r3,\
blink,\
.bit,\
source/mega65r3.py,\
artix7-xc7a200tfbg484-2,\
))

$(eval $(call DECLARE_CORE,\
orange-crab,\
blink,\
.bit,\
source/orange_crab.py,\
,\
))

$(eval $(call DECLARE_CORE,\
tinyfpga-bx,\
blink,\
.bin,\
source/tinyfpga_bx.py,\
,\
))

mega65r3.%.cor: mega65r3.%.bit Makefile.conf | $(BIT2CORE)
	$(BIT2CORE) mega65r3 $< $* "V1" $@

clean:
	rm -rf $(AMARANTH_OUTPUT_DIR)
