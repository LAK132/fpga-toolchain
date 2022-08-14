from amaranth_blink import *
from vhdl_blink import *
from amaranth import *
from amaranth_boards.mega65_r3 import *


class Top(Elaboratable):
    def elaborate(self, platform):
        m = Module()
        m.submodules += AmaranthBlink()
        m.submodules += VhdlBlink()
        return m


if __name__ == "__main__":
    import os
    Mega65r3Platform(toolchain="yosys_nextpnr").build(
        Top(),
        name="blink",
        build_dir="build/mega65r3",
        do_build=True,
        do_program=False)
