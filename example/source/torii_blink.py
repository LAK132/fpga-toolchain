from torii.hdl import *
from torii.hdl.time import Frequency, Hz
from torii.lib.io import Pin

__all__ = ["ToriiBlink"]


class ToriiBlink(Elaboratable):
	def __init__(self, led: Pin, freq: Frequency = Hz(2)):
		self.led = led
		self.freq = freq

	def elaborate(self, platform):
		m = Module()

		timer_max = int(platform.default_clk_frequency.hertz // self.freq.hertz)
		timer = Signal(range(timer_max+1))

		with m.If(timer == timer_max):
			m.d.sync += self.led.eq(~self.led)
			m.d.sync += timer.eq(0)
		with m.Else():
			m.d.sync += timer.eq(timer + 1)

		return m
