ALL_BOARDS=
ALL_XILINX_BOARDS=

define DECLARE_XILINX_BOARD=
$1_FPGA_FAMILY=$2
$1_FPGA_ARCH=$3
$1_FPGA_PART=$4
$1_XDC=$5
ALL_BOARDS+=$1
ALL_XILINX_BOARDS+=$1
endef

define DECLARE_VHDL_VERILOG_CORE=
$1_CORE_NAME=$2
$1_CORE_VERSION=$3
$1_TOP=$4
$1_VERILOG=$5
$1_VHDL=$6
$1_VHDL_ELABORATE=$7
ALL_CORES+=$1
ALL_VHDL_VERILOG_CORES+=$1
endef

define DECLARE_AMARANTH_CORE=
$1_CORE_NAME=$2
$1_CORE_VERSION=$3
$1_PYTHON=$4
ALL_CORES+=$1
ALL_AMARANTH_CORES+=$1
endef
