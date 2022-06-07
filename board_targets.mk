ifeq ($(BUILD_DIR),)
$(error BUILD_DIR not set)
endif

ifeq ($(SOURCE_DIR),)
$(error SOURCE_DIR not set)
endif

ifeq ($(BOARDS_DIR),)
$(error BOARDS_DIR not set)
endif

# --- Common targets ---

define SHARED_BOARD_BUILDER=
$1_BUILD_DIR=$$(BUILD_DIR)/$1
$$($1_BUILD_DIR):
	mkdir -p $$@

$$($1_BUILD_DIR)/$2.cor: $$($1_BUILD_DIR)/$2.bit $$(BIT2CORE)
	$$(BIT2CORE) $1 $$< $$($2_CORE_NAME) $$($2_CORE_VERSION) $$@
$2.$1.cor: $$($1_BUILD_DIR)/$2.cor
	cp $$< $$@
endef

$(foreach B,$(ALL_BOARDS),\
$(foreach C,$(ALL_CORES),\
$(eval $(call SHARED_BOARD_BUILDER,$B,$C))))

# --- Generic VHDL/Verilog toolchain targets ---

define VHDL_VERILOG_BOARD_BUILDER=
ifneq ($$($2_VHDL),)
$$($1_BUILD_DIR)/$2_vhdl.ys: $$($2_VERILOG) $$($2_VHDL) | $$($1_BUILD_DIR) $$(YOSYS) $$(GHDL_YOSYS_PLUGIN)
	@echo "ghdl $$($2_VHDL) -e $$($2_VHDL_ELABORATE);" > $$@
else
$$($1_BUILD_DIR)/$2_vhdl.ys: $$($2_VERILOG) $$($2_VHDL) | $$($1_BUILD_DIR) $$(YOSYS) $$(GHDL_YOSYS_PLUGIN)
	@echo "" > $$@
endif

ifneq ($$($2_VERILOG),)
$$($1_BUILD_DIR)/$2_verilog.ys: $$($2_VERILOG) $$($2_VHDL) | $$($1_BUILD_DIR) $$(YOSYS)
	@echo "read_verilog $$($2_VERILOG);" > $$@
else
$$($1_BUILD_DIR)/$2_verilog.ys: $$($2_VERILOG) $$($2_VHDL) | $$($1_BUILD_DIR) $$(YOSYS)
	@echo "" > $$@
endif

$$($1_BUILD_DIR)/$2.ys: $$($1_BUILD_DIR)/$2_vhdl.ys $$($1_BUILD_DIR)/$2_verilog.ys
	cat $$^ > $$@
endef

$(foreach B,$(ALL_BOARDS),\
$(foreach C,$(ALL_VHDL_VERILOG_CORES),\
$(eval $(call VHDL_VERILOG_BOARD_BUILDER,$B,$C))))

# --- Xilinx specific targets ---

XILINX_BUILD_DIR=$(BUILD_DIR)/xilinx
$(XILINX_BUILD_DIR):
	mkdir -p $@

.PRECIOUS: $(XILINX_BUILD_DIR)/%.bba $(XILINX_BUILD_DIR)/%.bin $(XILINX_BUILD_DIR)/%.json $(XILINX_BUILD_DIR)/%.fasm $(XILINX_BUILD_DIR)/%.frames $(XILINX_BUILD_DIR)/%.bit

$(XILINX_BUILD_DIR)/%.bin: $(XILINX_BUILD_DIR)/%.bba | $(BBASM)
	$(BBASM) --le $< $@

# --- Xilinx specific VHDL/Verilog toolchain targets ---

define XILINX_BOARD_BUILDER=
$$(XILINX_BUILD_DIR)/$$($1_FPGA_PART).bba: | $$(BBAEXPORT) $$(XILINX_BUILD_DIR) $$(XRAYDBDIR)/$$($1_FPGA_FAMILY)/$$($1_FPGA_PART)
	python3 $$(BBAEXPORT) --xray $$(XRAYDBDIR)/$$($1_FPGA_FAMILY) --device $$($1_FPGA_PART) --bba $$@

