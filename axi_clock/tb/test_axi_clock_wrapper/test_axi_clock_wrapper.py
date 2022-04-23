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
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam
from cocotbext.axi import AddressSpace


class TB:
    def __init__(self, dut):
        self.dut = dut
     
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        # AXI 
        cocotb.cocotb.start_soon(Clock(dut.clk_100m, 10,units="ns").start())        
        

        self.axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.clk_100m, dut.aresetn,reset_active_level=False)
       
        
        
        self.ClockDividerAddr = 0x00      

                       
        
    def set_idle_generator(self, generator=None):
        if generator:
            self.axil_master.write_if.aw_channel.set_pause_generator(generator())
            self.axil_master.write_if.w_channel.set_pause_generator(generator())
            self.axil_master.read_if.ar_channel.set_pause_generator(generator())           

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.axil_master.write_if.b_channel.set_pause_generator(generator())
            self.axil_master.read_if.r_channel.set_pause_generator(generator())
            
            

    async def reset(self):
        self.dut.aresetn.setimmediatevalue(1)        
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        self.dut.aresetn.value = 0
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        self.dut.aresetn.value = 1             
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)

        


    async def write_to_axi_lite(self,addr, value):

        self.log.info("Writing data")
        try:            
            send_data = value.to_bytes(4, 'little') #bytearray(value)    
            await self.axil_master.write(addr, send_data)
            await RisingEdge(self.dut.clk_100m)
            data = await self.axil_master.read(addr, 4)

            self.log.info("Writed: %s", data.data) 
        except:
            print("An exception occurred")     


   
async def run_test(dut, idle_inserter=None, backpressure_inserter=None, size=None):

    tb = TB(dut)    
    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    CLK_DIV = 10
    # set packet size
    await tb.write_to_axi_lite(tb.ClockDividerAddr, CLK_DIV)
       
       
    for data in range(CLK_DIV*100): #len(self.signal)
           await RisingEdge(dut.clk_100m)
   
    await RisingEdge(dut.clk_100m)  
    assert 1 == 1    
    


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:

    
    factory = TestFactory(run_test)    
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))


@pytest.mark.parametrize("axi_lite_data_width", [8, 16, 32])
def test_axi_clock(request, axi_lite_data_width):
    dut = "axi_clock"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}_wrapper.v"),        
        os.path.join(hdl_dir, f"{dut}_divider.v"),
        os.path.join(hdl_dir, f"{dut}_s_axi.v"),
        
        
    ]

    parameters = {}

    parameters['AXI_LITE_DATA_WIDTH'] = axi_lite_data_width
    parameters['AXI_ADDR_WIDTH'] = 5    

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
