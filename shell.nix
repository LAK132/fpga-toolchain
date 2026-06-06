with (import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.11.tar.gz") {});

mkShell {
	packages = [
		git
		clang
		bison
		flex
		gawk
		tcl
		libffi
		graphviz
		xdot
		pkg-config
		gcc_multi
		libusb1
		gnat
		cmake
		(python311.withPackages (ps: with ps; [ pip ]))
		eigen
		ccache
		dfu-util
		libftdi
		libftdi1
		libudev-zero
		zlib
		zlib.dev
		readline
		readline.dev
		boost188
		boost188.dev
	];

	shellHook = ''
		export PYTHON3=python3.11
		unset SOURCE_DATE_EPOCH
	'';
}
