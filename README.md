To install any missing dependencies (Ubuntu only):
```
sudo make install_dependencies
```

To build tools:
```
make submodules && make all -j $(nproc)
```

To build example:
```
cd example && make bin/mega65r3.cor
```
