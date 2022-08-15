include toolchain.mk

# --- Submodule locations ---

AMARANTH_PREFIX=$(SELFDIR)/amaranth
AMARANTH_BOARDS_PREFIX=$(SELFDIR)/amaranth-boards
FASM2BIT_PREFIX=$(SELFDIR)/fasm2bit
GHDL_PREFIX=$(SELFDIR)/ghdl
GHDL_YOSYS_PLUGIN_PREFIX=$(SELFDIR)/ghdl-yosys-plugin
MEGA65_TOOLS_PREFIX=$(SELFDIR)/mega65-tools
NEXTPNR_PREFIX=$(SELFDIR)/nextpnr
NEXTPNR_XILINX_PREFIX=$(SELFDIR)/nextpnr-xilinx
PRJTRELLIS_PREFIX=$(SELFDIR)/prjtrellis
PRJXRAY_PREFIX=$(SELFDIR)/prjxray
YOSYS_PREFIX=$(SELFDIR)/yosys

# ---

FASM2BIT_BUILD=$(FASM2BIT_PREFIX)/build
FASM2BIT=$(FASM2BIT_BUILD)/fasm2bit

MEGA65_TOOLS_PREFIX=$(SELFDIR)/mega65-tools
BIT2CORE=$(MEGA65_TOOLS_PREFIX)/bin/bit2core

LIBTRELLIS_PREFIX=$(PRJTRELLIS_PREFIX)/libtrellis
TRELLISDBDIR=$(SHAREDIR)/trellis/database
PYTRELLIS=$(LIBDIR)/trellis/pytrellis.so

FASM2FRAMES=$(PRJXRAY_PREFIX)/utils/fasm2frames.py
FASM2FRAMES_SH=$(SELFDIR)/fasm2frames.sh

LAKFPGA_PREFIX=$(SHAREDIR)/lakfpga

ALL_TOOLS=\
$(GHDL) \
$(NEXTPNR_ECP5) \
$(ECPPACK) \
$(NEXTPNR_XILINX) \
$(BBAEXPORT) \
$(BBASM) \
$(XC7FRAMES2BIT) \
$(YOSYS)

ALL_DEPENDS=\
$(ALL_TOOLS) \
$(NEXTPNR_XILINX_META) \
$(XRAYDBDIR) \
$(XRAYENV)

all: submodules
	$(MAKE) $(ALL_DEPENDS) install-lakfpga && \
	$(MAKE) -j1 force-amaranth force-amaranth-boards

submodules:
	$(MAKE) -j1 amaranth-submodule \
	amaranth-boards-submodule \
	yosys-submodule \
	prjtrellis-submodule \
	prjxray-submodule \
	nextpnr-submodule \
	nextpnr-xilinx-submodule \
	ghdl-submodule \
	ghdl-yosys-submodule \
	mega65-tools-submodule

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

force-deinit-amaranth-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(AMARANTH_PREFIX) )

force-amaranth: $(AMARANTH_PREFIX)/setup.py
	( cd $(AMARANTH_PREFIX) && python3 -m pip install --editable . )

# --- amaranth-boards ---

amaranth-boards-submodule: $(AMARANTH_BOARDS_PREFIX)/setup.py
$(AMARANTH_BOARDS_PREFIX)/setup.py:
	( cd $(SELFDIR) && git submodule update --init $(AMARANTH_BOARDS_PREFIX) )

force-deinit-amaranth-boards-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(AMARANTH_BOARDS_PREFIX) )

force-amaranth-boards: $(AMARANTH_BOARDS_PREFIX)/setup.py
	( cd $(AMARANTH_BOARDS_PREFIX) && python3 -m pip install --editable . )

# --- yosys ---

yosys-submodule: $(YOSYS_PREFIX)/Makefile
$(YOSYS_PREFIX)/Makefile:
	( cd $(SELFDIR) && git submodule update --init $(YOSYS_PREFIX) )

force-deinit-yosys-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(YOSYS_PREFIX) )

$(YOSYS_PREFIX)/frontends/ghdl: | $(YOSYS_PREFIX)/Makefile $(YOSYS_PREFIX)/frontends
	mkdir -p $@

$(YOSYS_PREFIX)/frontends/ghdl/%: $(GHDL_YOSYS_PLUGIN_PREFIX)/src/% | $(YOSYS_PREFIX)/frontends/ghdl
	cp -f $< $@

