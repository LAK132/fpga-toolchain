from boards.mega65r3 import *
from amaranth_blink import *
from vhdl_blink import *
from amaranth import *
from amaranth.vendor.xilinx import *


class Top(Elaboratable):
    def elaborate(self, platform):
        m = Module()
        m.submodules += AmaranthBlink()
        m.submodules += VhdlBlink()
        return m


if __name__ == "__main__":
    import os
    Mega65r3Platform(toolchain="ghdl_yosys_nextpnr_prjxray").build(
        Top(),
        name=os.environ["BITSTREAM_NAME"],
        build_dir=os.environ["BUILD_DIR"],
        do_build=True,
        do_program=False)
