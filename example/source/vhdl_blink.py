from torii import *
from pathlib import Path
from torii.vendor.xilinx import GhdlInstance

__all__ = ["VhdlBlink"]


class VhdlBlink(Elaboratable):
    def elaborate(self, platform):
        m = Module()

        m.submodules += GhdlInstance(
            "led_blink",
            ("i", "clock", ClockSignal()),
            ("o", "led", platform.request("ethernet").led)
        )

        filename = Path(__file__).parent / f"blink.vhdl"
        with open(filename, 'r') as f:
            platform.add_file(str(filename), f)

        return m
