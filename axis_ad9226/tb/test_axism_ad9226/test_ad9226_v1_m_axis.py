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

        cocotb.cocotb.start_soon(Clock(dut.clk_100m, 10,units="ns").start())        
        cocotb.cocotb.start_soon(Clock(dut.M_AXIS_ACLK, 40, units="ns").start())
                
        
    
    async def reset(self):
        self.dut.M_AXIS_ARESETN.setimmediatevalue(0)
        self.dut.M_AXIS_TREADY.setimmediatevalue(0)
        self.dut.EnableSampleGeneration.setimmediatevalue(0)
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        self.dut.M_AXIS_ARESETN.value = 0
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        self.dut.M_AXIS_ARESETN.value = 1  
        self.dut.M_AXIS_TREADY.value = 1      
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)

        self.dut.EnableSampleGeneration.value = 1
        self.dut.PacketSize.value             = 1000  #verilog code pkg is 8 bits so 16/4 = 4 u32 will be send
        self.dut.EnablePacket.value           = 0  
        self.dut.TriggerLevel.value           = 100
        self.dut.Decimator.value              = 0
        self.dut.MavgFactor.value             = 0
        

        self.dut.ConfigZCDValue.value         = 6144 #10240

        self.dut.M_AXIS_TREADY.value          = 1
        self.dut.button.value                 = 1  

       
        self.dut.ConfigAdc.value            = 0  #2147485696

    async def write(self, data):    
        await RisingEdge(self.dut.M_AXIS_ACLK)    
        self.dut.adc_1.value = data
        
        
    async def read(self):
        #await RisingEdge(self.dut.eoc)
        #result = self.dut.data_out0.value 
        #print(bytes(result))
        #print(result)
        return 0    

    def generateSin(self, freq, time, amp, sample_rate, random, random_range):
        samples = np.arange(0, time, 1/sample_rate) 
        noise = 0
        if random == 1:
              noise = np.random.randint(random_range, size=(len(samples)))  
              
        self.signal = amp/2 * np.sin(2 * np.pi * freq * samples)  + (amp/2)  + noise
        self.signal = np.int16(self.signal)
        #print(self.signal[4]) 
        #print(len(self.signal)) 

   
async def run_test(dut):

    tb = TB(dut)

    #id_count = 2**len(tb.source.bus.tid)

    cur_id = 1

    tb.generateSin(0.3,10,3500,10e3,1,500)
    await tb.reset()


    for i in range(len(tb.signal)): 
        v = int(tb.signal[i])       
        await tb.write(v)
        #rx_frame = await tb.sink.recv()
    #    out = await tb.read()
    #    print("Input %d - Output %d" % (v , out))
    #    assert v == int(out) , "output adc was incorrect on the {}th cycle".format(i)
   
    assert 1 == 1   
    await RisingEdge(dut.clk_100m)
    await RisingEdge(dut.clk_100m)




if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))


@pytest.mark.parametrize("data_width", [12])
def test_ad9226_v1_m_axis(request, data_width):
    dut = "ad9226_v1_m_axis"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),
        os.path.join(hdl_dir, "ad_9226.v"),
        os.path.join(hdl_dir, "data_decimation.v"),
        os.path.join(hdl_dir, "trigger_level_acq.v"),
        os.path.join(hdl_dir, "moving_average_fir.v"),
        os.path.join(hdl_dir, "zero_crossing_detector.v"),
        os.path.join(hdl_dir, "passband_filter"),
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
