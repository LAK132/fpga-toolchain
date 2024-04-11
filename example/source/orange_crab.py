from torii import *
from torii.platform.vendor.lattice_ecp5 import *
from torii_boards.lattice.orangecrab_r0_2 import *
from torii_boards.test.blinky import *

if __name__ == "__main__":
	import os
	OrangeCrabR0_2Platform(toolchain="Trellis").build(
		Blinky(),
		do_build=True,
		do_program=False)
