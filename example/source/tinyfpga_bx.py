from torii import *
from torii.vendor.xilinx import *
from torii_boards.tinyfpga_bx import *
from torii_boards.test.blinky import *

if __name__ == "__main__":
    import os
    TinyFPGABXPlatform(toolchain="IceStorm").build(
        Blinky(),
        do_build=True,
        do_program=False)
