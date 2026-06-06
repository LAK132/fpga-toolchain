from torii.hdl import *
from torii_boards.lattice.ecp5.orangecrab_r0_2 import *
from torii_boards.test.blinky import *

if __name__ == "__main__":
	import os
	OrangeCrabR0_2Platform(toolchain="Trellis").build(
		Blinky(),
		do_build=True,
		do_program=False)
