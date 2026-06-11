include toolchain.mk

# --- Submodule locations ---

TORII_HDL_PREFIX=$(SELFDIR)/torii-hdl
TORII_BOARDS_PREFIX=$(SELFDIR)/torii-boards
FASM2BIT_PREFIX=$(SELFDIR)/fasm2bit
GHDL_PREFIX=$(SELFDIR)/ghdl
GHDL_YOSYS_PLUGIN_PREFIX=$(SELFDIR)/ghdl-yosys-plugin
ICESTORM_PREFIX=$(SELFDIR)/icestorm
MEGA65_TOOLS_PREFIX=$(SELFDIR)/mega65-tools
NEXTPNR_PREFIX=$(SELFDIR)/nextpnr
NEXTPNR_XILINX_PREFIX=$(SELFDIR)/nextpnr-xilinx
OPENFPGALOADER_PREFIX=$(SELFDIR)/openFPGALoader
PRJTRELLIS_PREFIX=$(SELFDIR)/prjtrellis
PRJXRAY_PREFIX=$(SELFDIR)/prjxray
YOSYS_PREFIX=$(SELFDIR)/yosys

# ---

PYTHON3?=python3.11

FASM2BIT_BUILD=$(FASM2BIT_PREFIX)/build
FASM2BIT=$(FASM2BIT_BUILD)/fasm2bit

MEGA65_TOOLS_PREFIX=$(SELFDIR)/mega65-tools

LIBTRELLIS_PREFIX=$(PRJTRELLIS_PREFIX)/libtrellis
TRELLISDBDIR=$(SHAREDIR)/trellis/database
PYTRELLIS=$(LIBDIR)/trellis/pytrellis$(DLL)

LAKFPGA_PREFIX=$(SHAREDIR)/lakfpga

CMAKE_INSTALL_CONFIG=\
-DCMAKE_INSTALL_PREFIX="$(INSTALL_PREFIX)" \
-DCMAKE_INSTALL_LIBDIR="$(LIBDIR)" \
-DCMAKE_INSTALL_BINDIR="$(BINDIR)" \
-DCMAKE_INSTALL_INCLUDEDIR="$(INCDIR)" \
-DCMAKE_INSTALL_DATAROOTDIR="$(SHAREDIR)"

.PHONY: all
all:
	( $(MAKE) python-venv ) && \
	( $(MAKE) torii-hdl ) && \
	( $(MAKE) torii-boards ) && \
	$(foreach D,$(ALL_ARCH_DEPS),( $(MAKE) $D ) && ) \
	( $(MAKE) openFPGALoader ) && \
	( $(MAKE) install-lakfpga )

.PHONY: all-fast
all-fast:
	$(MAKE) -j$(shell nproc) all

.PHONY: force-all-ECP5
force-all-ECP5:
	( $(MAKE) force-prjtrellis ) && \
	( $(MAKE) force-nextpnr-ECP5 )

.PHONY: force-all-ICE40
force-all-ICE40:
	( $(MAKE) force-icestorm ) && \
	( $(MAKE) force-nextpnr-ICE40 )

.PHONY: force-all-XC7
force-all-XC7:
	( $(MAKE) force-prjxray ) && \
	( $(MAKE) force-prjxray-env ) && \
	( $(MAKE) force-nextpnr-XC7 )

.PHONY: force-all
force-all:
	( $(MAKE) submodules ) && \
	( $(MAKE) force-venv ) && \
	( $(MAKE) force-torii-hdl ) && \
	( $(MAKE) force-torii-boards ) && \
	( $(MAKE) force-ghdl ) && \
	( $(MAKE) force-yosys ) && \
	$(foreach A,$(ARCHITECTURES),( $(MAKE) force-all-$(strip $A) ) && )\
	( $(MAKE) force-coretool ) && \
	( $(MAKE) force-openFPGALoader ) && \
	( $(MAKE) install-lakfpga )

.PHONY: force-all-fast
force-all-fast:
	$(MAKE) -j$(shell nproc) force-all

.PHONY: submodules
submodules:
	$(MAKE) -j1 \
	torii-hdl-submodule \
	torii-boards-submodule \
	yosys-submodule \
	prjtrellis-submodule \
	prjxray-submodule \
	nextpnr-submodule \
	ghdl-submodule \
	ghdl-yosys-submodule \
	openFPGALoader-submodule \
	mega65-tools-submodule

