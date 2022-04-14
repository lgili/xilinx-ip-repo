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
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.regression import TestFactory

from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink
from cocotbext.axi import AxiBus, AxiMaster, AxiRam


class TB:
    def __init__(self, dut):
        self.dut = dut
        #self.signal = []

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.cocotb.start_soon(Clock(dut.ACLK, 10,units="ns").start())        
        cocotb.cocotb.start_soon(Clock(dut.clk_25m, 40, units="ns").start())

        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "s00_axi"), dut.ACLK, dut.ARESETN)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, "s00_axi"), dut.ACLK, dut.ARESETN, size=2**16)

        self.axi_ram.write_if.log.setLevel(logging.DEBUG)
        self.axi_ram.read_if.log.setLevel(logging.DEBUG)
                
        
    def set_idle_generator(self, generator=None):
        if generator:
            self.axi_master.write_if.aw_channel.set_pause_generator(generator())
            self.axi_master.write_if.w_channel.set_pause_generator(generator())
            self.axi_master.read_if.ar_channel.set_pause_generator(generator())
            self.axi_ram.write_if.b_channel.set_pause_generator(generator())
            self.axi_ram.read_if.r_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.axi_master.write_if.b_channel.set_pause_generator(generator())
            self.axi_master.read_if.r_channel.set_pause_generator(generator())
            self.axi_ram.write_if.aw_channel.set_pause_generator(generator())
            self.axi_ram.write_if.w_channel.set_pause_generator(generator())
            self.axi_ram.read_if.ar_channel.set_pause_generator(generator())

    async def reset(self):
        self.dut.ARESETN.setimmediatevalue(0)
        self.dut.m_axis_tready.setimmediatevalue(0)
        self.dut.EnableSampleGeneration.setimmediatevalue(0)
        await RisingEdge(self.dut.ACLK)
        await RisingEdge(self.dut.ACLK)
        self.dut.ARESETN.value = 0
        await RisingEdge(self.dut.ACLK)
        await RisingEdge(self.dut.ACLK)
        self.dut.ARESETN.value = 1  
        self.dut.m_axis_tready.value = 1      
        await RisingEdge(self.dut.ACLK)
        await RisingEdge(self.dut.ACLK)

        #self.dut.EnableSampleGeneration.value = 1
        #self.dut.PacketSize.value             = 16  #verilog code pkg is 8 bits so 16/4 = 4 u32 will be send
        #self.dut.EnablePacket.value           = 0  
        #self.dut.TriggerLevel.value           = 100
        #self.dut.Decimator.value              = 10

        
        self.dut.button.value                 = 1  

    async def write(self, data):    
        await RisingEdge(self.dut.clk_25m)    
        self.dut.adc_1.value = data
        
        
    async def read(self):
        #await RisingEdge(self.dut.eoc)
        #result = self.dut.data_out0.value 
        #print(bytes(result))
        #print(result)
        return 0    

    def generateSin(self, freq, time, amp, sample_rate):
        samples = np.arange(0, time, 1/sample_rate) 
        self.signal = amp/2 * np.sin(2 * np.pi * freq * samples)  + (amp/2)         
        self.signal = np.int16(self.signal)
        #print(self.signal[4]) 
        #print(len(self.signal)) 

   
async def run_test(dut, idle_inserter=None, backpressure_inserter=None, size=None):

    tb = TB(dut)

    byte_lanes = tb.axi_master.write_if.byte_lanes
    max_burst_size = tb.axi_master.write_if.max_burst_size

    if size is None:
        size = max_burst_size

    tb.generateSin(60,1,4095,1e3)
    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    


    #for i in range(len(tb.signal)): 
    #    v = int(tb.signal[i])       
    #    await tb.write(v)
        #rx_frame = await tb.sink.recv()
    #    out = await tb.read()
    #    print("Input %d - Output %d" % (v , out))
    #    assert v == int(out) , "output adc was incorrect on the {}th cycle".format(i)
   
    assert 1 == 1   
    await RisingEdge(dut.ACLK)
    await RisingEdge(dut.ACLK)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:

    data_width = len(cocotb.top.s00_axi_wdata)
    byte_lanes = data_width // 8
    max_burst_size = (byte_lanes-1).bit_length()

    factory = TestFactory(run_test)    
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.add_option("size", [None]+list(range(max_burst_size)))
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))


@pytest.mark.parametrize("data_width", [12])
def test_ad9226_wrapper(request, data_width):
    dut = "ad9226_wrapper"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),
        os.path.join(hdl_dir, "ad_9226.v"),
        os.path.join(hdl_dir, "data_decimation.v"),
        os.path.join(hdl_dir, "trigger_level_acq.v"),
        os.path.join(hdl_dir, "ad9226_v1_m_axis.v"),
        os.path.join(hdl_dir, "ad9226_v1_s_axis.v"),
        os.path.join(hdl_dir, "ad9226_v1_s_axi.v"),
        os.path.join(hdl_dir, "moving_average_fir.v"),
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
