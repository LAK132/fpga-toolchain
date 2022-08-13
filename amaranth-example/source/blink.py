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
    if os.environ["BUILD_DIR"].endswith("mega65r3"):
        from amaranth_boards.mega65_r3 import *
        Mega65r3Platform(toolchain="yosys_nextpnr").build(
            Top(),
            name=os.environ["BITSTREAM_NAME"],
            build_dir=os.environ["BUILD_DIR"],
            do_build=True,
            do_program=False)
    elif os.environ["BUILD_DIR"].endswith("orange-crab"):
        from amaranth_boards.orangecrab_r0_2 import *
        from amaranth_boards.test.blinky import *
        OrangeCrabR0_2Platform().build(
            Blinky(),
            name=os.environ["BITSTREAM_NAME"],
            build_dir=os.environ["BUILD_DIR"],
            do_build=True,
            do_program=False)
