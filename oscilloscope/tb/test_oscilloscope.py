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

from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam
from helpers.uart import UartSource, UartSink
import matplotlib.pyplot as plt 

class TB:
    def __init__(self, dut):
        self.dut = dut
        self.data_uart = []

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.cocotb.start_soon(Clock(dut.CLK100MHz, 100,units="ns").start())        
        cocotb.cocotb.start_soon(Clock(dut.CLKADC, 40, units="ns").start())
        cocotb.cocotb.start_soon(Clock(dut.clk_reading, 40, units="ns").start())

        self.axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.CLK100MHz, dut.rst_n,reset_active_level=False)
                
        self.uart_source = UartSource(dut.RxD, baud=115200, bits=8)
        self.uart_sink = UartSink(dut.TxD, baud=115200, bits=8)

        self.totalTimeSimulation        = 0.005
        self.currentTime                = 0

        self.TimeConfig     = 0x00
        self.TriggerConfig  = 0x04
        self.Channel1Config = 0x08
        self.Channel2Config = 0x0C
    
    async def reset(self):
        self.dut.rst_n.setimmediatevalue(0)
        self.dut.ch1_data.setimmediatevalue(0)
        self.dut.ch2_data.setimmediatevalue(0)
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)

        # self.dut.ch1_reset.value = 1
        # self.dut.ch2_reset.value = 1
        # self.dut.trig_reset.value  = 1
        # self.dut.time_reset.value  = 1
        for i in range(10):
            await RisingEdge(self.dut.CLKADC)

        self.dut.rst_n.value = 1
        # self.dut.ch1_reset.value = 0
        # self.dut.ch1_en.value = 1
        # self.dut.ch1_scale_in.value  = 0
        # self.dut.ch1_scale_out.value  = 1
        # self.dut.ch1_up.value  = 1
        # self.dut.ch1_down.value  = 0
        # self.dut.ch1_couple_sw.value   = 0

        # self.dut.ch2_reset.value = 0
        # self.dut.ch2_en.value = 1
        # self.dut.ch2_scale_in.value  = 0
        # self.dut.ch2_scale_out.value  = 1
        # self.dut.ch2_up.value  = 0
        # self.dut.ch2_down.value  = 1
        # self.dut.ch2_couple_sw.value   = 0

        # self.dut.trig_reset.value  = 0
        # self.dut.trig_up.value  = 1
        # self.dut.trig_down.value  = 0
        # self.dut.trig_off.value  = 0 # free running state

        # self.dut.time_reset.value  = 0
        # self.dut.time_scale_in.value  = 0
        # self.dut.time_scale_out.value  = 1
        # self.dut.time_left.value  = 0
        # self.dut.time_right.value  = 1

        # self.dut.en_read.value = 1


        # self.dut.ch1_offset.value = 0
        # self.dut.ch1_couple.value = 1
        
    def toSigned32(self, n):
        n = n & 0xffffffff
        return n | (-(n & (1<<31))) 

    def toSigned8(self, n):
        n = n & 0xff
        return n | (-(n & (1<<7))) 
       
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


    async def write_ch1_serial_thead(self):        
        for i in range(len(self.signal_a)):         
            v = int(self.signal_a[i])       
            await self.write2adc_ch1(v,12)
           

    async def write_ch2_serial_thead(self):        
        for i in range(len(self.signal_b)):         
            v = int(self.signal_b[i])       
            await self.write2adc_ch2(v,12)
           

    async def write2adc_ch1(self, data, size): 
        
        await FallingEdge(self.dut.cs_n)  
        await FallingEdge(self.dut.CLKADC)
        self.dut.ch1_data.value  = 0

        
        if(self.dut.cs_n.value == 0):
            
            for i in range(size): 
                value = data
                value >>= (size+1-i)
                await RisingEdge(self.dut.CLKADC) 
                self.dut.ch1_data.value        = value & 1
                #data <<= 1  
               
            
        await FallingEdge(self.dut.CLKADC)
        self.dut.ch1_data.value        = 0
        await FallingEdge(self.dut.CLKADC)
        self.dut.ch1_data.value        = 0 

    async def write2adc_ch2(self, data, size): 
        
        await FallingEdge(self.dut.cs_n)  
        await FallingEdge(self.dut.CLKADC)
        self.dut.ch2_data.value  = 0

        
        if(self.dut.cs_n.value == 0):
            
            for i in range(size): 
                value = data
                value >>= (size+1-i)
                await RisingEdge(self.dut.CLKADC) 
                self.dut.ch2_data.value        = value & 1
                #data <<= 1  
               
            
        await FallingEdge(self.dut.CLKADC)
        self.dut.ch2_data.value        = 0
        await FallingEdge(self.dut.CLKADC)
        self.dut.ch2_data.value        = 0     

        
    async def write_ch1_thead(self):        
        for i in range(len(self.signal_a)): 
            v = int(self.signal_a[i])       
            await self.write_ch1(v)

    async def write_ch2_thead(self):        
        for i in range(len(self.signal_b)): 
            v = int(self.signal_b[i])       
            await self.write_ch2(v)

    async def write_ch1(self, data):    
        await RisingEdge(self.dut.CLKADC)           
        self.dut.ch1_data.value = data

    async def write_ch2(self, data):    
        await RisingEdge(self.dut.CLKADC)           
        self.dut.ch2_data.value = data

    async def readDataUart(self):
        for i in range(100):
            await RisingEdge(self.dut.clk_reading) 
        # self.uart_sink._restart()    
        for i in range(1000):
            # rx_data = bytearray()
            # while len(rx_data) < 8:
            self.data_uart.append(await self.uart_sink.read())
            # self.data_uart = await self.dut.uart_sink.recv()
            # self.log.info("Read data: %s", self.data_uart[i])

    async def readDataUartSigned(self):
        for i in range(100):
            await RisingEdge(self.dut.clk_reading) 
 
        for i in range(2000):
            data8 =  int.from_bytes(await self.uart_sink.read(), 'little')
            self.data_uart.append(self.toSigned8(data8))
            
    async def sendDataUart(self):
        for i in range(2000):
            await RisingEdge(self.dut.clk_reading) 

        await self.uart_source.write(b'1')   
       

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

    async def delay(self, timeout):
        for i in range(timeout):
            await RisingEdge(self.dut.clk_reading) 

