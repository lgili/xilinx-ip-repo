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
# https://pypi.org/project/svreal/ to use hard_float
# need cocotb 1v8
import itertools
import logging
import os
import numpy as np
import bitstring, random , struct,codecs

import pytest
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.regression import TestFactory

import matplotlib.pyplot as plt 
from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink

class TB:
    def __init__(self, dut):
        self.dut = dut
        self.signal_a = []
        self.signal_b = []
        self.signal_c = []

        self.getbit = [2048,1024,512,256,128,64,32,16,8,4,2,1]

        for i in range(16):
            channel = f'cocotb.ad7276_wrapper.axis_ch{i+1}'            
            self.log_ch = logging.getLogger(channel)
            self.log_ch.setLevel(logging.ERROR)
        
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.ERROR)

        cocotb.cocotb.start_soon(Clock(dut.CLK100MHz, 10,units="ns").start())     

        self.axis_ch1 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch1"), dut.adc_sampling, dut.resetn,reset_active_level=False)  
        self.axis_ch2 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch2"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch3 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch3"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch4 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch4"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch5 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch5"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch6 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch6"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch7 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch7"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch8 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch8"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch9 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch9"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch10 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch10"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch11 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch11"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch12 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch12"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch13 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch13"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch14 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch14"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch15 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch15"), dut.adc_sampling, dut.resetn,reset_active_level=False)
        self.axis_ch16 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "axis_ch16"), dut.adc_sampling, dut.resetn,reset_active_level=False)  

        self.all_axis = [self.axis_ch1, self.axis_ch2, self.axis_ch3, self.axis_ch4, self.axis_ch5, self.axis_ch6, self.axis_ch7, self.axis_ch8,
        self.axis_ch9, self.axis_ch10, self.axis_ch11, self.axis_ch12, self.axis_ch13, self.axis_ch14, self.axis_ch15, self.axis_ch16]

       
        
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
        

    def set_backpressure_generator(self, generator=None):
            if generator:
                self.sink.set_pause_generator(generator())

    async def reset(self):
        self.dut.ARESETN.setimmediatevalue(0)
        self.dut.inData.setimmediatevalue(0)
        self.dut.axis_ch1_tready.setimmediatevalue(0)
        
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)
        self.dut.ARESETN.value = 0
        await RisingEdge(self.dut.CLK100MHz)
        await RisingEdge(self.dut.CLK100MHz)
    
        for i in range(100): 
            await RisingEdge(self.dut.CLK100MHz)
        
        self.dut.ARESETN.value = 1  
        for i in range(100): 
            await RisingEdge(self.dut.CLK100MHz)
        self.dut.axis_ch1_tready.value = 1 

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

    async def read_m_axis_thead(self, axis_num, num_pkg):
        self.ch0_frame = []
        self.data = [[0 for x in range(16)] for y in range(num_pkg)]
        
        for i in range(num_pkg):
            rx_data = bytearray()
            rx_data = await self.all_axis[axis_num].read() 
            # print(rx_data)     
            
            # for i in range(pkg_len):
            # d0 = rx_data[4*i]
            # d1 = rx_data[4*i+1]
            # d2 = rx_data[4*i+2]
            # d3 = rx_data[4*i+3]
            # data = [d0, d1, d2, d3]
            # value = int.from_bytes(rx_data, byteorder='little', signed=False) 
            # value_float = struct.unpack("f", rx_data)
            value_float = 0
            if(len(rx_data) == 4):
                value_float = self.bytes_to_float(rx_data)
            #print("###########################################################################")
            #print(value)
            #print(value_float)
            # self.ch0_frame.append(value)
            self.data[axis_num-1].append(value_float)
            # print(value)

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
    
    def bytes_to_float(self, bytesArray):
        # print(bytesArray)
        hexfloat = ''.join(format(x, '02x') for x in bytesArray)
        return struct.unpack('<f', codecs.decode(hexfloat, 'hex_codec'))[0]
    """
    f is the input floating point number 
    e is the number of fractional bits in the Q format. 
        Example in Q1.15 format e = 15
    """
    def to_fixed(self,f,e):
        a = f* (2**e)
        b = int(round(a))
        if a < 0:
            # next three lines turns b into it's 2's complement.
            b = abs(b)
            b = ~b
            b = b + 1
        return b   

    """
    x is the input fixed number which is of integer datatype
    e is the number of fractional bits for example in Q1.15 e = 15
    """
    def to_float(self,x,e):
        c = abs(x)
        sign = 1 
        if x < 0:
            # convert back from two's complement
            c = x - 1 
            c = ~c
            sign = -1
        f = (1.0 * c) / (2 ** e)
        f = f * sign
        return f
    
    def ieee754(self,flt):
        b = bitstring.BitArray(float=flt, length=32)
        return b

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
        
   
async def run_test(dut, backpressure_inserter=None):

    tb = TB(dut)

    #id_count = 2**len(tb.source.bus.tid)

    cur_id = 1

    for i in range(2):
        tb.generateSin(0.6,1,3500,1e3,1,500,i)

    # plt.plot(tb.signal_a)
    # plt.plot(tb.signal_b)
    # plt.show() 
    await tb.reset()
    tb.set_backpressure_generator(backpressure_inserter)


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


    read_thread_1 = cocotb.start_soon(tb.read_m_axis_thead(1, int(len(tb.signal_a)*7)))
    read_thread_2 = cocotb.start_soon(tb.read_m_axis_thead(2, int(len(tb.signal_a)*7)))
       
    assert 1 == 1   
    await RisingEdge(dut.CLK100MHz)
    await RisingEdge(dut.CLK100MHz)

    x = tb.ieee754(2.5)
    print(x)
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
    await read_thread_1
    await read_thread_2

    plt.plot(tb.data[0])
    # plt.plot(tb.data[1])
    plt.show() 
 

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    # factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '.',  'hdl'))
pll_dir = os.path.abspath(os.path.join(hdl_dir, '.',  'pll'))


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
