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

#from scapy.layers.l2 import Ether, ARP
#from scapy.utils import mac2str

import pytest
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.regression import TestFactory

from cocotbext.axi import AxiStreamBus, AxiStreamSource
from cocotbext.axi.stream import define_stream


class TB:
    def __init__(self, dut):
        self.dut = dut
        #self.signal = []

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
        cocotb.start_soon(Clock(dut.clk_sample, 40, units="ns").start())

        #self.header_source = EthHdrSource(EthHdrBus.from_prefix(dut, "s_eth"), dut.clk, dut.rst)
        #self.header_source = EthHdrSource(EthHdrBus.from_prefix(dut, "s_eth"), dut.clk, dut.rst)
        #self.payload_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_eth_payload_axis"), dut.clk, dut.rst)

        #self.sink = ArpHdrSink(ArpHdrBus.from_prefix(dut, "m"), dut.clk, dut.rst)

   # def set_idle_generator(self, generator=None):
    #    if generator:
    #        self.header_source.set_pause_generator(generator())
    #        self.payload_source.set_pause_generator(generator())

    #def set_backpressure_generator(self, generator=None):
    #    if generator:
    #        self.sink.set_pause_generator(generator())

    async def reset(self):
        self.dut.rst_n.setimmediatevalue(0)
        self.dut.ready.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst_n.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst_n.value = 1  
        self.dut.ready.value = 1      
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)

    async def write(self, data):    
        await RisingEdge(self.dut.clk_sample)    
        self.dut.data_in0.value = data
        
        
    async def read(self):
        await RisingEdge(self.dut.eoc)
        result = self.dut.data_out0.value 
        #print(bytes(result))
        #print(result)
        return result    

    def generateSin(self, freq, time, amp, sample_rate):
        samples = np.arange(0, time, 1/sample_rate) 
        self.signal = amp/2 * np.sin(2 * np.pi * freq * samples)  + (amp/2)         
        self.signal = np.int16(self.signal)
        #print(self.signal[4]) 
        #print(len(self.signal)) 

   
async def run_test(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)
    tb.generateSin(60,1,4095,1e3)
    await tb.reset()

    for i in range(len(tb.signal)): 
        v = int(tb.signal[i])       
        await tb.write(v)
        out = await tb.read()
        print("Input %d - Output %d" % (v , out))
        assert v == int(out) , "output adc was incorrect on the {}th cycle".format(i)
   
   
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)



if cocotb.SIM_NAME:

    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))
#lib_dir = os.path.abspath(os.path.join(rtl_dir, '..', 'lib'))
#axis_rtl_dir = os.path.abspath(os.path.join( 'axis', 'rtl'))


@pytest.mark.parametrize("data_width", [12])
def test_ad_9226(request, data_width):
    dut = "ad_9226"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),
    ]

    parameters = {}

    parameters['DATA_WIDTH'] = data_width    

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
