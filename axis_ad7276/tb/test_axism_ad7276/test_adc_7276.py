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

        cocotb.cocotb.start_soon(Clock(dut.Clk_100m, 10,units="ns").start())        
        cocotb.cocotb.start_soon(Clock(dut.Clk_adc, 40, units="ns").start())
                
        
    
    async def reset(self):
        self.dut.Resetn.setimmediatevalue(0)
        self.dut.inData[0].setimmediatevalue(0)
        #self.dut.m_axis_tready.setimmediatevalue(0)
        self.dut.EnableSampleGeneration.setimmediatevalue(0)
        await RisingEdge(self.dut.Clk_100m)
        await RisingEdge(self.dut.Clk_100m)
        self.dut.Resetn.value = 0
        await RisingEdge(self.dut.Clk_100m)
        await RisingEdge(self.dut.Clk_100m)
        self.dut.Resetn.value = 1  
        #self.dut.m_axis_tready.value = 1      
        await RisingEdge(self.dut.Clk_100m)
        await RisingEdge(self.dut.Clk_100m)

        self.dut.EnableSampleGeneration.value = 1
        self.dut.PacketSize.value             = 100  #verilog code pkg is 8 bits so 16/4 = 4 u32 will be send
        self.dut.EnablePacket.value           = 0  
        self.dut.TriggerLevel.value           = 100
        self.dut.Decimator.value              = 10
        self.dut.MavgFactor.value             = 10

        #self.dut.m_axis_tready.value          = 1
        

    async def write_sig_a_thead(self):        
        for i in range(len(self.signal_a)):         
            v = int(self.signal_a[i])       
            await self.write(v,12, 0)

    async def write_sig_b_thead(self):        
        for i in range(len(self.signal_b)):         
            v = int(self.signal_b[i])       
            await self.write(v,12,1)        

    async def write(self, data, size, input_bit): 
        
        await FallingEdge(self.dut.cs)  
        await FallingEdge(self.dut.Clk_adc)
        self.dut.inData[input_bit].value  = 0

        
        if(self.dut.cs.value == 0):
            
            for i in range(size): 
                value = data
                value >>= (size+1-i)
                await RisingEdge(self.dut.Clk_adc) 
                self.dut.inData[input_bit].value        = value & 1
                #data <<= 1  
               
            
        await FallingEdge(self.dut.Clk_adc)
        self.dut.inData[input_bit].value        = 0
        await FallingEdge(self.dut.Clk_adc)
        self.dut.inData[input_bit].value        = 0
    
    
    async def write_angle(self):
        j = 0
        for i in range(len(self.signal_a)):
            await RisingEdge(self.dut.cs)            
            self.dut.angle.value = int(((1 << 32)*j)/360)
            j= j+1
            if j == 359:
                j = 0

    async def read(self):
        #await RisingEdge(self.dut.eoc)
        #result = self.dut.data_out0.value 
        #print(bytes(result))
        #print(result)
        return 0    

    def generateSin(self, freq, time, amp,  sample_rate, random, random_range, channel):
        samples = np.arange(0, time, 1/sample_rate) 
        noise = 0
        if random == 1:
              noise = np.random.randint(random_range, size=(len(samples)))  
        if channel == 0:      
            self.signal_a = amp/2 * np.sin(2 * np.pi * freq * samples)  + (amp/2)  + noise
            self.signal_a = np.int16(self.signal_a)
        elif channel == 1:
            self.signal_b = amp/2 * np.sin(2 * np.pi * freq * samples - (2*np.pi/3))  + (amp/2)  + noise
            self.signal_b = np.int16(self.signal_b)  
        elif channel == 2:
            self.signal_c = amp/2 * np.sin(2 * np.pi * freq * samples + (2*np.pi/3))  + (amp/2)  + noise
            self.signal_c = np.int16(self.signal_c)        
        
   
async def run_test(dut):

    tb = TB(dut)

    #id_count = 2**len(tb.source.bus.tid)

    cur_id = 1

    for i in range(2):
        tb.generateSin(0.6,10,3500,1e3,1,500,i)

    #plt.plot(tb.signal_a)
    #plt.plot(tb.signal_b)
    #plt.show() 
    await tb.reset()


    #await tb.write(20,12)

    # Run reset_dut concurrently
    write_thread_a = cocotb.start_soon(tb.write_sig_a_thead())
    write_thread_b = cocotb.start_soon(tb.write_sig_b_thead())
    
    #write_angle_thread = cocotb.start_soon(tb.write_angle())
       
    assert 1 == 1   
    await RisingEdge(dut.Clk_100m)
    await RisingEdge(dut.Clk_100m)

    # Wait for the other thread to complete
    await write_thread_a
    await write_thread_a
    #await write_angle_thread




if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))
pll_dir = os.path.abspath(os.path.join(hdl_dir, '..',  'pll'))


@pytest.mark.parametrize("data_width", [12])
def test_ad9226(request, data_width):
    dut = "adc_7276"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),
        os.path.join(hdl_dir, "ad7276_if.v"),
        os.path.join(hdl_dir, "data_decimation.v"),        
        os.path.join(hdl_dir, "moving_average_fir.v"),
        os.path.join(hdl_dir, "cordic.v"),
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
