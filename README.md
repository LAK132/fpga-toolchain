# Building

### Missing dependencies (Ubuntu only)
```
sudo make install_dependencies
```

### Tools
```
make all -j $(nproc)
```

### Example
```
cd example && make blink-mega65r3.cor
```

```
cd example && FLASH_PORT=COM4 make jtag-flash-blink-mega65r3
```
