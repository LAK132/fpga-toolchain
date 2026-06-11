from vhdl_blink import *
from torii.hdl import *
from torii_boards.xilinx.artix7.mega65 import *


class Top(Elaboratable):
	def elaborate(self, platform):
		m = Module()

		led = platform.request("led")
		eth_led = platform.request("ethernet").led

		m.submodules += VhdlBlink(led)
		m.d.sync += eth_led.eq(led)

		return m


if __name__ == "__main__":
	import os
	Mega65r3Platform(toolchain="yosys_nextpnr-himbaechel").build(
		script_after_read = f"ghdl {Path(__file__).parent / f"blink.vhdl"} -e led_blink;"
		Top(),
		do_build=True,
		do_program=False)
