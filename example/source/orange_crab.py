from torii_blink import *
from torii.hdl import *
from torii_boards.lattice.ecp5.orangecrab_r0_2 import *


class Top(Elaboratable):
	def elaborate(self, platform):
		m = Module()
		m.submodules += ToriiBlink(platform.request("rgb_led").r)
		return m


if __name__ == "__main__":
	import os
	OrangeCrabR0_2Platform(toolchain="Trellis").build(
		Top(),
		do_build=True,
		do_program=False)
