include toolchain.mk

# --- Submodule locations ---

AMARANTH_PREFIX=$(SELFDIR)/amaranth
AMARANTH_BOARDS_PREFIX=$(SELFDIR)/amaranth-boards
FASM2BIT_PREFIX=$(SELFDIR)/fasm2bit
GHDL_PREFIX=$(SELFDIR)/ghdl
GHDL_YOSYS_PLUGIN_PREFIX=$(SELFDIR)/ghdl-yosys-plugin
ICESTORM_PREFIX=$(SELFDIR)/icestorm
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

LIBTRELLIS_PREFIX=$(PRJTRELLIS_PREFIX)/libtrellis
TRELLISDBDIR=$(SHAREDIR)/trellis/database
PYTRELLIS=$(LIBDIR)/trellis/pytrellis.so

LAKFPGA_PREFIX=$(SHAREDIR)/lakfpga

ALL_TOOLS=\
$(GHDL) \
$(ECPPACK) \
$(ICEPACK) \
$(BBAEXPORT) \
$(BBASM) \
$(XC7FRAMES2BIT) \
$(FASM2FRAMES) \
$(BIT2CORE) \
$(NEXTPNR_ECP5) \
$(NEXTPNR_ICE40) \
$(NEXTPNR_XILINX) \
$(YOSYS)

ALL_DEPENDS=\
$(ALL_TOOLS) \
$(NEXTPNR_XILINX_META) \
$(XRAYDBDIR) \
$(XRAYENV)

all:
	$(foreach T,submodules $(ALL_DEPENDS) install-lakfpga force-amaranth force-amaranth-boards, ( $(MAKE) $T ) &&) echo ""

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
	zlib1g-dev qtbase5-dev libqt5gui5 libeigen3-dev ccache dfu-util libftdi-dev

test:
	( cd example && $(MAKE) -j1 clean && $(MAKE) -j1 all )

# --- amaranth ---

$(AMARANTH_PREFIX)/setup.py:
	$(MAKE) amaranth-submodule

force-amaranth: $(AMARANTH_PREFIX)/setup.py
	( cd $(AMARANTH_PREFIX) && python3 -m pip install --editable . )

# --- amaranth-boards ---

$(AMARANTH_BOARDS_PREFIX)/setup.py:
	$(MAKE) amaranth-boards-submodule

force-amaranth-boards: $(AMARANTH_BOARDS_PREFIX)/setup.py
	( cd $(AMARANTH_BOARDS_PREFIX) && python3 -m pip install --editable . )

# --- yosys ---

$(YOSYS_PREFIX)/Makefile:
	$(MAKE) yosys-submodule

$(YOSYS_PREFIX)/frontends/ghdl: | $(YOSYS_PREFIX)/Makefile $(YOSYS_PREFIX)/frontends
	mkdir -p $@

$(YOSYS_PREFIX)/frontends/ghdl/%: $(GHDL_YOSYS_PLUGIN_PREFIX)/src/% | $(YOSYS_PREFIX)/frontends/ghdl
	cp -f $< $@

$(YOSYS_PREFIX)/Makefile.conf: $(YOSYS_PREFIX)/Makefile $(YOSYS_PREFIX)/frontends/ghdl/Makefile.inc $(YOSYS_PREFIX)/frontends/ghdl/ghdl.cc $(GHDL) Makefile.conf
	( cd $(YOSYS_PREFIX) && \
	 $(MAKE) config-gcc && \
	 echo 'ENABLE_CCACHE := 1' > Makefile.conf && \
	 echo 'ENABLE_GHDL := 1' >> Makefile.conf && \
	 echo 'PREFIX := $(INSTALL_PREFIX)' >> Makefile.conf && \
	 echo 'GHDL_PREFIX := $(INSTALL_PREFIX)' >> Makefile.conf && \
	 echo 'CXXFLAGS ?= -I"$(shell $(GHDL) --libghdl-include-dir)"' >> Makefile.conf )

force-yosys $(YOSYS): $(YOSYS_PREFIX)/Makefile.conf
	( cd $(YOSYS_PREFIX) && $(MAKE) && $(MAKE) install)

# --- prjtrellis ---

PRJTRELLIS_SUBMODULE_INIT_ARGS:=--recursive

