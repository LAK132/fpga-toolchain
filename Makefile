SELFDIR := $(PWD)/$(dir $(lastword $(MAKEFILE_LIST)))

YOSYS_PREFIX=$(SELFDIR)yosys
YOSYS=$(YOSYS_PREFIX)/yosys

NEXTPNR_PREFIX=$(SELFDIR)nextpnr-xilinx
NEXTPNR=$(NEXTPNR_PREFIX)/nextpnr-xilinx
BBAEXPORT=$(NEXTPNR_PREFIX)/xilinx/python/bbaexport.py
BBASM=$(NEXTPNR_PREFIX)/bbasm

GHDL_PREFIX=$(SELFDIR)ghdl
GHDL_BUILD=$(GHDL_PREFIX)/build
GHDL_MCODE=$(GHDL_PREFIX)/ghdl_mcode
GHDL=$(GHDL_PREFIX)/build/bin/ghdl

GHDL_YOSYS_PLUGIN_PREFIX=$(SELFDIR)ghdl-yosys-plugin
GHDL_YOSYS_PLUGIN=$(GHDL_YOSYS_PLUGIN_PREFIX)/ghdl.so

GHDL_YOSYS=$(YOSYS) -m $(GHDL_YOSYS_PLUGIN)

PRJXRAY_PREFIX=$(SELFDIR)prjxray
XRAYENV=$(PRJXRAY_PREFIX)/utils/environment.sh
FASM2FRAMES=$(PRJXRAY_PREFIX)/utils/fasm2frames.py
XC7FRAMES2BIT=$(PRJXRAY_PREFIX)/build/tools/xc7frames2bit
XRAYDBDIR=$(PRJXRAY_PREFIX)/database

VIVADO_PREFIX=/opt/Xilinx

all: $(GHDL_YOSYS_PLUGIN) $(NEXTPNR) $(XRAYDBDIR) $(PRJXRAY_PREFIX)/build $(XRAYDBDIR)
.PHONY: all

init:
	git submodule update --init \
	&& ( cd $(PRJXRAY_PREFIX) && git submodule update --init --recursive ) \
	&& ( cd $(NEXTPNR_PREFIX) && git submodule update --init )

install_dependencies:
	apt install build-essential clang bison flex libreadline-dev gawk tcl-dev \
	libffi-dev git graphviz xdot pkg-config gcc g++ gnat cmake virtualenv \
	python3 python3-pip python3-yaml python3-venv python3-virtualenv \
	libboost-system-dev libboost-python-dev libboost-filesystem-dev \
	libboost-thread-dev libboost-program-options-dev libboost-iostreams-dev \
	zlib1g-dev qtbase5-dev libqt5gui5 libeigen3-dev

# if you get `nextpnr-xilinx: error while loading shared libraries: libQt5Core.so.5: cannot open shared object file: No such file or directory`
# try running `sudo strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5`
# https://askubuntu.com/questions/1034313/ubuntu-18-4-libqt5core-so-5-cannot-open-shared-object-file-no-such-file-or-dir

# --- yosys ---

$(YOSYS_PREFIX)/Makefile.conf:
	( cd $(YOSYS_PREFIX) && make config-gcc && echo 'ENABLE_CCACHE := 1' >> Makefile.conf )

$(YOSYS): $(YOSYS_PREFIX)/Makefile.conf
	( cd $(YOSYS_PREFIX) && make )

# --- prjxray ---

$(PRJXRAY_PREFIX)/build:
	( cd $(PRJXRAY_PREFIX) && make build && make env )

$(FASM2FRAMES): $(PRJXRAY_PREFIX)/build
$(XC7FRAMES2BIT): $(PRJXRAY_PREFIX)/build

$(XRAYDBDIR):
	( cd $(PRJXRAY_PREFIX) && ./download-latest-db.sh )

# --- nextpnr-xilinx ---

$(NEXTPNR_PREFIX)/Makefile:
	( cd $(NEXTPNR_PREFIX) && cmake -DARCH=xilinx . )

$(NEXTPNR): $(NEXTPNR_PREFIX)/Makefile
	( cd $(NEXTPNR_PREFIX) && make )

$(BBAEXPORT): $(NEXTPNR)
$(BBASM): $(NEXTPNR)

# --- ghdl ---

$(GHDL_PREFIX)/Makefile: $(GHDL_PREFIX)/configure
	( cd $(GHDL_PREFIX) && ./configure --prefix="$(GHDL_BUILD)" )

$(GHDL_MCODE): $(GHDL_PREFIX)/Makefile
	( cd $(GHDL_PREFIX) && make OPT_FLAGS=-fPIC )

$(GHDL): $(GHDL_MCODE)
	( cd $(GHDL_PREFIX) && make install )

# --- ghdl-yosys-plugin ---

$(GHDL_YOSYS_PLUGIN): $(GHDL) $(YOSYS)
	( cd $(GHDL_YOSYS_PLUGIN_PREFIX) && make GHDL="$(GHDL)" YOSYS_CONFIG="$(YOSYS_PREFIX)/yosys-config" CFLAGS="-I$(YOSYS_PREFIX) -O" )

# --- clean ---

clean-ghdl:
	( cd $(GHDL_PREFIX) && ( make clean ; git clean -xdf ) || echo 'ghdl clean failed' )

clean-ghdl-yosys:
	( cd $(GHDL_YOSYS_PLUGIN_PREFIX) && make clean || echo 'ghdl-yosys clean failed' )

clean-nextpnr:
	( cd $(NEXTPNR_PREFIX) && make clean || echo 'nextpnr clean failed' )

clean-prjxray:
	( cd $(PRJXRAY_PREFIX) && ( make clean ; ( cd database && make reset ) ) || echo 'prjxray clean failed' )

clean-yosys:
	( cd $(YOSYS_PREFIX) && ( make clean ; rm Makefile.conf ) || echo 'yosys clean failed' )

clean: clean-ghdl clean-ghdl-yosys clean-yosys clean-nextpnr clean-prjxray