ifeq ($(HOST_SYSTEM),Linux)
ifneq ($(shell cat /etc/lsb-release | grep Ubuntu),)
IS_UBUNTU:=TRUE
endif
endif

.PHONY: install_dependencies
install_dependencies:
ifneq ($(IS_UBUNTU),)
	apt install build-essential clang bison flex libreadline-dev gawk tcl-dev \
	libffi-dev git graphviz xdot pkg-config gcc g++ gnat cmake \
	python3.11 python3.11-pip python3.11-venv \
	libboost-system-dev libboost-python-dev libboost-filesystem-dev \
	libboost-thread-dev libboost-program-options-dev libboost-iostreams-dev \
	zlib1g-dev qtbase5-dev libqt5gui5 libeigen3-dev ccache dfu-util libftdi-dev \
	libftdi1-dev libudev-dev grep
endif
ifeq ($(HOST_SYSTEM),WSL)
	$(warning If you are intending to build the board flashing tools, you will want to run this command under MSYS as well, or run install_msys_dependencies)
endif
ifeq ($(HOST_SYSTEM),MSYS)
	pacman -S --needed grep mingw-w64-ucrt-x86_64-cmake \
	mingw-w64-ucrt-x86_64-make mingw-w64-ucrt-x86_64-gcc \
	mingw-w64-ucrt-x86_64-libusb mingw-w64-ucrt-x86_64-libftdi \
	mingw-w64-ucrt-x86_64-libpng mingw-w64-ucrt-x86_64-zlib
endif

.PHONY: install_msys_dependencies
install_msys_dependencies:
	$(call MAKE_IN_MSYS,install_dependencies)

ifeq ($(HOST_SYSTEM),MSYS)
CC:=/ucrt64/bin/x86_64-w64-mingw32-gcc.exe
CXX:=/ucrt64/bin/x86_64-w64-mingw32-g++.exe
CMAKE?=/ucrt64/bin/cmake.exe
endif
CC?=gcc
CXX?=g++
CMAKE?=cmake

ifeq ($(MSYS_PREFIX),)
define MAKE_IN_MSYS=
$(error Unable to build tools requiring USB under WSL. Unable to find MSYS bash. Add `MSYS_PREFIX=/path/to/msys64` to your Makefile.conf)
endef
else
define MAKE_IN_MSYS=
( $(MSYS_PREFIX)/usr/bin/bash.exe -c "export MSYSTEM=UCRT64 && $(patsubst /mnt/%,/%,$(MSYS_PREFIX)/usr/bin/bash.exe) --login -c \"cd $(patsubst /mnt/%,/%,$(SELFDIR)) && /ucrt64/bin/mingw32-make.exe $(patsubst /mnt/%,/%,$1)\"" )
# the version above uses Windows paths, below uses unix paths
# ( $(MSYS_PREFIX)/usr/bin/bash.exe -c "export MSYSTEM=UCRT64 && $(patsubst /mnt/%,/%,$(MSYS_PREFIX)/usr/bin/bash.exe) --login -c \"cd $(patsubst /mnt/%,/%,$(SELFDIR)) && /usr/bin/make $(patsubst /mnt/%,/%,$1)\"" )
endef
endif

.PHONY: test
test:
	( cd example && $(MAKE) -j1 clean && $(MAKE) -j1 all )

# --- python venv ---

.PHONY: force-venv
force-venv $(ACTIVATE_VENV) $(VENV_PYTHON3):
	( cd $(SELFDIR) && $(PYTHON3) -m venv --copies $(INSTALL_PREFIX) )

.PHONY: python-venv
python-venv: $(ACTIVATE_VENV)

$(INSTALL_PREFIX): | $(VENV_PYTHON3)

$(BINDIR) $(LIBDIR) $(INCDIR) $(SHAREDIR): | $(VENV_PYTHON3)
	mkdir -p $@

# --- torii-hdl ---

$(TORII_HDL_PREFIX)/.git:
	$(MAKE) torii-hdl-submodule

.PHONY: force-torii-hdl
force-torii-hdl $(LIBDIR)/$(PYTHON3)/site-packages/torii: | $(TORII_HDL_PREFIX)/.git $(VENV_PYTHON3)
	( cd $(TORII_HDL_PREFIX) && . $(ACTIVATE_VENV) && $(VENV_PYTHON3) -m pip install . )

