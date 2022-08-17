from amaranth import *
from amaranth.vendor.xilinx import *
from amaranth_boards.orangecrab_r0_2 import *
from amaranth_boards.test.blinky import *

if __name__ == "__main__":
    import os
    OrangeCrabR0_2Platform(toolchain="Trellis").build(
        Blinky(),
        do_build=True,
        do_program=False)
