# FPGA Toolchain

A set of tools required for systhesising FPGA bitstreams.

Languages:
- Python (Torii)
- Verilog (Yosys)
- VHDL (GHDL)

Boards:
- Anything supported by Torii (torii-boards)

Bitstreams:
- iCE40 (icestorm)
- ECP5 (prjtrellis)
- Xilinx 7-series (prjxray)
	- MEGA65 cores (mega65-tools)

For usage demos, see the example project `example/`

# Building

Unless otherwise stated, run all commands from the root directory of this repo.

Adjust `Makefile.conf` to preference.

```
INSTALL_PREFIX=$(SELFDIR)/build
ARCHITECTURES=XC7 ICE40 ECP5
MSYS_PREFIX=/mnt/c/msys
```

`INSTALL_PREFIX`: where to install tools and data, defaults to a `build/` directory in the root of this repo.

`ARCHITECTURES`: which architectures to support (case sensitive):
* `XC7`: Xilinx 7-series
* `ICE40`: Lattice iCE40
* `ECP5`: Lattice ECP5

`MSYS_PREFIX`: WSL2 path to MSYS (Windows only).

## Dependencies

### NixOS
```
nix-shell shell.nix
```

### Ubuntu

python 3.11 is required. You may need to add the deadsnakes PPA (`sudo add-apt-repository ppa:deadsnakes/ppa`) if isn't available by default.

```
sudo make install_dependencies
```

### Windows

Synthesis should work under both WSL2 Ubuntu and MSYS.
MSYS is required for the flashing tools.

If you intend to use WSL2 and MSYS then you will need to make sure `MSYS_PREFIX` is set in `Makefile.conf` so that WSL2 can invoke relevant MSYS binaries (should be the UNIX style path ***from WSL2*** to MSYS, not the Windows path to MSYS).

#### MSYS
```
sudo make install_dependencies
```

#### WSL2 Ubuntu + MSYS
```
sudo make install_dependencies install_msys_dependencies
```

## Tools
```
make all              # normal single core build
make all-fast         # alias for `make all -j$(nproc)`
make force-all        # forcefully rebuild and reinstall all tools
make force-all-fast   # alias for `make force-all -j$(nproc)`
```

## Example
These commands should be run from the `example/` folder (`cd example`).

Build the `blink` bitstream for the MEGA65 R3:
```
make blink-mega65r3.bit
```

Build the `blink` core for the MEGA65 R3:
```
make blink-mega65r3.cor
```

Build and flash the `blink` bitstream to a MEGA65 R3 with a Black Magic Debug Probe:
```
FLASH_CABLE=bmd FLASH_PORT=/dev/ttyACM1 make jtag-flash-blink-mega65r3   # Linux
FLASH_CABLE=bmd FLASH_PORT=COM4 make jtag-flash-blink-mega65r3           # WSL2/MSYS
```
`FLASH_CABLE` and `FLASH_PORT` defaults can be changed in `example/Makefile.conf`
