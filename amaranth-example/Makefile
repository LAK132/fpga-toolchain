# make blink.mega65r3.cor
# make blink.orange-crab.bit

include Makefile.conf
PREFIX?=/usr/local
include $(PREFIX)/share/lakfpga/toolchain.mk

$(eval $(call DECLARE_CORE,blink.mega65r3,\
source/mega65r3.py,\
artix7-xc7a200tfbg484-2,\
))

$(eval $(call DECLARE_CORE,blink.orange-crab,\
source/orange_crab.py,\
,\
))
