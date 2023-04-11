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

        cocotb.cocotb.start_soon(Clock(dut.CLK100MHz, 10,units="ns").start())  
        # cocotb.cocotb.start_soon(Clock(dut.clk_adc, 60,units="ns").start())       
        
        self.EnableSampleGeneration = 0x00	
        self.PacketSize			    = 0x04
        self.EnablePacket		    = 0x08
        self.configPassband         = 0x0C
        self.DMABaseAddr            = 0x10
        self.TriggerLevel           = 0x14
        self.ConfigSampler          = 0x18
        self.DataFromArm            = 0x1C
        self.Decimator              = 0x20
        self.MavgFactor             = 0x24
        self.TriggerEnable          = 0x28
        self.TriggerOffset          = 0x2C  
        
    
    async def reset(self):
        self.dut.ARESETN.setimmediatevalue(0)
        self.dut.inData.setimmediatevalue(0)
        #self.dut.m_axis_tready.setimmediatevalue(0)
        # self.dut.EnableSampleGeneration.setimmediatevalue(0)
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)
        self.dut.ARESETN.value = 0
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)
        self.dut.ARESETN.value = 1  
        #self.dut.m_axis_tready.value = 1      
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)

        # self.dut.EnableSampleGeneration.value = 1
        # self.dut.PacketSize.value             = 100  #verilog code pkg is 8 bits so 16/4 = 4 u32 will be send
        # self.dut.EnablePacket.value           = 0  
        # self.dut.TriggerLevel.value           = 100
        # self.dut.Decimator.value              = 10
        # self.dut.MavgFactor.value             = 10
        await self.write_to_axi_lite(self.EnableSampleGeneration, 1)
        # await self.write_to_axi_lite(self.PacketSize, 100)
        # await self.write_to_axi_lite(self.EnablePacket, 0)
        # await self.write_to_axi_lite(self.Decimator, 0)
        # await self.write_to_axi_lite(self.MavgFactor, 0)

        #self.dut.m_axis_tready.value          = 1
        
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

    async def write_sig_thead(self, signal, bit):        
        for i in range(len(signal)):         
            v = int(signal[i])       
            await self.write(v,12, bit)  

    async def write(self, data, size, n_adc): 
        
        await FallingEdge(self.dut.cs0)  
        await FallingEdge(self.dut.sclk0)
       
        self.dut.inData[n_adc].value  = 0

        
        if(self.dut.cs[0].value == 0):
            
            for i in range(size): 
                value = data
                value >>= (size+1-i)
                await RisingEdge(self.dut.sclk0) 
                
                self.dut.inData[n_adc].value        = value & 1
                #data <<= 1  
               
            
        await FallingEdge(self.dut.sclk0)        
        self.dut.inData[n_adc].value  = 0
        await FallingEdge(self.dut.sclk0)       
        self.dut.inData[n_adc].value  = 0
    

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
    write_thread_0 = cocotb.start_soon(tb.write_sig_thead(tb.signal_a , 0))
    write_thread_1 = cocotb.start_soon(tb.write_sig_thead(tb.signal_b , 1))
    write_thread_2 = cocotb.start_soon(tb.write_sig_thead(tb.signal_a , 2))
    write_thread_3 = cocotb.start_soon(tb.write_sig_thead(tb.signal_b , 3))
    write_thread_4 = cocotb.start_soon(tb.write_sig_thead(tb.signal_a , 4))
    write_thread_5 = cocotb.start_soon(tb.write_sig_thead(tb.signal_b , 5))
    write_thread_6 = cocotb.start_soon(tb.write_sig_thead(tb.signal_a , 6))
    write_thread_7 = cocotb.start_soon(tb.write_sig_thead(tb.signal_b , 7))
    write_thread_8 = cocotb.start_soon(tb.write_sig_thead(tb.signal_a , 8))
    write_thread_9 = cocotb.start_soon(tb.write_sig_thead(tb.signal_b , 9))
    write_thread_10 = cocotb.start_soon(tb.write_sig_thead(tb.signal_a , 10))
    write_thread_11 = cocotb.start_soon(tb.write_sig_thead(tb.signal_b , 11))
    write_thread_12 = cocotb.start_soon(tb.write_sig_thead(tb.signal_a , 12))
    write_thread_13 = cocotb.start_soon(tb.write_sig_thead(tb.signal_b , 13))
    write_thread_14 = cocotb.start_soon(tb.write_sig_thead(tb.signal_a , 14))
    write_thread_15 = cocotb.start_soon(tb.write_sig_thead(tb.signal_b , 15))
    
    #write_angle_thread = cocotb.start_soon(tb.write_angle())
       
    assert 1 == 1   
    await RisingEdge(dut.CLK100MHz)
    await RisingEdge(dut.CLK100MHz)

    # Wait for the other thread to complete
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
