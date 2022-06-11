from amaranth import *
from amaranth.build import *
from amaranth.vendor.xilinx import *
from open_xilinx_platform import *

__all__ = ["Mega65r3Platform"]


class Mega65r3Platform(OpenXilinxPlatform):
    device = "xc7a200t"
    package = "fbg484"
    speed = "2"
    default_clk = "clk_in"
    required_tools = []
    resources = [
        Resource("clk_in", 0,
                 Pins("V13", dir="i"),
                 Clock(10e7),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("led", 0,
                 Pins("U22", dir="o"),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("iec", 0,
                 Subsignal("rst", Pins("AB21", dir="o")),
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
                 Subsignal("dotclk", Pins("AA19", dir="o")),
                 Subsignal("rst", Pins("N14", dir="o")),

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
                     "P16 R17 P20 R16 U18 V18 W20 W21", dir="io")),

                 Subsignal("addr", Pins(
                     "K19 K18 K21 M22 L20 J20 J21 K22 "
                     "H17 H20 G20 J15 H19 M20 N22 H18",
                     dir="io")),

                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("keyboard", 0,
                 Subsignal("out", Pins("A14 A13", dir="o")),
                 Subsignal("in", Pins("C13", dir="i")),
                 #  Subsignal("tck", Pins("E13", dir="")),
                 #  Subsignal("tdo", Pins("E14", dir="")),
                 #  Subsignal("tdi", Pins("D15", dir="")),
                 #  Subsignal("tms", Pins("D14", dir="")),
                 Subsignal("jtag_en", Pins("B13", dir="o")),

                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("paddle", 0,
                 Subsignal("in", Pins("H13 G15 J14 J22", dir="i")),
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
                     "U15 V15 T14 Y17 Y16 AB17 AA16 AB16", dir="o")),
                 Subsignal("green", Pins(
                     "Y14 W14 AA15 AB15 Y13 AA14 AA13 AB13", dir="o")),
                 Subsignal("blue", Pins(
                     "W10 Y12 AB12 AA11 AB11 Y11 AB10 AA10", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("hdmi", 0,
                 Subsignal("clk", DiffPairs("W1", "Y1", dir="o")),
                 Subsignal("data", DiffPairs(
                     "AA1 AB3 AA5", "AB1 AB2 AB5", dir="o")),
                 Subsignal("scl", Pins("AB7", dir="io")),
                 Subsignal("sda", Pins("V9", dir="io")),
                 Subsignal("en", Pins("AB8", dir="o")),  # aka ls_oe
                 Subsignal("hpd", Pins("Y8", dir="i")),
                 Subsignal("hpd_en", Pins("M15", dir="o")),
                 Subsignal("cec", Pins("W9", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("i2c", 0,
                 Subsignal("scl", Pins("A15", dir="io")),
                 Subsignal("sda", Pins("A16", dir="io")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        # Resource("jtag", 0,
        #           Subsignal("tck", Pins("V12", dir="")),
        #           Subsignal("tdi", Pins("R13", dir="")),
        #           Subsignal("tdo", Pins("U13", dir="")),
        #           Subsignal("tms", Pins("T13", dir="")),
        #           Subsignal("init", Pins("U12", dir="")),
        #          Attrs(IOSTANDARD="LVCMOS33")),

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
                 Subsignal("data", Pins("P22 R22 P21 R21", dir="io"),
                           Attrs(PULLUP="TRUE")),
                 Subsignal("cs", PinsN("T19", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("hyper_ram", 0,
                 Subsignal("clk", Pins("D22", dir="o"),
                           Attrs(SLEW="FAST", DRIVE="16")),
                 Subsignal("data", Pins(
                     "A21 D21 C20 A20 B20 A19 E21 E22", dir="io"),
                     Attrs(SLEW="FAST", DRIVE="16")),
                 Subsignal("rwds", Pins("B21", dir="io"),
                           Attrs(SLEW="FAST", DRIVE="16")),
                 Subsignal("rst", Pins("B22", dir="o")),
                 Subsignal("cs", Pins("C22", dir="o")),
                 Attrs(IOSTANDARD="LVCMOS33", PULLUP="FALSE")),

        # Resource("hyper_ram", 1,
        #          Subsignal("clk", Pins("G1", dir="o")),
        #          Subsignal("data", Pins(
        #              "B2 E1 G4 E3 D2 B1 C2 D1", dir="io")),
        #          Subsignal("rwds", Pins("H4", dir="io")),
        #          Subsignal("rst", Pins("H5", dir="o")),
        #          Subsignal("cs", Pins("J5", dir="o")),
        #          Attrs(IOSTANDARD="LVCMOS33", PULLUP="FALSE")),

        Resource("ethernet", 0,
                 Subsignal("led", Pins("R14", dir="o")),
                 Subsignal("clk", Pins("L4", dir="o"),
                           Attrs(SLEW="FAST")),
                 Subsignal("rst", Pins("K6", dir="o")),
                 Subsignal("mdio", Pins("L5", dir="io")),
                 Subsignal("mdc", Pins("J6", dir="o")),
                 Subsignal("rxd", Pins("P4 L1", dir="i")),
                 Subsignal("txd", Pins("L3 K3", dir="o"),
                           Attrs(SLEW="SLOW", DRIVE="4")),
                 Subsignal("rxer", Pins("M6", dir="i")),
                 Subsignal("txen", Pins("J4", dir="o"),
                           Attrs(SLEW="SLOW", DRIVE="4")),
                 Subsignal("rxdv", Pins("K4", dir="i")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("rs232", 0,
                 Subsignal("tx", Pins("L13", dir="o")),
                 Subsignal("rx", Pins("L14", dir="i")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("max10", 0,
                 Subsignal("tx", Pins("M13", dir="i")),
                 Subsignal("rx", Pins("K16", dir="o")),
                 Subsignal("rst", Pins("L16", dir="io")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("sd", 0,
                 Subsignal("clk", Pins("B17", dir="o")),
                 Subsignal("rst", Pins("B15", dir="o")),
                 Subsignal("miso", Pins("B18", dir="i")),
                 Subsignal("mosi", Pins("B16", dir="o")),
                 Subsignal("cd", Pins("D17", dir="i")),
                 Subsignal("wp", Pins("C17", dir="i")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("micro_sd", 0,
                 Subsignal("clk", Pins("G2", dir="o")),
                 Subsignal("rst", Pins("K2", dir="o")),
                 Subsignal("miso", Pins("H2", dir="i")),
                 Subsignal("mosi", Pins("J2", dir="o")),
                 Subsignal("cd", Pins("K1", dir="i")),
                 Attrs(IOSTANDARD="LVCMOS33")),

        Resource("floppy", 0,
                 Subsignal("density", Pins("P6", dir="o")),
                 Subsignal("motor", Pins("M5 H15", dir="o")),
                 Subsignal("select", Pins("N5 G17", dir="o")),
                 Subsignal("step_dir", Pins("P5", dir="o")),
                 Subsignal("step", Pins("M3", dir="o")),
                 Subsignal("wdata", Pins("N4", dir="o")),
                 Subsignal("wgate", Pins("N3", dir="o")),
                 Subsignal("side1", Pins("M1", dir="o")),
                 Subsignal("index", Pins("M2", dir="i")),
                 Subsignal("track0", Pins("N2", dir="i")),
                 Subsignal("wp", Pins("P2", dir="i")),
                 Subsignal("rdata", Pins("P1", dir="i")),
                 Subsignal("diskchanged", Pins("R1", dir="i")),
                 Attrs(IOSTANDARD="LVCMOS33")),
    ]
    connectors = [
        Connector("pmod", 0, "G1 E1 C2 B1 - - F1 D1 B2 A1 - -"),
        Connector("pmod", 1, "E2 D2 G4 J5 - - F3 E3 H4 H5 - -"),
        Connector("test", 0, "T16 U16 W16 J19 K17 N19 N20 D20")
    ]
