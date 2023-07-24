#!/usr/bin/env python
"""
Copyright (c) 2022 Luiz Carlos Gili
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

import itertools
import logging
import os
import numpy as np


import pytest
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.regression import TestFactory




class TB:
    def __init__(self, dut):
        self.dut = dut
        #self.signal = []

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.cocotb.start_soon(Clock(dut.CLK100MHz, 10,units="ns").start())        
        
        self.simulation_time = int(10)   
        self.serial_clk_div = 25    
        
    
    async def reset(self):
        self.dut.ARESETN.setimmediatevalue(0)
        self.dut.i_data.setimmediatevalue(0)
        
        self.dut.ARESETN.value = 0
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)
        self.dut.ARESETN.value = 1
    
    async def delay(self, clocks):
        for i in range(clocks):
            await RisingEdge(self.dut.CLK100MHz)
            
    async def write_clk(self):
        for j in range(self.simulation_time):
            for i in range(36):
                await self.delay(self.serial_clk_div)
                if i < 4:
                    self.dut.i_data[16].value = 1
                else:
                    self.dut.i_data[16].value = 0
        
    async def write_enable(self):
        for j in range(self.simulation_time):
            for i in range(36):
                await self.delay(self.serial_clk_div)
                if i < 34:
                    if (i % 2) == 0:
                        self.dut.i_data[17].value = 0
                    else:
                        self.dut.i_data[17].value = 1
                else:
                    self.dut.i_data[17].value = 0
               
    async def write(self, data, size, pos): 
        for j in range(self.simulation_time):
            # self.dut.i_data[pos].value  = 0
            await self.delay(self.serial_clk_div) 
            await self.delay(self.serial_clk_div)     
            print("====================================================")            
            for i in range(size+1): 
                value = data
                
                self.dut.i_data[pos].value        = data & 1 << i != 0
                print(self.dut.i_data[pos].value )
                await self.delay(self.serial_clk_div)
                await self.delay(self.serial_clk_div) 
            
               
            
        
        
    
   
async def run_test(dut):

    tb = TB(dut)
    
    await tb.reset()

    # for i in range(4095):
    #     await tb.write(i, 16)
    write_thread_0 = cocotb.start_soon(tb.write_clk())
    write_thread_1 = cocotb.start_soon(tb.write_enable())
    
    write_thread_2 = cocotb.start_soon(tb.write(1001,16,0))
    write_thread_3 = cocotb.start_soon(tb.write(1002,16,1))
    write_thread_4 = cocotb.start_soon(tb.write(1003,16,2))
    write_thread_5 = cocotb.start_soon(tb.write(1004,16,3))
    write_thread_6 = cocotb.start_soon(tb.write(1005,16,4))
    write_thread_7 = cocotb.start_soon(tb.write(1006,16,5))
    write_thread_8 = cocotb.start_soon(tb.write(1007,16,6))
    write_thread_9 = cocotb.start_soon(tb.write(1008,16,7))
    write_thread_10 = cocotb.start_soon(tb.write(1009,16,8))
    write_thread_11 = cocotb.start_soon(tb.write(1010,16,9))
    write_thread_12 = cocotb.start_soon(tb.write(1011,16,10))
    write_thread_13 = cocotb.start_soon(tb.write(1012,16,11))
    write_thread_14 = cocotb.start_soon(tb.write(1013,16,12))
    write_thread_15 = cocotb.start_soon(tb.write(1014,16,13))
    write_thread_16 = cocotb.start_soon(tb.write(1015,16,14))
    write_thread_17 = cocotb.start_soon(tb.write(1016,16,15))

    assert 1 == 1   
    await RisingEdge(dut.CLK100MHz)
    await RisingEdge(dut.CLK100MHz)


    await write_thread_0
    await write_thread_1
    await write_thread_2
    await write_thread_3
    await write_thread_4
    await write_thread_5
    await write_thread_6
    await write_thread_7
    await write_thread_8
    await write_thread_9
    await write_thread_10
    await write_thread_11
    await write_thread_12
    await write_thread_13
    await write_thread_14
    await write_thread_15
    await write_thread_16
    await write_thread_17


if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))


@pytest.mark.parametrize("data_width", [12])
def test_opal_com_wrapper(request, data_width):
    dut = "opal_com_wrapper"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),        
    ]

    parameters = {}

    parameters['ADC_DATA_WIDTH'] = data_width    

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env,
    )    
