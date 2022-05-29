# Common targets

define SHARED_BOARD_BUILDER=
BOARD_BIN_DIR=$$(BIN_DIR)/$1
$$(BOARD_BIN_DIR):
	mkdir -p $$@

ifneq ($$($1_VHDL),)
$$(BOARD_BIN_DIR)/$1_vhdl.ys: $$($1_VERILOG) $$($1_VHDL) | $$(BOARD_BIN_DIR) $$(YOSYS) $$(GHDL_YOSYS_PLUGIN)
	@echo "ghdl $$($1_VHDL) -e $$($1_VHDL_ELABORATE);" > $$@
else
$$(BOARD_BIN_DIR)/$1_vhdl.ys: $$($1_VERILOG) $$($1_VHDL) | $$(BOARD_BIN_DIR) $$(YOSYS) $$(GHDL_YOSYS_PLUGIN)
	@echo "" > $$@
endif

ifneq ($$($1_VERILOG),)
$$(BOARD_BIN_DIR)/$1_verilog.ys: $$($1_VERILOG) $$($1_VHDL) | $$(BOARD_BIN_DIR) $$(YOSYS)
	@echo "read_verilog $$($1_VERILOG);" > $$@
else
$$(BOARD_BIN_DIR)/$1_verilog.ys: $$($1_VERILOG) $$($1_VHDL) | $$(BOARD_BIN_DIR) $$(YOSYS)
	@echo "" > $$@
endif

$$(BOARD_BIN_DIR)/$1.ys: $$(BOARD_BIN_DIR)/$1_vhdl.ys $$(BOARD_BIN_DIR)/$1_verilog.ys
	cat $$(BOARD_BIN_DIR)/$1_vhdl.ys $$(BOARD_BIN_DIR)/$1_verilog.ys > $$@
endef

$(foreach B,$(ALL_BOARDS),$(eval $(call SHARED_BOARD_BUILDER,$B)))

# Xilinx specific targets

XILINX_BIN_DIR=$(BIN_DIR)/xilinx
$(XILINX_BIN_DIR):
	mkdir -p $@

.PRECIOUS: $(XILINX_BIN_DIR)/%.bba $(XILINX_BIN_DIR)/%.bin $(XILINX_BIN_DIR)/%.json $(XILINX_BIN_DIR)/%.fasm $(XILINX_BIN_DIR)/%.frames $(XILINX_BIN_DIR)/%.bit

$(XILINX_BIN_DIR)/%.bin: $(XILINX_BIN_DIR)/%.bba | $(BBASM)
	$(BBASM) --le $< $@

define XILINX_BOARD_BUILDER=
$$(XILINX_BIN_DIR)/$$($1_FPGA_PART).bba: | $$(BBAEXPORT) $$(XILINX_BIN_DIR) $$(XRAYDBDIR)/$$($1_FPGA_FAMILY)/$$($1_FPGA_PART)
	python3 $$(BBAEXPORT) --xray $$(XRAYDBDIR)/$$($1_FPGA_FAMILY) --device $$($1_FPGA_PART) --bba $$@

$$(BOARD_BIN_DIR)/$1.json: $$(BOARD_BIN_DIR)/$1.ys
	$$(GHDL_YOSYS) -s $$(BOARD_BIN_DIR)/$1.ys -p "synth_xilinx -abc9 -flatten -family $$($1_FPGA_ARCH) -top $$($1_TOP); write_json $$@"

$$(BOARD_BIN_DIR)/$1.fasm: $$(XILINX_BIN_DIR)/$$($1_FPGA_PART).bin $$(BOARD_BIN_DIR)/$1.json $$($1_XDC) | $$(NEXTPNR_XILINX)
	$$(NEXTPNR_XILINX) --chipdb $$(XILINX_BIN_DIR)/$$($1_FPGA_PART).bin --xdc $$($1_XDC) --json $$(BOARD_BIN_DIR)/$1.json --write $$(BOARD_BIN_DIR)/$1_routed.json --fasm $$@

$$(BOARD_BIN_DIR)/$1.frames: $$(BOARD_BIN_DIR)/$1.fasm | $$(FASM2FRAMES) $$(XRAYENV) $$(XRAYDBDIR)/$$($1_FPGA_FAMILY)/$$($1_FPGA_PART)
	$$(shell bash -c "source $$(XRAYENV) && python3 $$(FASM2FRAMES) --db-root '$$(XRAYDBDIR)/$$($1_FPGA_FAMILY)' --part $$($1_FPGA_PART) $$< > $$@ || ( rm $$@ ; return 1 )" )

$$(BIN_DIR)/$1.bit: $$(BOARD_BIN_DIR)/$1.frames $$(XRAYENV) | $$(XC7FRAMES2BIT) $$(SDCARD_DIR)
	$$(shell bash -c "source $$(XRAYENV) && $$(XC7FRAMES2BIT) --compressed --part_file '$$(XRAYDBDIR)/$$($1_FPGA_FAMILY)/$$($1_FPGA_PART)/part.yaml' --part_name $$($1_FPGA_PART) --frm_file $$< --output_file $$@" )
endef

$(foreach B,$(XILINX_BOARDS),$(eval $(call XILINX_BOARD_BUILDER,$B)))