$$($1_BUILD_DIR)/$2.json: $$($1_BUILD_DIR)/$2.ys
	$$(GHDL_YOSYS) -s $$($1_BUILD_DIR)/$2.ys -p "synth_xilinx -abc9 -flatten -family $$($1_FPGA_ARCH) -top $$($2_TOP); write_json $$@"

$$($1_BUILD_DIR)/$2.fasm: $$(XILINX_BUILD_DIR)/$$($1_FPGA_PART).bin $$($1_BUILD_DIR)/$2.json $$($1_XDC) | $$(NEXTPNR_XILINX)
	$$(NEXTPNR_XILINX) --chipdb $$(XILINX_BUILD_DIR)/$$($1_FPGA_PART).bin --xdc $$($1_XDC) --json $$($1_BUILD_DIR)/$2.json --write $$($1_BUILD_DIR)/$2_routed.json --fasm $$@

$$($1_BUILD_DIR)/$2.frames: $$($1_BUILD_DIR)/$2.fasm | $$(FASM2FRAMES) $$(XRAYENV) $$(XRAYDBDIR)/$$($1_FPGA_FAMILY)/$$($1_FPGA_PART)
	$$(shell bash -c "source $$(XRAYENV) && python3 $$(FASM2FRAMES) --db-root '$$(XRAYDBDIR)/$$($1_FPGA_FAMILY)' --part $$($1_FPGA_PART) $$< > $$@ || ( rm $$@ ; return 1 )" )

$$($1_BUILD_DIR)/$2.bit: $$($1_BUILD_DIR)/$2.frames $$(XRAYENV) | $$(XC7FRAMES2BIT) $$(SDCARD_DIR)
	$$(XC7FRAMES2BIT) --compressed --part_file '$$(XRAYDBDIR)/$$($1_FPGA_FAMILY)/$$($1_FPGA_PART)/part.yaml' --part_name $$($1_FPGA_PART) --frm_file $$< --output_file $$@
endef

$(foreach B,$(ALL_XILINX_BOARDS),\
$(foreach C,$(ALL_VHDL_VERILOG_CORES),\
$(eval $(call XILINX_BOARD_BUILDER,$B,$C))))

# --- Xilinx specific Amaranth toolchain targets ---
# :TODO: we should probably be invoking a generated python script that imports
# the requested modules and platform
define AMARANTH_BOARD_BUILDER=
$$(warning $$($1_BUILD_DIR)/$2.bit)
$$($1_BUILD_DIR)/$2.bit: $$($2_PYTHON) | $$($1_BUILD_DIR) $$(XILINX_BUILD_DIR)/$$($1_FPGA_PART).bin $$(YOSYS) $$(NEXTPNR_XILINX) $$(FASM2FRAMES) $$(XC7FRAMES2BIT) $$(XRAYENV) $$(XRAYDBDIR)/$$($1_FPGA_FAMILY)/$$($1_FPGA_PART)
	YOSYS="$$(YOSYS)" \
	NEXTPNR_XILINX="$$(NEXTPNR_XILINX)" \
	XRAYENV="$$(XRAYENV)" \
	FASM2FRAMES="$$(FASM2FRAMES_SH)" \
	ACTUALFASM2FRAMES="$$(FASM2FRAMES)" \
	XC7FRAMES2BIT="$$(XC7FRAMES2BIT)" \
	AMARANTH_nextpnr_db_dir="$$(XILINX_BUILD_DIR)" \
	AMARANTH_prjxray_db_dir="$$(XRAYDBDIR)" \
	BITSTREAM_NAME="$2" \
	BUILD_DIR="$$($1_BUILD_DIR)" \
	python3 $$($2_PYTHON)
endef

$(foreach B,$(ALL_XILINX_BOARDS),\
$(foreach C,$(ALL_AMARANTH_CORES),\
$(eval $(call AMARANTH_BOARD_BUILDER,$B,$C))))