.PHONY: torii-hdl
torii-hdl: $(LIBDIR)/$(PYTHON3)/site-packages/torii

# --- torii-boards ---

$(TORII_BOARDS_PREFIX)/.git:
	$(MAKE) torii-boards-submodule

.PHONY: force-torii-boards
force-torii-boards $(LIBDIR)/$(PYTHON3)/site-packages/torii_boards: | $(TORII_BOARDS_PREFIX)/.git $(VENV_PYTHON3)
	( cd $(TORII_BOARDS_PREFIX) && . $(ACTIVATE_VENV) && $(VENV_PYTHON3) -m pip install . )

.PHONY: torii-boards
torii-boards: $(LIBDIR)/$(PYTHON3)/site-packages/torii_boards

# --- yosys ---

YOSYS_SUBMODULE_INIT_ARGS:=--recursive

$(YOSYS_PREFIX)/.git: |  $(GHDL_YOSYS_PLUGIN_PREFIX)/.git
	$(MAKE) yosys-submodule

$(YOSYS_PREFIX)/Makefile: | $(YOSYS_PREFIX)/.git

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

.PHONY: force-yosys
force-yosys $(YOSYS): $(YOSYS_PREFIX)/Makefile.conf
	( cd $(YOSYS_PREFIX) && $(MAKE) && $(MAKE) install)

.PHONY: yosys
yosys: $(YOSYS)

# --- prjtrellis ---

PRJTRELLIS_SUBMODULE_INIT_ARGS:=--recursive

$(LIBTRELLIS_PREFIX)/.git:
	$(MAKE) prjtrellis-submodule

$(LIBTRELLIS_PREFIX)/CMakeLists.txt: | $(LIBTRELLIS_PREFIX)/.git

$(LIBTRELLIS_PREFIX)/generated/Makefile: $(LIBTRELLIS_PREFIX)/CMakeLists.txt Makefile.conf | $(ACTIVATE_VENV)
	( cd $(LIBTRELLIS_PREFIX) && . $(ACTIVATE_VENV) && $(CMAKE) . -B generated $(CMAKE_INSTALL_CONFIG) && $(CMAKE) --build generated )

.PHONY: force-prjtrellis
force-prjtrellis $(ECPPACK) $(PYTRELLIS): $(LIBTRELLIS_PREFIX)/generated/Makefile | $(ACTIVATE_VENV)
	( cd $(LIBTRELLIS_PREFIX)/generated && . $(ACTIVATE_VENV) && $(MAKE) -j1 && $(MAKE) -j1 install )

.PHONY: prjtrellis
prjtrellis: $(PYTRELLIS)

# To depend on this correctly, you must depend on
# $(TRELLISDBDIR)/<FAMILY>/<PART>
# example: $(TRELLISDBDIR)/ECP5/LFE5U-25F
.PRECIOUS: $(TRELLISDBDIR)/%
$(TRELLISDBDIR): $(LIBTRELLIS_PREFIX)/Makefile
$(TRELLISDBDIR)/%: $(LIBTRELLIS_PREFIX)/Makefile
	( cd $(PRJTRELLIS_PREFIX) && git submodule update --init $(TRELLISDBDIR) )

# --- icestorm ---

ICESTORM_SUBMODULE_INIT_ARGS:=--recursive

$(ICESTORM_PREFIX)/.git:
	$(MAKE) icestorm-submodule

$(ICESTORM_PREFIX)/Makefile: | $(ICESTORM_PREFIX)/.git

.PHONY: force-icestorm
force-icestorm $(ICEPACK): $(ICESTORM_PREFIX)/Makefile
	( cd $(ICESTORM_PREFIX) && PREFIX="$(INSTALL_PREFIX)" $(MAKE) && PREFIX="$(INSTALL_PREFIX)" $(MAKE) -j1 install )

.PHONY: icestorm
icestorm: $(ICEPACK)

# --- prjxray ---

PRJXRAY_SUBMODULE_INIT_ARGS:=--recursive

$(PRJXRAY_PREFIX)/.git:
	$(MAKE) prjxray-submodule

$(PRJXRAY_PREFIX)/CMakeLists.txt $(PRJXRAY_PREFIX)/Makefile: | $(PRJXRAY_PREFIX)/.git