$(YOSYS_PREFIX)/Makefile.conf: $(YOSYS_PREFIX)/Makefile $(YOSYS_PREFIX)/frontends/ghdl/Makefile.inc $(YOSYS_PREFIX)/frontends/ghdl/ghdl.cc $(GHDL) Makefile.conf
	( cd $(YOSYS_PREFIX) && \
	 $(MAKE) config-gcc && \
	 echo 'ENABLE_CCACHE := 1' >> Makefile.conf && \
	 echo 'ENABLE_GHDL := 1' >> Makefile.conf && \
	 echo 'PREFIX := $(INSTALL_PREFIX)' >> Makefile.conf && \
	 echo 'GHDL_PREFIX := $(INSTALL_PREFIX)' >> Makefile.conf && \
	 echo 'CXXFLAGS ?= -I"$(shell $(GHDL) --libghdl-include-dir)"' >> Makefile.conf )

force-yosys $(YOSYS): $(YOSYS_PREFIX)/Makefile.conf
	( cd $(YOSYS_PREFIX) && $(MAKE) && $(MAKE) install)

# --- prjtrellis ---

prjtrellis-submodule: $(LIBTRELLIS_PREFIX)/CMakeLists.txt
$(LIBTRELLIS_PREFIX)/CMakeLists.txt:
	( cd $(SELFDIR) && git submodule update --init --recursive $(PRJTRELLIS_PREFIX) )

force-deinit-prjtrellis-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(PRJTRELLIS_PREFIX) )

$(LIBTRELLIS_PREFIX)/Makefile: $(LIBTRELLIS_PREFIX)/CMakeLists.txt Makefile.conf
	( cd $(LIBTRELLIS_PREFIX) && cmake -DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX) . )

force-prjtrellis $(PYTRELLIS) $(ECPPACK): $(LIBTRELLIS_PREFIX)/Makefile
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

force-deinit-prjxray-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(PRJXRAY_PREFIX) )

$(PRJXRAY_PREFIX)/build: $(PRJXRAY_PREFIX)/Makefile
	mkdir -p $@

$(PRJXRAY_PREFIX)/build/Makefile: Makefile.conf | $(PRJXRAY_PREFIX)/build
	( cd $(PRJXRAY_PREFIX)/build && cmake -DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX) .. )

force-prjxray $(XC7FRAMES2BIT) $(FASM2FRAMES): $(PRJXRAY_PREFIX)/build/Makefile
	( cd $(PRJXRAY_PREFIX) && ENV_DIR=$(INSTALL_PREFIX) $(MAKE) env && $(MAKE) install )

$(XRAY_SHARE_DIR)/prjxray_settings.sh: $(SELFDIR)/prjxray_settings.sh | $(XRAY_SHARE_DIR)
	cp -f $< $@

$(XRAY_SHARE_DIR)/environment.sh: $(PRJXRAY_PREFIX)/utils/environment.sh | $(XRAY_SHARE_DIR)
	cp -f $< $@

$(XRAY_SHARE_DIR)/environment.python.sh: $(PRJXRAY_PREFIX)/utils/environment.python.sh | $(XRAY_SHARE_DIR)
	cp -f $< $@

$(XRAY_SHARE_DIR)/vivado.sh: $(PRJXRAY_PREFIX)/utils/vivado.sh | $(XRAY_SHARE_DIR)
	cp -f $< $@

$(XRAYENV): $(XRAY_SHARE_DIR)/prjxray_settings.sh $(XRAY_SHARE_DIR)/environment.sh $(XRAY_SHARE_DIR)/environment.python.sh $(XRAY_SHARE_DIR)/vivado.sh Makefile.conf
	@echo "export XRAY_VIVADO_SETTINGS=$(XRAY_SHARE_DIR)/prjxray_settings.sh;source $(XRAY_SHARE_DIR)/environment.sh" > $@ && \
	chmod +x $@

# To depend on this correctly, you must depend on $(XRAYDBDIR)/<FAMILY>/<PART>
# example: $(XRAYDBDIR)/artix7/xc7a100tcsg324-1
.PRECIOUS: $(XRAY_SHARE_DIR)/%
.PRECIOUS: $(XRAYDBDIR)/%
$(XRAY_SHARE_DIR):
	mkdir -p $@
