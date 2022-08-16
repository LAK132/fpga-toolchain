from amaranth import *
from amaranth.vendor.xilinx import *
from amaranth_boards.tinyfpga_bx import *
from amaranth_boards.test.blinky import *

if __name__ == "__main__":
    import os
    TinyFPGABXPlatform(toolchain="IceStorm").build(
        Blinky(),
        name="blink",
        build_dir="build/tinyfpga-bx",
        do_build=True,
        do_program=False)