$(PRJXRAY_PREFIX)/build/Makefile: $(PRJXRAY_PREFIX)/CMakeLists.txt Makefile.conf | $(ACTIVATE_VENV)
	( cd $(PRJXRAY_PREFIX) && . $(ACTIVATE_VENV) && $(CMAKE) . -B build -DCMAKE_POLICY_VERSION_MINIMUM=3.5 $(CMAKE_INSTALL_CONFIG) )

.PHONY: force-prjxray
force-prjxray $(XC7FRAMES2BIT) $(FASM2FRAMES): $(PRJXRAY_PREFIX)/build/Makefile | $(ACTIVATE_VENV)
	( cd $(PRJXRAY_PREFIX) && . $(ACTIVATE_VENV) && ENV_DIR="$(INSTALL_PREFIX)" $(MAKE) -j1 env && cd $(PRJXRAY_PREFIX)/build && $(MAKE) -j1 preinstall && $(CMAKE) $(CMAKE_INSTALL_CONFIG) -P cmake_install.cmake )

$(XRAY_SHARE_DIR)/prjxray_settings.sh: $(SELFDIR)/prjxray_settings.sh | $(XRAY_SHARE_DIR)
	cp -f $< $@

$(XRAY_SHARE_DIR)/environment.sh: $(PRJXRAY_PREFIX)/utils/environment.sh | $(XRAY_SHARE_DIR)
	cp -f $< $@

$(XRAY_SHARE_DIR)/environment.python.sh: $(PRJXRAY_PREFIX)/utils/environment.python.sh | $(XRAY_SHARE_DIR)
	cp -f $< $@

$(XRAY_SHARE_DIR)/vivado.sh: $(PRJXRAY_PREFIX)/utils/vivado.sh | $(XRAY_SHARE_DIR)
	cp -f $< $@

.PHONY: force-prjxray-env
force-prjxray-env $(XRAY_ENV): $(XRAY_SHARE_DIR)/prjxray_settings.sh $(XRAY_SHARE_DIR)/environment.sh $(XRAY_SHARE_DIR)/environment.python.sh $(XRAY_SHARE_DIR)/vivado.sh Makefile.conf
	@echo "export XRAY_VIVADO_SETTINGS=$(XRAY_SHARE_DIR)/prjxray_settings.sh;source $(XRAY_SHARE_DIR)/environment.sh" > $(XRAY_ENV) && \
	chmod +x $(XRAY_ENV)

# To depend on this correctly, you must depend on $(XRAY_DB_DIR)/<FAMILY>/<PART>
# example: $(XRAY_DB_DIR)/artix7/xc7a100tcsg324-1
.PRECIOUS: $(XRAY_SHARE_DIR)/%
.PRECIOUS: $(XRAY_DB_DIR)/%
$(XRAY_SHARE_DIR):
	mkdir -p $@
