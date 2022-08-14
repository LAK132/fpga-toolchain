ifeq ($(dir $(lastword $(MAKEFILE_LIST))),./)
SELFDIR := $(abspath $(PWD))
else
SELFDIR := $(abspath $(PWD)/$(dir $(lastword $(MAKEFILE_LIST))))
endif

AMARANTH_PREFIX=$(SELFDIR)/amaranth

AMARANTH_BOARDS_PREFIX=$(SELFDIR)/amaranth-boards

YOSYS_PREFIX=$(SELFDIR)/yosys
YOSYS=$(YOSYS_PREFIX)/yosys

NEXTPNR_PREFIX=$(SELFDIR)/nextpnr
NEXTPNR_ECP5=$(NEXTPNR_PREFIX)/nextpnr-ecp5

NEXTPNR_XILINX_PREFIX=$(SELFDIR)/nextpnr-xilinx
NEXTPNR_XILINX=$(NEXTPNR_XILINX_PREFIX)/nextpnr-xilinx
BBAEXPORT=$(NEXTPNR_XILINX_PREFIX)/xilinx/python/bbaexport.py
BBASM=$(NEXTPNR_XILINX_PREFIX)/bbasm

GHDL_PREFIX=$(SELFDIR)/ghdl
GHDL_BUILD=$(GHDL_PREFIX)/build
GHDL_MCODE=$(GHDL_PREFIX)/ghdl_mcode
GHDL_BIN=$(GHDL_BUILD)/bin
GHDL_LIB=$(GHDL_BUILD)/lib
GHDL=$(GHDL_BIN)/ghdl

GHDL_YOSYS_PLUGIN_PREFIX=$(SELFDIR)/ghdl-yosys-plugin

PRJTRELLIS_PREFIX=$(SELFDIR)/prjtrellis
LIBTRELLIS_PREFIX=$(PRJTRELLIS_PREFIX)/libtrellis
TRELLISDBDIR=$(PRJTRELLIS_PREFIX)/database
TRELLIS_INSTALL_PREFIX=$(SELFDIR)/trellis
PYTRELLIS=$(TRELLIS_INSTALL_PREFIX)/lib/trellis/pytrellis.so
ECPPACK=$(TRELLIS_INSTALL_PREFIX)/bin/ecppack

PRJXRAY_PREFIX=$(SELFDIR)/prjxray
XRAYENV=$(SELFDIR)/prjxray_env.sh
FASM2FRAMES=$(PRJXRAY_PREFIX)/utils/fasm2frames.py
FASM2FRAMES_SH=$(SELFDIR)/fasm2frames.sh
XC7FRAMES2BIT=$(PRJXRAY_PREFIX)/build/tools/xc7frames2bit
XRAYDBDIR=$(PRJXRAY_PREFIX)/database

VIVADO_PREFIX=/opt/Xilinx

MEGA65_TOOLS_DIR=$(SELFDIR)/mega65-tools
BIT2CORE=$(MEGA65_TOOLS_DIR)/bin/bit2core

all: force-amaranth $(GHDL_YOSYS_DEPEND) $(NEXTPNR_XILINX) $(XRAYDBDIR) $(XC7FRAMES2BIT) $(BIT2CORE)
submodules: amaranth-submodule amaranth-boards-submodule yosys-submodule prjtrellis-submodule prjxray-submodule nextpnr-submodule nextpnr-xilinx-submodule ghdl-submodule ghdl-yosys-submodule mega65-tools-submodule
.PHONY: all

install_dependencies:
	apt install build-essential clang bison flex libreadline-dev gawk tcl-dev \
	libffi-dev git graphviz xdot pkg-config gcc g++ gnat cmake virtualenv \
	python3 python3-pip python3-yaml python3-venv python3-virtualenv \
	libboost-system-dev libboost-python-dev libboost-filesystem-dev \
	libboost-thread-dev libboost-program-options-dev libboost-iostreams-dev \
	zlib1g-dev qtbase5-dev libqt5gui5 libeigen3-dev ccache dfu-util

# --- amaranth ---

amaranth-submodule: $(AMARANTH_PREFIX)/setup.py
$(AMARANTH_PREFIX)/setup.py:
	( cd $(SELFDIR) && git submodule update --init $(AMARANTH_PREFIX) )

force-amaranth: $(AMARANTH_PREFIX)/setup.py
	( cd $(AMARANTH_PREFIX) && python3 -m pip install --editable . )

# --- amaranth-boards ---

amaranth-boards-submodule: $(AMARANTH_BOARDS_PREFIX)/setup.py
$(AMARANTH_BOARDS_PREFIX)/setup.py:
	( cd $(SELFDIR) && git submodule update --init $(AMARANTH_BOARDS_PREFIX) )

