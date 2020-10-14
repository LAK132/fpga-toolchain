YOSYS_PREFIX=yosys
YOSYS=$(YOSYS_PREFIX)/yosys

NEXTPNR_PREFIX=nextpnr-xilinx
NEXTPNR=$(NEXTPNR_PREFIX)/nextpnr-xilinx
BBAEXPORT=python3 $(NEXTPNR_PREFIX)/xilinx/python/bbaexport.py
BBASM=$(NEXTPNR_PREFIX)/bbasm

GHDL_PREFIX=ghdl
GHDL_MCODE=$(GHDL_PREFIX)/ghdl_mcode
GHDL=$(GHDL_PREFIX)/ghdl/bin/ghdl

GHDL_YOSYS_PLUGIN_PREFIX=ghdl-yosys-plugin
GHDL_YOSYS_PLUGIN=$(GHDL_YOSYS_PLUGIN_PREFIX)/ghdl.so

GHDL_YOSYS=$(YOSYS) -m $(GHDL_YOSYS_PLUGIN)

PRJXRAY_PREFIX=prjxray
XRAYENV=$(PRJXRAY_PREFIX)/utils/environment.sh
FASM2FRAMES=python3 $(PRJXRAY_PREFIX)/utils/fasm2frames.py
XC7FRAMES2BIT=$(PRJXRAY_PREFIX)/build/tools/xc7frames2bit
XRAYDBDIR=$(PRJXRAY_PREFIX)/database

VIVADO_PREFIX=/opt/Xilinx

.PHONY: all
all: $(GHDL_YOSYS_PLUGIN) $(XRAYDBDIR) $(PRJXRAY_PREFIX)/build

init:
	git submodule update --init \
	&& ( cd $(PRJXRAY_PREFIX) && git submodule update --init --recursive ) \
	&& ( cd $(NEXTPNR_PREFIX) && git submodule update --init )

install_dependencies:
	apt install build-essential clang bison flex libreadline-dev gawk tcl-dev libffi-dev git graphviz xdot pkg-config gcc g++ gnat cmake virtualenv python3 python3-pip python3-yaml python3-venv python3-virtualenv libboost-system-dev libboost-python-dev libboost-filesystem-dev zlib1g-dev

$(YOSYS):
	( cd $(YOSYS_PREFIX) && make config-gcc && make )

$(PRJXRAY_PREFIX)/build:
	( cd $(PRJXRAY_PREFIX) && make build && make env )

$(XC7FRAMES2BIT): $(PRJXRAY_PREFIX)/build
$(BBASM): $(PRJXRAY_PREFIX)/build

$(XRAYDBDIR):
	( cd $(PRJXRAY_PREFIX) && ./download-latest-db.sh )

$(NEXTPNR):
	( cd $(NEXTPNR_PREFIX) && cmake -DARCH=xilinx . && make )

$(GHDL_MCODE):
	( cd $(GHDL_PREFIX) && ./configure --prefix="$(GHDL_PREFIX)" && make OPT_FLAGS=-fPIC )

$(GHDL): $(GHDL_MCODE)
	( cd $(GHDL_PREFIX) && make install )

$(GHDL_YOSYS_PLUGIN): $(GHDL) $(YOSYS)
	( cd $(GHDL_YOSYS_PLUGIN_PREFIX) && make GHDL="$(PWD)/$(GHDL)" YOSYS_CONFIG="$(PWD)/$(YOSYS_PREFIX)/yosys-config" CFLAGS="-I$(PWD)/$(YOSYS_PREFIX) -O" )