$(XRAY_DB_DIR): | $(XRAY_SHARE_DIR)
	( cd $(XRAY_SHARE_DIR) && git clone https://github.com/SymbiFlow/prjxray-db database )
$(XRAY_DB_DIR)/%: | $(XRAY_DB_DIR)

.PHONY: prjxray
prjxray: $(XC7FRAMES2BIT) $(XRAY_ENV) | $(XRAY_DB_DIR)

# --- nextpnr ---

NEXTPNR_SUBMODULE_INIT_ARGS:=--recursive
NEXTPNR_PYTHON?=OFF

$(NEXTPNR_PREFIX)/.git:
	$(MAKE) nextpnr-submodule

$(NEXTPNR_PREFIX)/CMakeLists.txt: | $(NEXTPNR_PREFIX)/.git

$(NEXTPNR_PREFIX)/cmake-build-ecp5/Makefile: $(NEXTPNR_PREFIX)/CMakeLists.txt $(PYTRELLIS) Makefile.conf | $(ACTIVATE_VENV)
	( cd $(NEXTPNR_PREFIX) && . $(ACTIVATE_VENV) && \
	$(CMAKE) . -B cmake-build-ecp5 -DBUILD_PYTHON=$(NEXTPNR_PYTHON) -DBUILD_GUI=OFF -DARCH="ecp5" -DTRELLIS_INSTALL_PREFIX="$(INSTALL_PREFIX)" $(CMAKE_INSTALL_CONFIG) && \
	$(CMAKE) --build cmake-build-ecp5 )

.PHONY: force-nextpnr-ECP5
force-nextpnr-ECP5 $(NEXTPNR_ECP5): $(NEXTPNR_PREFIX)/cmake-build-ecp5/Makefile | $(ACTIVATE_VENV)
	( cd $(NEXTPNR_PREFIX)/cmake-build-ecp5 && . $(ACTIVATE_VENV) && $(MAKE) && $(MAKE) -j1 install )

$(NEXTPNR_PREFIX)/cmake-build-ice40/Makefile: $(NEXTPNR_PREFIX)/CMakeLists.txt $(ICEPACK) Makefile.conf | $(ACTIVATE_VENV)
	( cd $(NEXTPNR_PREFIX) && . $(ACTIVATE_VENV) && \
	$(CMAKE) . -B cmake-build-ice40 -DBUILD_PYTHON=$(NEXTPNR_PYTHON) -DBUILD_GUI=OFF -DARCH="ice40" -DICESTORM_INSTALL_PREFIX="$(INSTALL_PREFIX)" $(CMAKE_INSTALL_CONFIG) && \
	$(CMAKE) --build cmake-build-ice40 )

.PHONY: force-nextpnr-ICE40
force-nextpnr-ICE40 $(NEXTPNR_ICE40): $(NEXTPNR_PREFIX)/cmake-build-ice40/Makefile | $(ACTIVATE_VENV)
	( cd $(NEXTPNR_PREFIX)/cmake-build-ice40 && . $(ACTIVATE_VENV) && $(MAKE) && $(MAKE) -j1 install )

$(NEXTPNR_PREFIX)/cmake-build-xilinx/Makefile: $(NEXTPNR_PREFIX)/CMakeLists.txt Makefile.conf | $(ACTIVATE_VENV) $(XRAY_DB_DIR)
	( cd $(NEXTPNR_PREFIX) && . $(ACTIVATE_VENV) && \
	$(CMAKE) . -B cmake-build-xilinx -DBUILD_PYTHON=$(NEXTPNR_PYTHON) -DBUILD_GUI=OFF -DARCH="himbaechel" -DHIMBAECHEL_UARCH="xilinx" -DHIMBAECHEL_SPLIT=1 -DHIMBAECHEL_PRJXRAY_DB="$(XRAY_DB_DIR)" $(CMAKE_INSTALL_CONFIG) && \
	$(CMAKE) --build cmake-build-xilinx )

.PHONY: force-nextpnr-XC7
force-nextpnr-XC7 $(NEXTPNR_HIMBAECHEL_XILINX): $(NEXTPNR_PREFIX)/cmake-build-xilinx/Makefile | $(ACTIVATE_VENV)
	( cd $(NEXTPNR_PREFIX)/cmake-build-xilinx && . $(ACTIVATE_VENV) && $(MAKE) && $(MAKE) -j1 install )

.PHONY: force-nextpnr
force-nextpnr: $(foreach A,$(ARCHITECTURES),force-nextpnr-$(strip $A) )

.PHONY: nextpnr
nextpnr: $(NEXTPNR_ECP5) $(NEXTPNR_ICE40) $(NEXTPNR_HIMBAECHEL_XILINX)

# --- ghdl ---

$(GHDL_PREFIX)/.git:
	$(MAKE) ghdl-submodule

$(GHDL_PREFIX)/build: | $(GHDL_PREFIX)/.git
	mkdir -p $@

$(GHDL_PREFIX)/configure: | $(GHDL_PREFIX)/.git

$(GHDL_PREFIX)/build/Makefile: $(GHDL_PREFIX)/configure Makefile.conf | $(GHDL_PREFIX)/build
	( cd $(GHDL_PREFIX)/build && ../configure --prefix="$(INSTALL_PREFIX)" --libghdldir="share/ghdl" )

.PHONY: force-ghdl
force-ghdl $(GHDL): $(GHDL_PREFIX)/build/Makefile
	( cd $(GHDL_PREFIX)/build && unset SOURCE_DATE_EPOCH && $(MAKE) -j1 OPT_FLAGS=-fPIC && $(MAKE) install )

.PHONY: ghdl
ghdl: $(GHDL)

# --- ghdl-yosys-plugin ---

$(GHDL_YOSYS_PLUGIN_PREFIX)/.git:
	$(MAKE) ghdl-yosys-submodule

# --- openFPGALoader ---

$(OPENFPGALOADER_PREFIX)/.git:
	$(MAKE) openFPGALoader-submodule

$(OPENFPGALOADER_PREFIX)/CMakeLists.txt: | $(OPENFPGALOADER_PREFIX)/.git

$(OPENFPGALOADER_PREFIX)/build: $(OPENFPGALOADER_PREFIX)/CMakeLists.txt
	mkdir -p $@

$(OPENFPGALOADER_PREFIX)/build/Makefile: $(OPENFPGALOADER_PREFIX)/CMakeLists.txt Makefile.conf | $(OPENFPGALOADER_PREFIX)/build
ifeq ($(HOST_SYSTEM),WSL)
	$(call MAKE_IN_MSYS,$@)
else
	( cd $(OPENFPGALOADER_PREFIX)/build && $(CMAKE) -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_STATIC=OFF -DENABLE_CMSISDAP=OFF $(CMAKE_INSTALL_CONFIG) .. )
endif

.PHONY: force-openFPGALoader
force-openFPGALoader $(OPENFPGALOADER): $(OPENFPGALOADER_PREFIX)/build/Makefile
ifeq ($(HOST_SYSTEM),WSL)
	$(call MAKE_IN_MSYS,$@)
else
	( cd $(OPENFPGALOADER_PREFIX)/build && $(CMAKE) --build . && $(CMAKE) --install . )
endif

.PHONY: openFPGALoader
openFPGALoader: $(OPENFPGALOADER)

# --- mega65-tools ---

$(MEGA65_TOOLS_PREFIX)/.git:
	$(MAKE) mega65-tools-submodule

$(MEGA65_TOOLS_PREFIX)/src/tools/coretool: | $(MEGA65_TOOLS_PREFIX)/.git

.PHONY: force-coretool
force-coretool $(CORETOOL): $(MEGA65_TOOLS_PREFIX)/src/tools/coretool | $(BINDIR)
	cp -f $< $(CORETOOL)

.PHONY: coretool
coretool: $(CORETOOL)

# --- lakfpga ---

$(LAKFPGA_PREFIX):
	mkdir -p $@

$(LAKFPGA_PREFIX)/%: $(SELFDIR)/% | $(LAKFPGA_PREFIX)
	cp -f $< $@

$(LAKFPGA_PREFIX)/Makefile.conf: Makefile Makefile.conf | $(LAKFPGA_PREFIX)
	echo 'INSTALL_PREFIX:=$(INSTALL_PREFIX)' > $@ && \
	echo 'ARCHITECTURES:=$(ARCHITECTURES)' >> $@ && \
	echo 'MSYS_PREFIX:=$(MSYS_PREFIX)' >> $@

.PHONY: install-lakfpga
install-lakfpga: $(LAKFPGA_PREFIX)/Makefile.conf $(LAKFPGA_PREFIX)/toolchain.mk

# --- pattern targets ---

STEM=$(shell echo '$*' | tr '[:lower:]' '[:upper:]' | tr '-' '_')

force-rebuild-%: FORCE
	$(MAKE) -j1 force-deinit-$*-submodule && \
	$(MAKE) -j1 $*-submodule && \
	$(MAKE) force-$*

%-submodule: FORCE
	$(warning init submodule for $* at $($(STEM)_PREFIX))
	( cd $(SELFDIR) && git submodule update --init $($(STEM)_SUBMODULE_INIT_ARGS) $($(STEM)_PREFIX) )

force-deinit-%-submodule: FORCE
	$(warning deinit submodule for $* at $($(STEM)_PREFIX))
	( cd $(SELFDIR) && git submodule deinit --force $($(STEM)_PREFIX) )

# --- clean ---

.PHONY: force-deinit-submodules
force-deinit-submodules:
	$(MAKE) -j1 \
	force-deinit-torii-hdl-submodule \
	force-deinit-torii-boards-submodule \
	force-deinit-yosys-submodule \
	force-deinit-prjtrellis-submodule \
	force-deinit-prjxray-submodule \
	force-deinit-nextpnr-submodule \
	force-deinit-nextpnr-xilinx-submodule \
	force-deinit-ghdl-submodule \
	force-deinit-ghdl-yosys-plugin-submodule \
	force-deinit-openFPGALoader-submodule \
	force-deinit-mega65-tools-submodule

.PHONY: hard-reset
hard-reset: force-deinit-submodules
ifeq ($(INSTALL_PREFIX),$(SELFDIR)/build)
	rm -rf $(SELFDIR)/build
endif

.PHONY: force-rebuild-all
force-rebuild-all: hard-reset
	$(MAKE) all

FORCE:
