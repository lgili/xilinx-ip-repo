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
        #self.signal = []

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        #self.log.setLevel(logging.FATAL)

        # AXI
        #self.address_space = AddressSpace()
        #self.pool = self.address_space.create_pool(0, 0x8000_0000)

        cocotb.cocotb.start_soon(Clock(dut.clk_100m, 10,units="ns").start())        
        cocotb.cocotb.start_soon(Clock(dut.clk_adc, 40, units="ns").start())
        #cocotb.cocotb.start_soon(Clock(dut.clk_60hz, 16, units="ns").start())

        self.axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.clk_100m, dut.aresetn,reset_active_level=False)
        #self.address_space.register_region(self.axil_master, 0x10_0000_0000)
        #self.hw_regs = self.address_space.create_window(0x10_0000_0000, self.axil_master.size)

        #self.sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk_100m, dut.aresetn,reset_active_level=False)

        #tb.log.info("Packet: %s", pkt)

        self.totalTimeSimulation        = 0.005
        self.currentTime                = 0

        self.EnableSampleGenerationAddr = 0x00
        self.PacketSizeAddr             = 0x04
        self.PacketRate                 = 0x08
        self.ConfigAdcAddr              = 0x0C
        self.ConfigZCDValueAddr         = 0x10
        self.ConfigDecimatorAddr        = 0x14
        self.ConfigMavgFactorAddr       = 0x18
        self.ConfigResetAddr            = 0x20

                       
        
    def set_idle_generator(self, generator=None):
        if generator:
            self.axil_master.write_if.aw_channel.set_pause_generator(generator())
            self.axil_master.write_if.w_channel.set_pause_generator(generator())
            self.axil_master.read_if.ar_channel.set_pause_generator(generator())           

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.axil_master.write_if.b_channel.set_pause_generator(generator())
            self.axil_master.read_if.r_channel.set_pause_generator(generator())
            #self.sink.set_pause_generator(generator())
            

    async def reset(self):
        self.dut.aresetn.setimmediatevalue(1)
        
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        self.dut.aresetn.value = 0
        self.dut.s1_ad9226_data.value = 0
        self.dut.s2_ad9226_data.value = 0
        self.dut.s3_ad9226_data.value = 0
        for i in range(20):
            await RisingEdge(self.dut.clk_100m)
        
        self.dut.aresetn.value = 1  
        self.dut.m_axis_tready.value = 1      
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)

        self.dut.ext_trigger.value = 0
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        await RisingEdge(self.dut.clk_100m)
        self.dut.ext_trigger.value = 1

        
    async def loggingTime(self):
        
        while(1):
            for i in range(10000): 
                await RisingEdge(self.dut.clk_100m)
            self.log.info("is runnig")  
            self.currentTime += (10000*(1/100e6))

            if(self.currentTime == 40000*(1/100e6)):
                await self.write_to_axi_lite(self.ConfigResetAddr, 1)
                await self.write_to_axi_lite(self.ConfigResetAddr, 0)

            if(self.currentTime == 50000*(1/100e6)):
                self.dut.ext_trigger.value = 0
                await RisingEdge(self.dut.clk_100m)
                self.dut.ext_trigger.value = 1


            if(self.currentTime > self.totalTimeSimulation):
                break

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

    async def gen_adc_input_thead(self):
        for i in range(len(self.signal)): 
            v = int(self.signal[i])       
            await self.write(v)
            

    async def write(self, data):    
        await RisingEdge(self.dut.clk_adc)    
        self.dut.s1_ad9226_data.value = data
        self.dut.s2_ad9226_data.value = data
        self.dut.s3_ad9226_data.value = data
        
        
    async def read_m_axis_thead(self):
        for data in range(2): #len(self.signal)
            self.rx_frame = await self.sink.read()          


    def generateSin(self, freq, time, amp, sample_rate, random, random_range):
        samples = np.arange(0, time, 1/sample_rate) 
        noise = 0
        if random == 1:
              noise = np.random.randint(random_range, size=(len(samples)))  
              
        self.signal = amp/2 * np.sin(2 * np.pi * freq * samples)  + (amp/2)  + noise
        self.signal = np.int16(self.signal)
        #print(self.signal[4]) 
        #print(len(self.signal))  


   
