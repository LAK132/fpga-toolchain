from torii.hdl import *
from pathlib import Path
import os

__all__ = ["VerilogBlink"]


class VerilogBlink(Elaboratable):
	def elaborate(self, platform):
		m = Module()

		m.submodules += Instance(
			"led_blink",
			("i", "clock", ClockSignal()),
			("o", "led", platform.request("led"))
		)

		absolute_filename = Path(__file__).parent / f"blink.v"
		filename = absolute_filename.relative_to(os.path.commonpath([absolute_filename, Path(os.getcwd())]))
		with open(absolute_filename, 'r') as f:
			platform.add_file(str(filename), f)

		return m