$(XRAYDBDIR): | $(XRAY_SHARE_DIR)
	( cd $(XRAY_SHARE_DIR) && git clone https://github.com/SymbiFlow/prjxray-db database )
$(XRAYDBDIR)/%: | $(XRAYDBDIR)

# --- nextpnr ---

nextpnr-submodule: $(NEXTPNR_PREFIX)/CMakeLists.txt
$(NEXTPNR_PREFIX)/CMakeLists.txt:
	( cd $(SELFDIR) && git submodule update --init $(NEXTPNR_PREFIX) ) && \
	( cd $(NEXTPNR_PREFIX) && git submodule update --init )

force-deinit-nextpnr-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(NEXTPNR_PREFIX) )

$(NEXTPNR_PREFIX)/Makefile: $(NEXTPNR_PREFIX)/CMakeLists.txt $(PYTRELLIS) Makefile.conf
	( cd $(NEXTPNR_PREFIX) && cmake -DARCH=ecp5 -DTRELLIS_INSTALL_PREFIX=$(INSTALL_PREFIX) -DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX) . )

force-nextpnr-ecp5 $(NEXTPNR_ECP5): $(NEXTPNR_PREFIX)/Makefile
	( cd $(NEXTPNR_PREFIX) && $(MAKE) && $(MAKE) install )

# --- nextpnr-xilinx ---