$(LIBTRELLIS_PREFIX)/CMakeLists.txt:
	$(MAKE) prjtrellis-submodule

$(LIBTRELLIS_PREFIX)/Makefile: $(LIBTRELLIS_PREFIX)/CMakeLists.txt Makefile.conf
	( cd $(LIBTRELLIS_PREFIX) && cmake -DCMAKE_INSTALL_PREFIX="$(INSTALL_PREFIX)" . )

force-prjtrellis $(PYTRELLIS): $(LIBTRELLIS_PREFIX)/Makefile
	( cd $(LIBTRELLIS_PREFIX) && $(MAKE) -j1 && $(MAKE) -j1 install )

$(ECPPACK): $(PYTRELLIS)

# To depend on this correctly, you must depend on
# $(TRELLISDBDIR)/<FAMILY>/<PART>
# example: $(TRELLISDBDIR)/ECP5/LFE5U-25F
.PRECIOUS: $(TRELLISDBDIR)/%
$(TRELLISDBDIR): $(LIBTRELLIS_PREFIX)/Makefile
$(TRELLISDBDIR)/%: $(LIBTRELLIS_PREFIX)/Makefile
	( cd $(PRJTRELLIS_PREFIX) && git submodule update --init $(TRELLISDBDIR) )

# --- icestorm ---

ICESTORM_SUBMODULE_INIT_ARGS:=--recursive

$(ICESTORM_PREFIX)/Makefile:
	$(MAKE) icestorm-submodule

force-icestorm $(ICEPACK): $(ICESTORM_PREFIX)/Makefile
	( cd $(ICESTORM_PREFIX) && PREFIX="$(INSTALL_PREFIX)" $(MAKE) && PREFIX="$(INSTALL_PREFIX)" $(MAKE) -j1 install )

# --- prjxray ---

PRJXRAY_SUBMODULE_INIT_ARGS:=--recursive

$(PRJXRAY_PREFIX)/Makefile:
	$(MAKE) prjxray-submodule

$(PRJXRAY_PREFIX)/build: $(PRJXRAY_PREFIX)/Makefile
	mkdir -p $@

$(PRJXRAY_PREFIX)/build/Makefile: $(PRJXRAY_PREFIX)/CMakeLists.txt Makefile.conf | $(PRJXRAY_PREFIX)/build
	( cd $(PRJXRAY_PREFIX)/build && cmake -DCMAKE_INSTALL_PREFIX="$(INSTALL_PREFIX)" .. )

force-prjxray $(FASM2FRAMES): $(PRJXRAY_PREFIX)/build/Makefile
	( cd $(PRJXRAY_PREFIX) && ENV_DIR="$(INSTALL_PREFIX)" $(MAKE) -j1 env && $(MAKE) -j1 install )

$(XC7FRAMES2BIT): $(FASM2FRAMES)

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

NEXTPNR_SUBMODULE_INIT_ARGS:=--recursive
NEXTPNR_PYTHON?=OFF

$(NEXTPNR_PREFIX)/CMakeLists.txt:
	$(MAKE) nextpnr-submodule

$(NEXTPNR_PREFIX)/Makefile: $(NEXTPNR_PREFIX)/CMakeLists.txt $(PYTRELLIS) $(ICEPACK) Makefile.conf
	( cd $(NEXTPNR_PREFIX) && cmake -DBUILD_PYTHON=$(NEXTPNR_PYTHON) -DBUILD_GUI=OFF -DARCH="ecp5;ice40" -DICESTORM_INSTALL_PREFIX="$(INSTALL_PREFIX)" -DTRELLIS_INSTALL_PREFIX="$(INSTALL_PREFIX)" -DCMAKE_INSTALL_PREFIX="$(INSTALL_PREFIX)" . )

force-nextpnr $(NEXTPNR_ECP5): $(NEXTPNR_PREFIX)/Makefile
	( cd $(NEXTPNR_PREFIX) && $(MAKE) && $(MAKE) -j1 install )

$(NEXTPNR_ICE40): $(NEXTPNR_ECP5)

# --- nextpnr-xilinx ---

NEXTPNR_XILINX_SUBMODULE_INIT_ARGS:=--recursive

