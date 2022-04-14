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
from select import select
import numpy as np


import pytest
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.regression import TestFactory

import matplotlib.pyplot as plt 
from fxpmath import Fxp
import ClarkePark

class TB:
    def __init__(self, dut):
        self.dut = dut
               

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.cocotb.start_soon(Clock(dut.clk_control, 20,units="us").start())  
        cocotb.cocotb.start_soon(Clock(dut.Clk, 200,units="ns").start())       
                        
        
    
    async def reset(self):
        self.dut.Resetn.setimmediatevalue(0)    
       
        
        await RisingEdge(self.dut.Clk)
        await RisingEdge(self.dut.Clk)
        self.dut.Resetn.value = 0
        await RisingEdge(self.dut.Clk)
        await RisingEdge(self.dut.Clk)
        self.dut.Resetn.value = 1  
        await RisingEdge(self.dut.Clk)
        await RisingEdge(self.dut.Clk)
        
               
    
    async def add(self, value_1, value_2):
        self.dut.sum_a.value = value_1
        self.dut.sum_b.value = value_2
        await RisingEdge(self.dut.Clk)
        return self.dut.result_sum.value

    


    async def write_sig_a_thead(self):        
        for i in range(len(self.signed_signal_a)):         
            v = int(self.signed_signal_a[i])  
            await RisingEdge(self.dut.clk_control)      
            self.dut.phase_a.value = v
   
    async def write_sig_b_thead(self):        
        for i in range(len(self.signed_signal_b)):         
            v = int(self.signed_signal_b[i])  
            await RisingEdge(self.dut.clk_control)      
            self.dut.phase_b.value = v

    async def write_sig_c_thead(self):        
        for i in range(len(self.signed_signal_c)):         
            v = int(self.signed_signal_c[i])  
            await RisingEdge(self.dut.clk_control)      
            self.dut.phase_c.value = v
        

    async def write_angle(self):
       
        pw = 23  # Bits in our phase variables
        nsamples = 1<<pw
        t_local = 0        
        for i in range(len(self.signal_a)):
            await RisingEdge(self.dut.clk_control)  
            while self.theta[i] >= 2*np.pi:            
                self.theta[i] = self.theta[i] - 2*np.pi
            
            theta = int(self.theta[i] * (1<<32) / (2*np.pi))
            #print(self.theta[i])    
            self.dut.theta.value = theta # #int(gain * np.pi)  #int(*(2**32)/(2*np.pi)) corrigit step
            

    def generateSin(self, freq, time, amp,  sample_rate, random, random_range, channel):
        samples = np.arange(0, time, 1/sample_rate) 
        noise = 0
        if random == 1:
              noise = np.random.randint(random_range, size=(len(samples)))  
        if channel == 0:    
            self.theta =  2 * np.pi * freq * samples 
            
            self.signal_a = amp * np.sin(self.theta)    + noise
            self.signal_a = np.int32(self.signal_a)
            self.signed_signal_a = np.int32(self.signal_a) & 0xffffffff # to signed int32
            #for i in range(len(samples)):
            #    x = Fxp(self.signal_a[i], True, 32, 16)
            #    self.signal_a[i] = int(x.hex(),0)
        elif channel == 1:
            self.signal_b = amp * np.sin(2 * np.pi * freq * samples - (2*np.pi/3))  +  noise
            self.signal_b = np.int32(self.signal_b)
            self.signed_signal_b = np.int32(self.signal_b) & 0xffffffff # to signed int32
            #for i in range(len(samples)):
            #    x = Fxp(self.signal_b[i], True, 32, 16)
            #    self.signal_b[i] = int(x.hex(),0)  
        elif channel == 2:
            self.signal_c = amp * np.sin(2 * np.pi * freq * samples + (2*np.pi/3))  +  noise
            self.signal_c = np.int32(self.signal_c)
            self.signed_signal_c = np.int32(self.signal_c) & 0xffffffff # to signed int32
            #for i in range(len(samples)):
            #    x = Fxp(self.signal_a[i], True, 32, 16)
            #    self.signal_a[i] = int(x.hex(),0)             
      

