from boards.mega65r3 import *
from amaranth import *
from amaranth.vendor.xilinx import *


class Blink(Elaboratable):
    def elaborate(self, platform):
        m = Module()

        led = platform.request("led")
        eth_led = platform.request("ethernet").led

        half_freq = int(platform.default_clk_frequency // 2)
        timer = Signal(range(half_freq+1))

        with m.If(timer == half_freq):
            m.d.sync += led.eq(~led)
            m.d.sync += eth_led.eq(~eth_led)
            m.d.sync += timer.eq(0)
        with m.Else():
            m.d.sync += timer.eq(timer + 1)

        return m


if __name__ == "__main__":
    Mega65r3Platform(toolchain="yosys_nextpnr").build(
        Blink(), name="blink", build_dir="build",
        do_build=True, do_program=False)
