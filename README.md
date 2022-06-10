# Building

### Missing dependencies (Ubuntu only)
```
sudo make install_dependencies
```

### Tools
```
make submodules && make all -j $(nproc)
```

### Example
```
cd example && make blink.mega65r3.cor
```

# Somewhat Common Issues:

* If you get `nextpnr-xilinx: error while loading shared libraries: libQt5Core.so.5: cannot open shared object file: No such file or directory` try running `sudo strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5` (https://askubuntu.com/questions/1034313/ubuntu-18-4-libqt5core-so-5-cannot-open-shared-object-file-no-such-file-or-dir)

* If prjxray stops working after installing/updating amaranth, run `make force-prjxray` again
