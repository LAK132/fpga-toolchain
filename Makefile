ifeq ($(dir $(lastword $(MAKEFILE_LIST))),./)
SELFDIR := $(abspath $(PWD))
else
SELFDIR := $(abspath $(PWD)/$(dir $(lastword $(MAKEFILE_LIST))))
endif

YOSYS_PREFIX=$(SELFDIR)/yosys
YOSYS=$(YOSYS_PREFIX)/yosys

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
GHDL_YOSYS_PLUGIN=$(GHDL_YOSYS_PLUGIN_PREFIX)/ghdl.so

GHDL_YOSYS=$(YOSYS) -m $(GHDL_YOSYS_PLUGIN)
GHDL_YOSYS_DEPEND=$(YOSYS) $(GHDL_YOSYS_PLUGIN)

PRJXRAY_PREFIX=$(SELFDIR)/prjxray
XRAYENV=$(SELFDIR)/prjxray_env.sh
FASM2FRAMES=$(PRJXRAY_PREFIX)/utils/fasm2frames.py
XC7FRAMES2BIT=$(PRJXRAY_PREFIX)/build/tools/xc7frames2bit
XRAYDBDIR=$(PRJXRAY_PREFIX)/database

VIVADO_PREFIX=/opt/Xilinx

all: $(GHDL_YOSYS_DEPEND) $(NEXTPNR_XILINX) $(XRAYDBDIR) $(XC7FRAMES2BIT)
submodules: yosys-submodule prjxray-submodule nextpnr-xilinx-submodule ghdl-submodule ghdl-yosys-submodule
.PHONY: all

install_dependencies:
	apt install build-essential clang bison flex libreadline-dev gawk tcl-dev \
	libffi-dev git graphviz xdot pkg-config gcc g++ gnat cmake virtualenv \
	python3 python3-pip python3-yaml python3-venv python3-virtualenv \
	libboost-system-dev libboost-python-dev libboost-filesystem-dev \
	libboost-thread-dev libboost-program-options-dev libboost-iostreams-dev \
	zlib1g-dev qtbase5-dev libqt5gui5 libeigen3-dev ccache

# if you get `nextpnr-xilinx: error while loading shared libraries: libQt5Core.so.5: cannot open shared object file: No such file or directory`
# try running `sudo strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5`
# https://askubuntu.com/questions/1034313/ubuntu-18-4-libqt5core-so-5-cannot-open-shared-object-file-no-such-file-or-dir

# --- yosys ---

yosys-submodule: $(YOSYS_PREFIX)/Makefile
$(YOSYS_PREFIX)/Makefile:
	( cd $(SELFDIR) && git submodule update --init $(YOSYS_PREFIX) )

$(YOSYS_PREFIX)/Makefile.conf: $(YOSYS_PREFIX)/Makefile
	( cd $(YOSYS_PREFIX) && $(MAKE) config-gcc && echo 'ENABLE_CCACHE := 1' >> Makefile.conf )

force-yosys $(YOSYS): $(YOSYS_PREFIX)/Makefile.conf
	( cd $(YOSYS_PREFIX) && $(MAKE) )

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

ghdl-yosys-submodule: $(GHDL_YOSYS_PLUGIN_PREFIX)/Makefile
$(GHDL_YOSYS_PLUGIN_PREFIX)/Makefile:
	( cd $(SELFDIR) && git submodule update --init $(GHDL_YOSYS_PLUGIN_PREFIX) )

force-ghdl-yosys $(GHDL_YOSYS_PLUGIN): $(GHDL) $(YOSYS) $(GHDL_YOSYS_PLUGIN_PREFIX)/Makefile
	( cd $(GHDL_YOSYS_PLUGIN_PREFIX) && $(MAKE) GHDL="$(GHDL)" YOSYS_CONFIG="$(YOSYS_PREFIX)/yosys-config" CFLAGS="-I$(YOSYS_PREFIX) -O" )

# --- clean ---

clean-ghdl:
	( cd $(GHDL_PREFIX) && ( $(MAKE) clean ; git clean -xdf ) || echo 'ghdl clean failed' )

clean-ghdl-yosys:
	( cd $(GHDL_YOSYS_PLUGIN_PREFIX) && $(MAKE) clean || echo 'ghdl-yosys clean failed' )

clean-nextpnr-xilinx:
	( cd $(NEXTPNR_XILINX_PREFIX) && $(MAKE) clean || echo 'nextpnr-xilinx clean failed' )

clean-prjxray:
	( cd $(PRJXRAY_PREFIX) && ( $(MAKE) clean ; ( cd database && $(MAKE) reset ) ) || echo 'prjxray clean failed' )

clean-yosys:
	( cd $(YOSYS_PREFIX) && ( $(MAKE) clean ; rm Makefile.conf ) || echo 'yosys clean failed' )

clean: clean-ghdl clean-ghdl-yosys clean-yosys clean-nextpnr clean-prjxray
	rm -rf prjxray_env.sh