nextpnr-xilinx-submodule: $(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt
$(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt:
	( cd $(SELFDIR) && git submodule update --init $(NEXTPNR_XILINX_PREFIX) ) && \
	( cd $(NEXTPNR_XILINX_PREFIX) && git submodule update --init )

force-deinit-nextpnr-xilinx-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(NEXTPNR_XILINX_PREFIX) )

$(NEXTPNR_XILINX_PREFIX)/Makefile: $(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt Makefile.conf
	( cd $(NEXTPNR_XILINX_PREFIX) && cmake -DARCH=xilinx -DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX) . )

force-nextpnr-xilinx $(NEXTPNR_XILINX): $(NEXTPNR_XILINX_PREFIX)/Makefile
	( cd $(NEXTPNR_XILINX_PREFIX) && $(MAKE) && $(MAKE) install )

.PRECIOUS: $(NEXTPNR_XILINX_META)/%
$(NEXTPNR_XILINX_META): | $(NEXTPNR_XILINX_SHARE)
	( cd $(NEXTPNR_XILINX_SHARE) && git clone https://github.com/gatecat/nextpnr-xilinx-meta meta )
$(NEXTPNR_XILINX_META)/%: | $(NEXTPNR_XILINX_META)

$(NEXTPNR_XILINX_SHARE) $(NEXTPNR_XILINX_PYTHON):
	mkdir -p $@

BBAEXPORT_DEPENDS=\
$(NEXTPNR_XILINX_PYTHON)/bba.py \
$(NEXTPNR_XILINX_PYTHON)/bels.py \
$(NEXTPNR_XILINX_PYTHON)/constid.py \
$(NEXTPNR_XILINX_PYTHON)/nextpnr_structs.py \
$(NEXTPNR_XILINX_PYTHON)/parse_sdf.py \
$(NEXTPNR_XILINX_PYTHON)/tileconn.py \
$(NEXTPNR_XILINX_PYTHON)/xilinx_device.py \
$(NEXTPNR_XILINX_SHARE)/constids.inc

$(BBAEXPORT): $(NEXTPNR_XILINX_PREFIX)/xilinx/python/bbaexport.py $(BBAEXPORT_DEPENDS) | $(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt
	cp -f $< $@

$(NEXTPNR_XILINX_SHARE)/%: $(NEXTPNR_XILINX_PREFIX)/xilinx/% | $(NEXTPNR_XILINX_SHARE) $(NEXTPNR_XILINX_PYTHON) $(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt
	cp -f $< $@

$(NEXTPNR_XILINX_PREFIX)/bbasm: $(NEXTPNR_XILINX)

$(BBASM): $(NEXTPNR_XILINX_PREFIX)/bbasm
	cp -f $< $@

bbaexport: $(BBAEXPORT) $(NEXTPNR_XILINX_META)
bbasm: $(BBASM)

# --- ghdl ---

ghdl-submodule: $(GHDL_PREFIX)/configure
$(GHDL_PREFIX)/configure:
	( cd $(SELFDIR) && git submodule update --init $(GHDL_PREFIX) )

force-deinit-ghdl-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(GHDL_PREFIX) )

$(GHDL_PREFIX)/Makefile: $(GHDL_PREFIX)/configure Makefile.conf
	( cd $(GHDL_PREFIX) && ./configure --prefix="$(INSTALL_PREFIX)" )

force-ghdl $(GHDL): $(GHDL_PREFIX)/Makefile
	( cd $(GHDL_PREFIX) && $(MAKE) OPT_FLAGS=-fPIC && $(MAKE) install )

# --- ghdl-yosys-plugin ---

ghdl-yosys-submodule: $(GHDL_YOSYS_PLUGIN_PREFIX)/src
$(GHDL_YOSYS_PLUGIN_PREFIX)/src/%: | $(GHDL_YOSYS_PLUGIN_PREFIX)/src
$(GHDL_YOSYS_PLUGIN_PREFIX)/src:
	( cd $(SELFDIR) && git submodule update --init $(GHDL_YOSYS_PLUGIN_PREFIX) )

force-deinit-ghdl-yosys-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(GHDL_YOSYS_PLUGIN_PREFIX) )

# --- mega65-tools ---

mega65-tools-submodule: $(MEGA65_TOOLS_PREFIX)/Makefile
$(MEGA65_TOOLS_PREFIX)/Makefile:
	( cd $(SELFDIR) && git submodule update --init $(MEGA65_TOOLS_PREFIX) )

force-deinit-mega65-tools-submodule:
	( cd $(SELFDIR) && git submodule deinit --force $(MEGA65_TOOLS_PREFIX) )

force-bit2core $(BIT2CORE): $(MEGA65_TOOLS_PREFIX)/Makefile Makefile.conf
	( cd $(MEGA65_TOOLS_PREFIX) && $(MAKE) bin/bit2core )

# --- lakfpga ---

$(LAKFPGA_PREFIX):
	mkdir -p $@

$(LAKFPGA_PREFIX)/%: $(SELFDIR)/% | $(LAKFPGA_PREFIX)
	cp -f $< $@

$(LAKFPGA_PREFIX)/Makefile.conf: Makefile.conf | $(LAKFPGA_PREFIX)
	echo 'INSTALL_PREFIX=$(INSTALL_PREFIX)' >> $@ && \
	echo 'VIVADO_PREFIX=$(VIVADO_PREFIX)' >> $@

install-lakfpga: $(LAKFPGA_PREFIX)/Makefile.conf $(LAKFPGA_PREFIX)/toolchain.mk

# --- clean ---

clean-ghdl:
	( cd $(GHDL_PREFIX) && ( $(MAKE) clean ; git clean -xdf ) || echo 'ghdl clean failed' )

clean-ghdl-yosys:
	( cd $(GHDL_YOSYS_PLUGIN_PREFIX) && $(MAKE) clean || echo 'ghdl-yosys clean failed' )

clean-nextpnr:
	( cd $(NEXTPNR_PREFIX) && $(MAKE) clean || echo 'nextpnr clean failed' )

clean-prjtrellis:
	( cd $(LIBTRELLIS_PREFIX) && $(MAKE) clean || echo 'prjtrellis clean failed' )

clean-nextpnr-xilinx:
	( cd $(NEXTPNR_XILINX_PREFIX) && $(MAKE) clean || echo 'nextpnr-xilinx clean failed' )

clean-prjxray:
	( cd $(PRJXRAY_PREFIX) && ( $(MAKE) clean ; ( cd $(XRAYDBDIR) && $(MAKE) reset ) ) || echo 'prjxray clean failed' )
	rm -rf prjxray_env.sh

clean-yosys:
	( cd $(YOSYS_PREFIX) && ( $(MAKE) clean ; rm Makefile.conf ) || echo 'yosys clean failed' )

clean-mega65-tools:
	( cd $(MEGA65_TOOLS_PREFIX) && $(MAKE) clean || echo 'mega65-tools clean failed' )

clean: clean-ghdl clean-ghdl-yosys clean-yosys clean-nextpnr clean-prjtrellis clean-nextpnr-xilinx clean-prjxray clean-mega65-tools

force-deinit-submodules:
	$(MAKE) -j1 force-deinit-amaranth-submodule \
	force-deinit-amaranth-boards-submodule \
	force-deinit-yosys-submodule \
	force-deinit-prjtrellis-submodule \
	force-deinit-prjxray-submodule \
	force-deinit-nextpnr-submodule \
	force-deinit-nextpnr-xilinx-submodule \
	force-deinit-ghdl-submodule \
	force-deinit-ghdl-yosys-submodule \
	force-deinit-mega65-tools-submodule

hard-reset: force-deinit-submodules
ifeq ($(INSTALL_PREFIX),$(SELFDIR)/build)
	rm -rf $(SELFDIR)/build
endif
