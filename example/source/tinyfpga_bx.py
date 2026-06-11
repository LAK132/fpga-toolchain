from torii_blink import *
from torii.hdl import *
from torii_boards.lattice.ice40.tinyfpga_bx import *


class Top(Elaboratable):
	def elaborate(self, platform):
		m = Module()
		m.submodules += ToriiBlink(platform.request("led"))
		return m


if __name__ == "__main__":
	import os
	TinyFPGABXPlatform(toolchain="IceStorm").build(
		Top(),
		do_build=True,
		do_program=False)
