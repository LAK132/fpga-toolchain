from torii.hdl import *
from torii_boards.lattice.ice40.tinyfpga_bx import *
from torii_boards.test.blinky import *

if __name__ == "__main__":
	import os
	TinyFPGABXPlatform(toolchain="IceStorm").build(
		Blinky(),
		do_build=True,
		do_program=False)