force-amaranth-boards: $(AMARANTH_BOARDS_PREFIX)/setup.py
	( cd $(AMARANTH_BOARDS_PREFIX) && python3 -m pip install --editable . )

# --- yosys ---

yosys-submodule: $(YOSYS_PREFIX)/Makefile
$(YOSYS_PREFIX)/Makefile:
	( cd $(SELFDIR) && git submodule update --init $(YOSYS_PREFIX) )

$(YOSYS_PREFIX)/frontends/ghdl: | $(YOSYS_PREFIX)/frontends
	mkdir -p $@

$(YOSYS_PREFIX)/frontends/ghdl/%: $(GHDL_YOSYS_PLUGIN_PREFIX)/src/% | $(YOSYS_PREFIX)/frontends/ghdl
	cp -f $< $@

$(YOSYS_PREFIX)/Makefile.conf: $(YOSYS_PREFIX)/Makefile $(YOSYS_PREFIX)/frontends/ghdl/Makefile.inc $(YOSYS_PREFIX)/frontends/ghdl/ghdl.cc $(GHDL)
	( cd $(YOSYS_PREFIX) && $(MAKE) config-gcc && echo 'ENABLE_CCACHE := 1' >> Makefile.conf && echo 'ENABLE_GHDL := 1' >> Makefile.conf && echo 'GHDL_PREFIX := $(GHDL_BUILD)' >> Makefile.conf && echo 'CXXFLAGS ?= -I"$(shell $(GHDL) --libghdl-include-dir)"' >> Makefile.conf )

force-yosys $(YOSYS): $(YOSYS_PREFIX)/Makefile.conf
	( cd $(YOSYS_PREFIX) && $(MAKE) )

# --- prjtrellis ---

prjtrellis-submodule: $(LIBTRELLIS_PREFIX)/CMakeLists.txt
$(LIBTRELLIS_PREFIX)/CMakeLists.txt:
	( cd $(SELFDIR) && git submodule update --init --recursive $(PRJTRELLIS_PREFIX) )

$(LIBTRELLIS_PREFIX)/Makefile: $(LIBTRELLIS_PREFIX)/CMakeLists.txt
	( cd $(LIBTRELLIS_PREFIX) && cmake -DCMAKE_INSTALL_PREFIX=$(TRELLIS_INSTALL_PREFIX) . )

force-prjtrellis $(PYTRELLIS): $(LIBTRELLIS_PREFIX)/Makefile
	( cd $(LIBTRELLIS_PREFIX) && $(MAKE) && $(MAKE) install )

# To depend on this correctly, you must depend on
# $(TRELLISDBDIR)/<FAMILY>/<PART>
# example: $(TRELLISDBDIR)/ECP5/LFE5U-25F
.PRECIOUS: $(TRELLISDBDIR)/%
$(TRELLISDBDIR): $(LIBTRELLIS_PREFIX)/Makefile
$(TRELLISDBDIR)/%: $(LIBTRELLIS_PREFIX)/Makefile
	( cd $(PRJTRELLIS_PREFIX) && git submodule update --init $(TRELLISDBDIR) )

# --- prjxray ---

prjxray-submodule: $(PRJXRAY_PREFIX)/Makefile
$(PRJXRAY_PREFIX)/Makefile:
	( cd $(SELFDIR) && git submodule update --init $(PRJXRAY_PREFIX) ) && \
	( cd $(PRJXRAY_PREFIX) && git submodule update --init --recursive )

force-prjxray $(PRJXRAY_PREFIX)/build: $(PRJXRAY_PREFIX)/Makefile
	( cd $(PRJXRAY_PREFIX) && $(MAKE) build && $(MAKE) env )

$(FASM2FRAMES): $(PRJXRAY_PREFIX)/build
$(XC7FRAMES2BIT): $(PRJXRAY_PREFIX)/build

$(XRAYENV): $(SELFDIR)/prjxray_settings.sh
	@echo "export XRAY_VIVADO_SETTINGS=$<;source $(PRJXRAY_PREFIX)/utils/environment.sh" > $@ && chmod +x $@

# To depend on this correctly, you must depend on $(XRAYDBDIR)/<FAMILY>/<PART>
# example: $(XRAYDBDIR)/artix7/xc7a100tcsg324-1
.PRECIOUS: $(XRAYDBDIR)/%
$(XRAYDBDIR): $(PRJXRAY_PREFIX)/Makefile
$(XRAYDBDIR)/%: $(PRJXRAY_PREFIX)/Makefile
	( cd $(PRJXRAY_PREFIX) && ./download-latest-db.sh )

# --- nextpnr ---

