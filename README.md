# FPGA Toolchain

A set of tools required for systhesising FPGA bitstreams.

Languages:
- Torii (torii-hdl)
- Verilog (yosys)
- VHDL (GHDL)

Boards:
- Anything supported by torii-boards

Bitstreams:
- iCE40 (icestorm)
- ECP5 (prjtrellis)
- Xilinx 7-series (prjxray)
	- MEGA65 cores (mega65-tools)

For usage demos, see the example project `example/`

# Building

Unless otherwise stated, run all commands from the root directory of this repo.

Adjust `Makefile.conf` to preference.
`INSTALL_PREFIX` will default to building the tools into a `build/` directory in the root of this repo.

## Dependencies

python 3.11 is required.
If this isn't available on Ubuntu you may need to add the deadsnakes PPA (`sudo add-apt-repository ppa:deadsnakes/ppa`).

### NixOS
```
nix-shell shell.nix
```

### Ubuntu
```
sudo make install_dependencies
```

### Windows

Synthesis should work under both WSL2 Ubuntu and MSYS.
MSYS is required for the flashing tools.

If you intend to use WSL and MSYS then you will need to set `MSYS_PREFIX` is set in `Makefile.conf` so that WSL can invoke relevant MSYS binaries (should be the UNIX style path to MSYS _from_ WSL, not the Windows path to MSYS).

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
make all -j $(nproc)
```

## Example
```
cd example && make blink-mega65r3.cor
```

```
cd example && FLASH_PORT=COM4 make jtag-flash-blink-mega65r3
```
