ALL_BOARDS=
XILINX_BOARDS=

define DECLARE_XILINX_BOARD=
$1_FPGA_FAMILY=$2
$1_FPGA_ARCH=$3
$1_FPGA_PART=$4
ALL_BOARDS+=$1
XILINX_BOARDS+=$1
endef

define DECLARE_BOARD_SOURCE=
$1_XDC=$2
$1_TOP=$3
$1_VERILOG=$4
$1_VHDL=$5
$1_VHDL_ELABORATE=$6
endef