"""
x is the input fixed number which is of integer datatype
e is the number of fractional bits for example in Q1.15 e = 15
"""
def to_float(x,e):
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
"""
f is the input floating point number 
e is the number of fractional bits in the Q format. 
    Example in Q1.15 format e = 15
"""
def to_fixed(f,e):
    a = f* (2**e)
    b = int(round(a))
    if a < 0:
        # next three lines turns b into it's 2's complement.
        b = abs(b)
        b = ~b
        b = b + 1
    return b           
   
async def run_test(dut):

    tb = TB(dut)

    pk = (1 << 24) # 
    for i in range(3):
        tb.generateSin(60,0.1,pk,50e3,0,500,i) #65536

    a = tb.signal_a/pk
    b = tb.signal_b/pk
    c = tb.signal_c/pk

    
    
    alpha, beta, z = ClarkePark.abc_to_alphaBeta0(a,b,c)    
    # plt.plot(alpha)
    # plt.plot(beta)
    # plt.plot(z)
    # plt.show()

    # #d, q, z1 = ClarkePark.abc_to_dq0(A, B, C, wt, delta)
    # d, q, z1 = ClarkePark.alphaBeta0_to_dq0(alpha, beta, z, tb.theta, 0)
    # plt.plot(d)
    # plt.plot(q)
    # plt.plot(z1)
    # plt.show()


    
    #plt.plot(a)
    #plt.plot(a-b*0.5-c*0.5)
    #plt.plot(tb.signal_b)
    #plt.plot(tb.signal_c)
    #plt.show() 
    await tb.reset()

    #val_2 = 2.75
    #val_1 = -1
    #num_a = to_fixed(val_1,4)
    #print(num_a)
    
    #x = Fxp(val_1, True, 16, 4)      # signed=True, n_word=16, n_frac=8  
    
    #print(x.hex())
    #print(int(x.hex(),base=16))
    #num_b = to_fixed(val_2,4)
    #print(num_b)

    #result_add = await tb.add(num_a,num_b)

    #print(val_1+val_2)
    #num_f = to_float(int(result_add),4)
    #print(num_f)

    
    

    #await tb.write(20,12)

    # Run reset_dut concurrently
    write_thread_a = cocotb.start_soon(tb.write_sig_a_thead())
    write_thread_b = cocotb.start_soon(tb.write_sig_b_thead())
    write_thread_c = cocotb.start_soon(tb.write_sig_c_thead())

    write_angle_thread = cocotb.start_soon(tb.write_angle())
    
   
    assert 1 == 1   
    await RisingEdge(dut.Clk)
    await RisingEdge(dut.Clk)

    # Wait for the other thread to complete
    await write_thread_a
    await write_thread_b
    await write_thread_c
    await write_angle_thread




if cocotb.SIM_NAME:
    factory = TestFactory(run_test)    
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
hdl_dir = os.path.abspath(os.path.join(tests_dir, '..',  'hdl'))



@pytest.mark.parametrize("data_width", [32])
def test_pll(request, data_width):
    dut = "pll"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(hdl_dir, f"{dut}.v"),
        os.path.join(hdl_dir, "alphaBeta.v"),       
        os.path.join(hdl_dir, "cordic.v"),
        os.path.join(hdl_dir, "qmult.v"),  
        os.path.join(hdl_dir, "pi_controller.v"),  
        os.path.join(hdl_dir, "ab_dq.v"),  
        os.path.join(hdl_dir, "vco.v"),  
        os.path.join(hdl_dir, "data_valid_gen.v"), 
        os.path.join(hdl_dir, "pid.v"), 
    ]

    parameters = {}

    parameters['DATA_WIDTH'] = data_width    
    #parameters['FRACTIONAL_WIDTH'] = 10

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
