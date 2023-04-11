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
from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam
from cocotbext.axi import AddressSpace

class TB:
    def __init__(self, dut):
        self.dut = dut
        self.data_size_to_read = 0

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.cocotb.start_soon(Clock(dut.s00_axi_aclk, 10,units="ns").start())  
        cocotb.cocotb.start_soon(Clock(dut.m00_axis_aclk, 10,units="ns").start())    

        self.axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s00_axi"), dut.s00_axi_aclk, dut.s00_axi_aresetn,reset_active_level=False)
        self.sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m00_axis"), dut.m00_axis_aclk, dut.m00_axis_aresetn,reset_active_level=False)   
        
        self.enable                         = 0x00	
        self.num_of_words_reg			    = 0x04
         
        
    
    async def reset(self):
        self.dut.s00_axi_aresetn.setimmediatevalue(0)
        self.dut.m00_axis_aresetn.setimmediatevalue(0)
        
        await RisingEdge(self.dut.m00_axis_aclk)
        await RisingEdge(self.dut.m00_axis_aclk)
        self.dut.s00_axi_aresetn.value = 0
        self.dut.m00_axis_aresetn.value = 0
        await RisingEdge(self.dut.m00_axis_aclk)
        await RisingEdge(self.dut.m00_axis_aclk)
        self.dut.s00_axi_aresetn.value = 1  
        self.dut.m00_axis_aresetn.value = 1
        #self.dut.m_axis_tready.value = 1      
        await RisingEdge(self.dut.m00_axis_aclk)
        await RisingEdge(self.dut.m00_axis_aclk)

        
        
        
        
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

        

    async def read_m_axis_thead(self, pkg_len, num_pkg):
        self.rx_frame = []
        
        for i in range(num_pkg):
            rx_data = bytearray()
            rx_data = await self.sink.read()      
            
            for i in range(pkg_len):
                d0 = rx_data[4*i]
                d1 = rx_data[4*i+1]
                d2 = rx_data[4*i+2]
                d3 = rx_data[4*i+3]
                data = [d0, d1, d2, d3]
                value = int.from_bytes(data, byteorder='little', signed=False) 
                self.rx_frame.append(value)
        

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

    
    await tb.reset()

    tb.data_size_to_read = 4095
    #await tb.write(20,12)
    await tb.write_to_axi_lite(tb.num_of_words_reg, tb.data_size_to_read)
    await tb.write_to_axi_lite(tb.enable, 1)

    # Run reset_dut concurrently
    read_thread_0 = cocotb.start_soon(tb.read_m_axis_thead(tb.data_size_to_read, 2))
    
    
    #write_angle_thread = cocotb.start_soon(tb.write_angle())
       
    assert 1 == 1   
    await RisingEdge(dut.m00_axis_aclk)
    await RisingEdge(dut.m00_axis_aclk)

    # Wait for the other thread to complete
    await read_thread_0

    print(tb.rx_frame)




if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))
pll_dir = os.path.abspath(os.path.join(hdl_dir, '..',  'pll'))


@pytest.mark.parametrize("data_width", [12])
def test_ad7276_wrapper(request, data_width):
    dut = "ad7276_wrapper"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.sv"),
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
