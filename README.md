# Verilog IPs Core for Vivado

[![Build Status](https://github.com/lgili/xilinx-ip-repo/workflows/ips%20Tests/badge.svg?branch=master)](https://github.com/lgili/xilinx-ip-repo/actions/)



GitHub repository: https://github.com/lgili/xilinx-ip-repo

## Introduction

This is a basic AXIs IP core, written in Verilog with cocotb
testbenches.

## Documentation

### To build a IP

 First you need to export the vivado sources
```console
$ source /tools/Xilinx/Vivado/2021.1/settings64.sh
```

After you can enter in the IP folder and do Make
```console
$ make
```
Then you need to add this folter to yours IP repository on Vivado.



<!---

### Source Files

    rtl/uart.v     : Wrapper for complete UART
    rtl/uart_rx.v  : UART receiver implementation
    rtl/uart_tx.v  : UART transmitter implementation

### AXI Stream Interface Example

two byte transfer with sink pause after each byte

              __    __    __    __    __    __    __    __    __
    clk    __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                    _____ _________________
    tdata  XXXXXXXXX_D0__X_D1______________XXXXXXXXXXXXXXXXXXXXXXXX
                    _______________________
    tvalid ________/                       \_______________________
           ______________             _____             ___________
    tready               \___________/     \___________/


## Testing

Running the included testbenches requires [cocotb](https://github.com/cocotb/cocotb), [cocotbext-axi](https://github.com/alexforencich/cocotbext-axi), and [Icarus Verilog](http://iverilog.icarus.com/).  The testbenches can be run with pytest directly (requires [cocotb-test](https://github.com/themperek/cocotb-test)), pytest via tox, or via cocotb makefiles.

-->
