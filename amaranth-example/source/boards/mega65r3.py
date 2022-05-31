from amaranth import *
from amaranth.build import *
from amaranth.vendor.xilinx import *

__all__ = ["Mega65r3Platform"]


class Mega65r3Platform(XilinxPlatform):
    device = "xc7a200t"
    package = "fbg484"
    speed = "2"
    default_clk = "clk_in"
    required_tools = []
    resources = [
        Resource("clk_in", 0, Pins("V13", dir="i"),
                 Clock(10e7), Attrs(IOSTANDARD="LVCMOS33")),

        Resource("led", 0, Pins("U22", dir="o"), Attrs(IOSTANDARD="LVCMOS33")),

        Resource("iec", 0,
                 Subsignal("reset", Pins("AB21", dir="o")),
                 Subsignal("atn", Pins("N17", dir="o")),

                 Subsignal("data_en", Pins("Y21", dir="o")),
                 Subsignal("data_o", Pins("Y22", dir="o")),
                 Subsignal("data_i", Pins("AB22", dir="i"),
                           Attrs(PULLUP="TRUE")),

                 Subsignal("clk_en", Pins("AA21", dir="o")),
                 Subsignal("clk_o", Pins("Y19", dir="o")),
                 Subsignal("clk_i", Pins("Y18", dir="i"),
                           Attrs(PULLUP="TRUE")),

                 Subsignal("srq_en", Pins("AB20", dir="o")),
                 Subsignal("srq_o", Pins("U20", dir="o")),
                 Subsignal("srq_i", Pins("AA18", dir="i")),

                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("cartridge", 0,
                 Subsignal("ctrl_en", Pins("G18", dir="o")),
                 Subsignal("ctrl_dir", Pins("U17", dir="o")),

                 Subsignal("addr_en", Pins("L19", dir="o")),
                 Subsignal("hi_addr_dir", Pins("L18", dir="o")),
                 Subsignal("lo_addr_dir", Pins("L21", dir="o")),

                 Subsignal("data_en", Pins("U21", dir="o")),
                 Subsignal("data_dir", Pins("V22", dir="o")),

                 Subsignal("phi2", Pins("V17", dir="o")),
                 Subsignal("dotclock", Pins("AA19", dir="o")),
                 Subsignal("reset", Pins("N14", dir="o")),


                 Subsignal("nmi", Pins("W17", dir="i")),
                 Subsignal("irq", Pins("P14", dir="i")),
                 Subsignal("dma", Pins("P15", dir="i")),

                 Subsignal("exrom", Pins("R19", dir="io")),
                 Subsignal("ba", Pins("N13", dir="io")),
                 Subsignal("rw", Pins("R18", dir="io")),
                 Subsignal("rom_lo", Pins("AB18", dir="io")),
                 Subsignal("rom_hi", Pins("T18", dir="io")),
                 Subsignal("io1", Pins("N15", dir="io")),
                 Subsignal("game", Pins("W22", dir="io")),
                 Subsignal("io2", Pins("AA20", dir="io")),

                 Subsignal("data", Pins(
                     "W21 W20 V18 U18 R16 P20 R17 P16", dir="io")),

                 Subsignal("addr", Pins(
                     "H18 N22 M20 H19 J15 G20 H20 H17 "
                     "K22 J21 J20 L20 M22 K21 K18 K19",
                     dir="io")),

                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("keyboard", 0,
                 Subsignal("out", Pins("A14 A13", dir="o")),
                 Subsignal("in", Pins("C13", dir="i")),

                 #  Subsignal("tck", Pins("E13", dir="")),
                 #  Subsignal("tdo", Pins("E14", dir="")),
                 #  Subsignal("tms", Pins("D14", dir="")),
                 #  Subsignal("tdi", Pins("D15", dir="")),
                 Subsignal("jtag_en", Pins("B13", dir="o")),

                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("paddle", 0,
                 Subsignal("in", Pins("J22 J14 G15 H13", dir="i")),
                 Subsignal("drain", Pins("H22", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("joystick", 0,
                 Subsignal("up", Pins("C14", dir="i")),
                 Subsignal("down", Pins("F16", dir="i")),
                 Subsignal("left", Pins("F14", dir="i")),
                 Subsignal("right", Pins("F13", dir="i")),
                 Subsignal("fire", Pins("E17", dir="i")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("joystick", 1,
                 Subsignal("up", Pins("W19", dir="i")),
                 Subsignal("down", Pins("P17", dir="i")),
                 Subsignal("left", Pins("F21", dir="i")),
                 Subsignal("right", Pins("C15", dir="i")),
                 Subsignal("fire", Pins("F15", dir="i")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("vga", 0,
                 Subsignal("clk", Pins("AA9", dir="o")),
                 Subsignal("sync", PinsN("V10", dir="o")),
                 Subsignal("blank", PinsN("W11", dir="o")),
                 Subsignal("hsync", Pins("W12", dir="o")),
                 Subsignal("vsync", Pins("V14", dir="o")),
                 Subsignal("red", Pins(
                     "AB16 AA16 AB17 Y16 Y17  T14  V15 U15", dir="o")),
                 Subsignal("green", Pins(
                     "AB13 AA13 AA14 Y13 AB15 AA15 W14 Y14", dir="o")),
                 Subsignal("blue", Pins(
                     "AA10 AB10 Y11 AB11 AA11 AB12 Y12 W10", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("hdmi", 0,
                 Subsignal("clk", DiffPairs("W1", "Y1", dir="o")),
                 Subsignal("data", DiffPairs(
                     "AA5 AB3 AA1", "AB5 AB2 AB1", dir="o")),
                 Subsignal("scl", Pins("AB7", dir="io")),
                 Subsignal("sda", Pins("V9", dir="io")),
                 Subsignal("en", Pins("AB8", dir="o")),  # aka ls_oe
                 Subsignal("hpd", Pins("Y8", dir="i")),  # hot plug detect
                 Subsignal("hpd_en", Pins("M15", dir="o")),  # hot plug detect
                 Subsignal("cec", Pins("W9", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("i2c", 0,
                 Subsignal("scl", Pins("A15", dir="io")),
                 Subsignal("sda", Pins("A16", dir="io")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("jtag", 0,
                 #  Subsignal("tdi", Pins("R13", dir="")),
                 #  Subsignal("tdo", Pins("U13", dir="")),
                 #  Subsignal("tck", Pins("V12", dir="")),
                 #  Subsignal("tms", Pins("T13", dir="")),
                 #  Subsignal("init", Pins("U12", dir="")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        # Seeed Grove
        Resource("grove", 0,
                 Subsignal("scl", Pins("G21", dir="io")),
                 Subsignal("sda", Pins("G22", dir="io")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("audio", 0,
                 Subsignal("left", Pins("L6", dir="o")),
                 Subsignal("right", Pins("F4", dir="o")),
                 Subsignal("sd", Pins("F18", dir="o")),
                 Subsignal("speaker", Pins("E16", dir="o")),
                 Subsignal("mclk", Pins("D16", dir="o")),
                 Subsignal("bclk", Pins("E19", dir="o")),
                 Subsignal("sync", Pins("F19", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("spi_flash", 0,
                 Subsignal("data", Pins("R21 P21 R22 P22", dir="io"),
                           Attrs(PULLUP="TRUE")),
                 Subsignal("cs", PinsN("T19", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("hyper_ram", 0,
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("ethernet", 0,
                 Subsignal("led", Pins("R14", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("rs232", 0,
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("max10", 0,
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("sd", 0,
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("sd", 1,
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("floppy", 0,
                 Attrs(IOSTANDARD="LVCMOS33")),
    ]
    connectors = [
        Connector("pmod", 0, "F1 D1 B2 A1 - - G1 E1 C2 B1 - -"),
        Connector("pmod", 1, "F3 E3 H4 H5 - - E2 D2 G4 J5 - -"),
        Connector("test", 0, "D20 N20 N19 K17 J19 W16 U16 T16")
    ]
