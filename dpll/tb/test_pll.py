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

import matplotlib.pyplot as plt 


class TB:
    def __init__(self, dut):
        self.dut = dut
        self.signal_a = []
        self.signal_b = []
        self.signal_c = []

        self.getbit = [2048,1024,512,256,128,64,32,16,8,4,2,1]

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.cocotb.start_soon(Clock(dut.i_clk, 10,units="ns").start())  
           
        
                
    
    async def reset(self):
        self.dut.i_rstn.setimmediatevalue(0)
        self.dut.phase_a.setimmediatevalue(0)
        self.dut.phase_b.setimmediatevalue(0)
        self.dut.phase_c.setimmediatevalue(0)

        self.dut.i_ld.setimmediatevalue(0) 
        self.dut.i_step.setimmediatevalue(1)  
        self.dut.i_lgcoeff.setimmediatevalue(11)   
        #self.dut.m_axis_tready.setimmediatevalue(0)
        # self.dut.EnableSampleGeneration.setimmediatevalue(0)
        await RisingEdge(self.dut.i_clk)
        await RisingEdge(self.dut.i_clk)
        self.dut.i_rstn.value = 0
        await RisingEdge(self.dut.i_clk)
        await RisingEdge(self.dut.i_clk)
        self.dut.i_ce.value = 1  
        self.dut.i_rstn.value = 1  
        #self.dut.m_axis_tready.value = 1    
        await RisingEdge(self.dut.i_clk)
        await RisingEdge(self.dut.i_clk)
        
   
    async def write_sig_a_thead(self, signal):        
        for i in range(len(signal)):         
            data = int(signal[i])  
            await FallingEdge(self.dut.i_clk)       
            self.dut.phase_a.value  = data

    async def write_sig_b_thead(self, signal):        
        for i in range(len(signal)):         
            data = int(signal[i])  
            await FallingEdge(self.dut.i_clk)       
            self.dut.phase_b.value  = data

    async def write_sig_c_thead(self, signal):        
        for i in range(len(signal)):         
            data = int(signal[i])  
            await FallingEdge(self.dut.i_clk)       
            self.dut.phase_c.value  = data            

    def toSigned32(self, n):
        n = n & 0xffffffff
        return n | (-(n & (1<<31))) 

    def toSigned8(self, n):
        n = n & 0xff
        return n | (-(n & (1<<7)))
    
    def toSigned16(self, n):
        n = n & 0xffff
        return n | (-(n & (1<<15)))
     
    def generateSin(self, freq, time, amp,  sample_rate, random, random_range, channel):
        samples = np.arange(0, time, 1/sample_rate) 
        noise = 0
        if random == 1:
              noise = np.random.randint(random_range, size=(len(samples)))  
        if channel == 0:      
            self.signal_a = amp/2 * np.sin(2 * np.pi * freq * samples)  + amp/2  + noise
            self.signal_a = np.int16(self.signal_a)
        elif channel == 1:
            self.signal_b = amp/2 * np.sin(2 * np.pi * freq * samples - (2*np.pi/3))  + amp/2 + noise
            self.signal_b = np.int16(self.signal_b)  
        elif channel == 2:
            self.signal_c = amp/2 * np.sin(2 * np.pi * freq * samples + (2*np.pi/3)) + amp/2  + noise
            self.signal_c = np.int16(self.signal_c)        
        
   
async def run_test(dut):

    tb = TB(dut)

    #id_count = 2**len(tb.source.bus.tid)

    cur_id = 1

    for i in range(3):
        tb.generateSin(0.06,100,3500,1e3,1,500,i)

    #plt.plot(tb.signal_a)
    #plt.plot(tb.signal_b)
    #plt.show() 
    await tb.reset()


    #await tb.write(20,12)

    # Run reset_dut concurrently
    write_thread_0 = cocotb.start_soon(tb.write_sig_a_thead(tb.signal_a))
    write_thread_1 = cocotb.start_soon(tb.write_sig_b_thead(tb.signal_b))
    write_thread_2 = cocotb.start_soon(tb.write_sig_c_thead(tb.signal_c))

       
    assert 1 == 1   
    # await RisingEdge(dut.CLK100MHz)
    # await RisingEdge(dut.CLK100MHz)

    # Wait for the other thread to complete
    await write_thread_0
    await write_thread_1
    await write_thread_2

 



if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))
pll_dir = os.path.abspath(os.path.join(hdl_dir, '..',  'pll'))


@pytest.mark.parametrize("data_width", [12])
def test_pll(request, data_width):
    dut = "pll"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),
        #os.path.join(hdl_dir, "pi_controller.v"),
        #os.path.join(pll_dir, "fd.v"),
        #os.path.join(pll_dir, "lp.v"),
        #os.path.join(pll_dir, "pd.v"),
        #os.path.join(pll_dir, "vcodiv.v"),
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