nextpnr-submodule: $(NEXTPNR_PREFIX)/CMakeLists.txt
$(NEXTPNR_PREFIX)/CMakeLists.txt:
	( cd $(SELFDIR) && git submodule update --init $(NEXTPNR_PREFIX) ) && \
	( cd $(NEXTPNR_PREFIX) && git submodule update --init )

$(NEXTPNR_PREFIX)/Makefile: $(NEXTPNR_PREFIX)/CMakeLists.txt $(PYTRELLIS)
	( cd $(NEXTPNR_PREFIX) && cmake -DARCH=ecp5 -DTRELLIS_INSTALL_PREFIX=$(TRELLIS_INSTALL_PREFIX) . )

force-nextpnr-ecp5 $(NEXTPNR_ECP5): $(NEXTPNR_PREFIX)/Makefile
	( cd $(NEXTPNR_PREFIX) && $(MAKE) )

# --- nextpnr-xilinx ---

nextpnr-xilinx-submodule: $(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt
$(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt:
	( cd $(SELFDIR) && git submodule update --init $(NEXTPNR_XILINX_PREFIX) ) && \
	( cd $(NEXTPNR_XILINX_PREFIX) && git submodule update --init )

$(NEXTPNR_XILINX_PREFIX)/Makefile: $(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt
	( cd $(NEXTPNR_XILINX_PREFIX) && cmake -DARCH=xilinx . )

force-nextpnr-xilinx $(NEXTPNR_XILINX): $(NEXTPNR_XILINX_PREFIX)/Makefile
	( cd $(NEXTPNR_XILINX_PREFIX) && $(MAKE) )

$(BBAEXPORT): $(NEXTPNR_XILINX)
$(BBASM): $(NEXTPNR_XILINX)

# --- ghdl ---

ghdl-submodule: $(GHDL_PREFIX)/configure
$(GHDL_PREFIX)/configure:
	( cd $(SELFDIR) && git submodule update --init $(GHDL_PREFIX) )

$(GHDL_PREFIX)/Makefile: $(GHDL_PREFIX)/configure
	( cd $(GHDL_PREFIX) && ./configure --prefix="$(GHDL_BUILD)" )

$(GHDL_MCODE): $(GHDL_PREFIX)/Makefile
	( cd $(GHDL_PREFIX) && $(MAKE) OPT_FLAGS=-fPIC )

force-ghdl $(GHDL): $(GHDL_MCODE)
	( cd $(GHDL_PREFIX) && $(MAKE) install )

# --- ghdl-yosys-plugin ---

ghdl-yosys-submodule: $(GHDL_YOSYS_PLUGIN_PREFIX)/src
$(GHDL_YOSYS_PLUGIN_PREFIX)/src/%: | $(GHDL_YOSYS_PLUGIN_PREFIX)/src
$(GHDL_YOSYS_PLUGIN_PREFIX)/src:
	( cd $(SELFDIR) && git submodule update --init $(GHDL_YOSYS_PLUGIN_PREFIX) )

# --- mega65-tools ---

mega65-tools-submodule: $(MEGA65_TOOLS_DIR)/Makefile
$(MEGA65_TOOLS_DIR)/Makefile:
	( cd $(SELFDIR) && git submodule update --init $(MEGA65_TOOLS_DIR) )

force-bit2core $(BIT2CORE): $(MEGA65_TOOLS_DIR)/Makefile
	( cd $(MEGA65_TOOLS_DIR) && $(MAKE) bin/bit2core )

# --- clean ---

clean-ghdl:
	( cd $(GHDL_PREFIX) && ( $(MAKE) clean ; git clean -xdf ) || echo 'ghdl clean failed' )

clean-ghdl-yosys:
	( cd $(GHDL_YOSYS_PLUGIN_PREFIX) && $(MAKE) clean || echo 'ghdl-yosys clean failed' )

clean-nextpnr-xilinx:
	( cd $(NEXTPNR_XILINX_PREFIX) && $(MAKE) clean || echo 'nextpnr-xilinx clean failed' )

clean-prjxray:
	( cd $(PRJXRAY_PREFIX) && ( $(MAKE) clean ; ( cd database && $(MAKE) reset ) ) || echo 'prjxray clean failed' )
	rm -rf prjxray_env.sh

clean-yosys:
	( cd $(YOSYS_PREFIX) && ( $(MAKE) clean ; rm Makefile.conf ) || echo 'yosys clean failed' )

clean-mega65-tools:
	( cd $(MEGA65_TOOLS_DIR) && $(MAKE) clean || echo 'mega65-tools clean failed' )

clean: clean-ghdl clean-ghdl-yosys clean-yosys clean-nextpnr-xilinx clean-prjxray clean-mega65-tools
