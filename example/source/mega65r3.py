from torii_blink import *
from vhdl_blink import *
from torii import *
from torii_boards.mega65 import *


class Top(Elaboratable):
    def elaborate(self, platform):
        m = Module()
        m.submodules += ToriiBlink()
        m.submodules += VhdlBlink()
        return m


if __name__ == "__main__":
    import os
    Mega65r3Platform(toolchain="yosys_nextpnr").build(
        Top(),
        do_build=True,
        do_program=False)
