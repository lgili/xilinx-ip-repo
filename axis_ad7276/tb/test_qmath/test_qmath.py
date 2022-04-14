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
from select import select
import numpy as np


import pytest
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.regression import TestFactory

import matplotlib.pyplot as plt 
from fxpmath import Fxp

class TB:
    def __init__(self, dut):
        self.dut = dut
               

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.cocotb.start_soon(Clock(dut.Clk, 10,units="ns").start())        
                        
        
    
    async def reset(self):
        self.dut.Resetn.setimmediatevalue(0)    
       
        
        await RisingEdge(self.dut.Clk)
        await RisingEdge(self.dut.Clk)
        self.dut.Resetn.value = 0
        await RisingEdge(self.dut.Clk)
        await RisingEdge(self.dut.Clk)
        self.dut.Resetn.value = 1  
        await RisingEdge(self.dut.Clk)
        await RisingEdge(self.dut.Clk)
        
               
    
    async def add(self, value_1, value_2):
        self.dut.sum_a.value = value_1
        self.dut.sum_b.value = value_2
        await RisingEdge(self.dut.Clk)
        return self.dut.result_sum.value

    


    async def write_sig_a_thead(self):        
        for i in range(len(self.signal_a)):         
            v = int(self.signal_a[i])       
            await self.write(v,12, 0)
   
    
    async def write_angle(self):
        j = 0
        for i in range(len(self.signal_a)):
            await RisingEdge(self.dut.cs)            
            self.dut.angle.value = int(((1 << 32)*j)/360)
            j= j+1
            if j == 359:
                j = 0
      

"""
x is the input fixed number which is of integer datatype
e is the number of fractional bits for example in Q1.15 e = 15
"""
def to_float(x,e):
    c = abs(x)
    sign = 1 
    if x < 0:
        # convert back from two's complement
        c = x - 1 
        c = ~c
        sign = -1
    f = (1.0 * c) / (2 ** e)
    f = f * sign
    return f
"""
f is the input floating point number 
e is the number of fractional bits in the Q format. 
    Example in Q1.15 format e = 15
"""
def to_fixed(f,e):
    a = f* (2**e)
    b = int(round(a))
    if a < 0:
        # next three lines turns b into it's 2's complement.
        b = abs(b)
        b = ~b
        b = b + 1
    return b           
   
async def run_test(dut):

    tb = TB(dut)

    #id_count = 2**len(tb.source.bus.tid)

    cur_id = 1

    #for i in range(2):
    #    tb.generateSin(0.6,10,3500,1e3,1,500,i)

    #plt.plot(tb.signal_a)
    #plt.plot(tb.signal_b)
    #plt.show() 
    await tb.reset()

    val_2 = 2.75
    val_1 = -1
    num_a = to_fixed(val_1,4)
    print(num_a)
    
    x = Fxp(val_1, True, 16, 4)      # signed=True, n_word=16, n_frac=8  
    
    print(x.hex())
    print(int(x.hex(),base=16))
    num_b = to_fixed(val_2,4)
    print(num_b)

    result_add = await tb.add(num_a,num_b)

    print(val_1+val_2)
    num_f = to_float(int(result_add),4)
    print(num_f)

    
    

    #await tb.write(20,12)

    # Run reset_dut concurrently
    #write_thread_a = cocotb.start_soon(tb.write_sig_a_thead())
    #write_thread_b = cocotb.start_soon(tb.write_sig_b_thead())
    
   
    assert 1 == 1   
    await RisingEdge(dut.Clk)
    await RisingEdge(dut.Clk)

    # Wait for the other thread to complete
    #await write_thread_a
    #await write_thread_a
    #await write_angle_thread




if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))
pll_dir = os.path.abspath(os.path.join(hdl_dir, '..',  'pll'))


@pytest.mark.parametrize("data_width", [16])
def test_qmath(request, data_width):
    dut = "qmath"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),
        os.path.join(hdl_dir, "qmult.v"),       
        os.path.join(hdl_dir, "qdiv.v"),
        os.path.join(hdl_dir, "qmults.v"),        
    ]

    parameters = {}

    parameters['DATA_WIDTH'] = data_width    
    parameters['FRACTIONAL_WIDTH'] = 10

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