async def run_test(dut, idle_inserter=None, backpressure_inserter=None, size=None):

    tb = TB(dut)
    
    realCLk = 100e6
    fakeClk = 100e3
    dife = realCLk/fakeClk
    tb.generateSin(6000,0.005,3500,25e6,1,500)
    await tb.reset()

    
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)


    # set packet size
    await tb.write_to_axi_lite(tb.PacketSizeAddr, 100)

    # set adc config
    await RisingEdge(dut.clk_100m)
    useSigned = 0
    if(useSigned):
        val = 1 << 31
        val |= 2048
        tb.log.info("Adc config %d", val)
        await tb.write_to_axi_lite(tb.ConfigAdcAddr, val)
    else:
        await tb.write_to_axi_lite(tb.ConfigAdcAddr, 0)  


    # set Decimator     
    await tb.write_to_axi_lite(tb.ConfigDecimatorAddr, 0)

    #set MavgFactor
    await tb.write_to_axi_lite(tb.ConfigMavgFactorAddr, 15)

    #set Zero Crossing
    zcv = 3 << 12  # number os cycles to save
    zcv |= 3 << 20 # jump saved
    zcv |= 1 << 28 # timer ou zero cross detection to trigger
    zcv |= 0       # value to compare
    await tb.write_to_axi_lite(tb.ConfigZCDValueAddr, zcv)   

    # set enable
    await RisingEdge(dut.clk_100m)
    await RisingEdge(dut.clk_100m)
    await tb.write_to_axi_lite(tb.EnableSampleGenerationAddr, 1)    

    write_thread_a = cocotb.start_soon(tb.gen_adc_input_thead())
    time_tread_b = cocotb.start_soon(tb.loggingTime())

    #read_thread_b = cocotb.start_soon(tb.read_m_axis_thead())
   
    assert 1 == 1   
    await RisingEdge(dut.clk_100m)
    await RisingEdge(dut.clk_100m)

     # Wait for the other thread to complete
    await write_thread_a
    await time_tread_b

    #result = await tb.sink.read(100)
    #tb.log("values from m_axis %d", result)

    
    #await read_thread_b


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])
    #return itertools.cycle([1])

if cocotb.SIM_NAME:

    data_width = len(cocotb.top.s_axi_wdata)
    byte_lanes = data_width // 8
    max_burst_size = (byte_lanes-1).bit_length()

    factory = TestFactory(run_test)    
    #factory.add_option("idle_inserter", [None, cycle_pause])
    #factory.add_option("backpressure_inserter", [None, cycle_pause])    
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
        os.path.join(hdl_dir, "ad9226_v1_m_axis.v"),
       
        os.path.join(hdl_dir, "ad9226_v1_s_axi.v"),
        os.path.join(hdl_dir, "ad_9226.v"),
        os.path.join(hdl_dir, "data_decimation.v"),
        os.path.join(hdl_dir, "trigger_level_acq.v"),
        os.path.join(hdl_dir, "moving_average_fir.v"),
        os.path.join(hdl_dir, "zero_crossing_detector.v"),
        os.path.join(hdl_dir, "passband_filter.v"),
        os.path.join(hdl_dir, "passband_iir.v"),
        os.path.join(hdl_dir, "skidbuffer.v"),

        os.path.join(hdl_dir, "integrator.v"),
        os.path.join(hdl_dir, "comb.sv"),
        os.path.join(hdl_dir, "cic_d.v"),
        os.path.join(hdl_dir, "downsampler.v"),
        os.path.join(hdl_dir, "ad9226_if.v"),

        os.path.join(hdl_dir, "fifo.v"),
        os.path.join(hdl_dir, "display.v"),
        
        
        
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
