from torii import *
from torii.vendor.xilinx import *
from torii_boards.orangecrab_r0_2 import *
from torii_boards.test.blinky import *

if __name__ == "__main__":
    import os
    OrangeCrabR0_2Platform(toolchain="Trellis").build(
        Blinky(),
        do_build=True,
        do_program=False)
