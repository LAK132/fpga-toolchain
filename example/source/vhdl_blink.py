from torii import *
from pathlib import Path
from torii.platform.vendor.xilinx import GhdlInstance
import os

__all__ = ["VhdlBlink"]


class VhdlBlink(Elaboratable):
	def elaborate(self, platform):
		m = Module()

		m.submodules += GhdlInstance(
			"led_blink",
			("i", "clock", ClockSignal()),
			("o", "led", platform.request("ethernet").led)
		)

		absolute_filename = Path(__file__).parent / f"blink.vhdl"
		filename = absolute_filename.relative_to(os.path.commonpath([absolute_filename, Path(os.getcwd())]))
		with open(absolute_filename, 'r') as f:
			platform.add_file(str(filename), f)

		return m
