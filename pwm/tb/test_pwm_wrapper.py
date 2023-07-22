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
# https://pypi.org/project/svreal/ to use hard_float
# need cocotb 1v8
import itertools
import logging
import os
import numpy as np
import bitstring, random , struct,codecs

import pytest
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.regression import TestFactory

import matplotlib.pyplot as plt 
from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam

class TB:
    def __init__(self, dut):
        self.dut = dut
        
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.ERROR)

        cocotb.cocotb.start_soon(Clock(dut.CLK100MHz, 10,units="ns").start())   
        

    def set_backpressure_generator(self, generator=None):
            if generator:
                self.sink.set_pause_generator(generator())

    async def reset(self):
        self.dut.ARESETN.setimmediatevalue(0)
        self.dut.duty.setimmediatevalue(0)
                     
        
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)
        self.dut.ARESETN.value = 0
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)
    
        # self.dut.num_of_words.value = 16
        for i in range(100): 
            await RisingEdge(self.dut.CLK100MHz)
        
        self.dut.ARESETN.value = 1  


    def config_pwm(self, duty):
        self.dut.duty.value = duty
        

    async def await_thread(self):
        clk_to_await = 10000*50
        for i in range(clk_to_await):
            await RisingEdge(self.dut.CLK100MHz)
       




    
 
     
        


async def run_test(dut, backpressure_inserter=None):

    tb = TB(dut)

    
    # plt.plot(tb.signal_a)
    # plt.plot(tb.signal_b)
    # plt.show() 
    await tb.reset()
    tb.set_backpressure_generator(backpressure_inserter)
    
    tb.config_pwm(2048)


    # Run reset_dut concurrently
    write_thread_0 = cocotb.start_soon(tb.await_thread())
    assert 1 == 1   
    await RisingEdge(dut.CLK100MHz)
    await RisingEdge(dut.CLK100MHz)


    await write_thread_0
    # await read_thread_1
    # await read_thread_2

    # plt.plot(tb.data[0])
    # plt.plot(tb.data[1])
    # plt.show() 
 

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    # factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '../',  'hdl'))

@pytest.mark.parametrize("data_width", [12, 8, 16, 32])
def test_pwm_wrapper(request, data_width):
    dut = "pwm_wrapper"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.sv"),
        os.path.join(hdl_dir, "clock_divider.sv"),  
        os.path.join(hdl_dir, "dff.v"),      
    ]

    parameters = {}

    parameters['PWM_CLK_DIV'] = 1 
    parameters['DW'] = data_width

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