async def run_test(dut):

    tb = TB(dut)

    #id_count = 2**len(tb.source.bus.tid)

    for i in range(2):
        tb.generateSin(0.6,10,3500,1e3,1,500,i)
    await tb.reset()

    ch1_config = 200      # offset
    ch1_config |= 9 << 15 # scale
    ch1_config |= 0 << 16 # couple
    ch1_config |= 1<<  31 # enable
    await tb.write_to_axi_lite(tb.Channel1Config, ch1_config)

    ch2_config = 200      # offset
    ch2_config |= 9 << 15 # scale
    ch2_config |= 0 << 16 # couple
    ch2_config |= 1<<  31 # enable
    await tb.write_to_axi_lite(tb.Channel2Config, ch2_config)

    time_config = 2      # scale
    await tb.write_to_axi_lite(tb.TimeConfig, time_config)

    trigger_config  = 100      # value    
    trigger_config |= 0 <<  31 # enable 0 | disable 1
    await tb.write_to_axi_lite(tb.TriggerConfig, trigger_config)

    write_ch1 = cocotb.start_soon(tb.write_ch1_thead())
    write_ch2 = cocotb.start_soon(tb.write_ch2_thead())

    read_uart_ch1 = cocotb.start_soon(tb.readDataUartSigned())

    # await tb.sendDataUart()
    # await tb.delay(2000)
    # trigger_config |= 1 <<  12 # start read
    # await tb.write_to_axi_lite(tb.TriggerConfig, trigger_config)
    assert 1 == 1   

    # Wait for the other thread to complete
    await write_ch1
    await write_ch2
    await read_uart_ch1
   
    plt.plot(tb.data_uart)
    plt.show() 


if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))


@pytest.mark.parametrize("data_width", [12])
def test_oscilloscope(request, data_width):
    dut = "oscilloscope"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),
        os.path.join(hdl_dir, "fifo/fifo_async.v"),
        # os.path.join(hdl_dir, "data_decimation.v"),
        # os.path.join(hdl_dir, "trigger_level_acq.v"),
        # os.path.join(hdl_dir, "moving_average_fir.v"),
        # os.path.join(hdl_dir, "zero_crossing_detector.v"),
        # os.path.join(hdl_dir, "passband_filter"),
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