$(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt:
	$(MAKE) nextpnr-xilinx-submodule

$(NEXTPNR_XILINX_PREFIX)/Makefile: $(NEXTPNR_XILINX_PREFIX)/CMakeLists.txt Makefile.conf
	( cd $(NEXTPNR_XILINX_PREFIX) && cmake -DEXTERNAL_DB=ON -DBUILD_PYTHON=$(NEXTPNR_PYTHON) -DBUILD_GUI=OFF -DARCH=xilinx -DCMAKE_INSTALL_PREFIX="$(INSTALL_PREFIX)" . )

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

$(GHDL_PREFIX)/configure:
	$(MAKE) ghdl-submodule

$(GHDL_PREFIX)/Makefile: $(GHDL_PREFIX)/configure Makefile.conf
	( cd $(GHDL_PREFIX) && ./configure --prefix="$(INSTALL_PREFIX)" )

force-ghdl $(GHDL): $(GHDL_PREFIX)/Makefile
	( cd $(GHDL_PREFIX) && $(MAKE) OPT_FLAGS=-fPIC && $(MAKE) install )

# --- ghdl-yosys-plugin ---

$(GHDL_YOSYS_PLUGIN_PREFIX)/src/%: | $(GHDL_YOSYS_PLUGIN_PREFIX)/src
$(GHDL_YOSYS_PLUGIN_PREFIX)/src:
	$(MAKE) ghdl-yosys-submodule

# --- mega65-tools ---

$(MEGA65_TOOLS_PREFIX)/Makefile:
	$(MAKE) mega65-tools-submodule

$(MEGA65_TOOLS_PREFIX)/bin/bit2core: $(MEGA65_TOOLS_PREFIX)/Makefile Makefile.conf
	( cd $(MEGA65_TOOLS_PREFIX) && $(MAKE) bin/bit2core )

force-bit2core $(BIT2CORE): $(MEGA65_TOOLS_PREFIX)/bin/bit2core
	cp -f $< $(BIT2CORE)

# --- lakfpga ---

$(LAKFPGA_PREFIX):
	mkdir -p $@

$(LAKFPGA_PREFIX)/%: $(SELFDIR)/% | $(LAKFPGA_PREFIX)
	cp -f $< $@

$(LAKFPGA_PREFIX)/Makefile.conf: Makefile.conf | $(LAKFPGA_PREFIX)
	echo 'INSTALL_PREFIX:=$(INSTALL_PREFIX)' > $@ && \
	echo 'VIVADO_PREFIX:=$(VIVADO_PREFIX)' >> $@

install-lakfpga: $(LAKFPGA_PREFIX)/Makefile.conf $(LAKFPGA_PREFIX)/toolchain.mk

# --- pattern targets ---

STEM=$(shell echo '$*' | tr '[:lower:]' '[:upper:]' | tr '-' '_')

force-rebuild-%:
	$(MAKE) -j1 force-deinit-$*-submodule && \
	$(MAKE) -j1 $*-submodule && \
	$(MAKE) force-$*

%-submodule:
	$(warning init submodule for $* at $($(STEM)_PREFIX))
	( cd $(SELFDIR) && git submodule update --init $($(STEM)_SUBMODULE_INIT_ARGS) $($(STEM)_PREFIX) )

force-deinit-%-submodule:
	$(warning deinit submodule for $* at $($(STEM)_PREFIX))
	( cd $(SELFDIR) && git submodule deinit --force $($(STEM)_PREFIX) )

# --- clean ---

force-deinit-submodules:
	$(MAKE) -j1 force-deinit-amaranth-submodule \
	force-deinit-amaranth-boards-submodule \
	force-deinit-yosys-submodule \
	force-deinit-prjtrellis-submodule \
	force-deinit-prjxray-submodule \
	force-deinit-nextpnr-submodule \
	force-deinit-nextpnr-xilinx-submodule \
	force-deinit-ghdl-submodule \
	force-deinit-ghdl-yosys-plugin-submodule \
	force-deinit-mega65-tools-submodule

hard-reset: force-deinit-submodules
ifeq ($(INSTALL_PREFIX),$(SELFDIR)/build)
	rm -rf $(SELFDIR)/build
endif

force-rebuild-all: hard-reset
	$(MAKE) all
