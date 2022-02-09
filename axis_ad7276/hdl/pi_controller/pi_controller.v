/*
Copyright (c) 2014-2022 Luiz Carlos Gili

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
*/

// Language: Verilog 2001

`timescale 1ns / 1ps

// Recursive Digital PI Implementation in Verilog 

//Methodology
// - FSM to allow sequential processing of data samples from the ADC 
// - Uses an incremental PI form to compute increments to the control output 
// - Clips the integrator portion to a pre-determined voltage to prevent integrator windup 



module pi_controller(clk,reset_n, data_in_0, data_in_1, data_ready, u, pi_ready);

    parameter DATA_WIDTH = 16; 

    parameter IDLE = 0000; 
    parameter readADC = 0001; 
    parameter computeError = 0002; 
    parameter computeDeltaU = 0003; 
    parameter computeU = 0004; 
    parameter latchDAC = 0005; 

    input clk; 
    input reset_n; 
    input [DATA_WIDTH-1:0] adc_in_0; 
    input [DATA_WIDTH-1:0] adc_in_1; 
    input data_ready; 
    output reg signed [DATA_WIDTH-1:0] u; 
    output reg pi_ready; 
    
  //Local Variables 
  wire signed [DATA_WIDTH-1:0] error_bus; 
  wire signed [DATA_WIDTH-1:0] deltaU_bus; 
  wire signed [DATA_WIDTH-1:0] controlOutput_bus; 
  wire signed [DATA_WIDTH-1:0] u_out_bus; 
  
  
  reg [3:0] current_state; 
  reg [3:0] next_state; 
  reg signed [DATA_WIDTH-1:0] error; 
  reg signed [DATA_WIDTH-1:0] error_prev; 
  reg signed [DATA_WIDTH-1:0] deltaU; 
  reg signed [DATA_WIDTH-1:0] u_prev; 
  
  
 //Module Instantiations 
 
  error_calculator error 
  ( 
  .clk(clk),
  .reset_n(reset_n),
  .adc_in_0(data_in_0),
  .adc_in_1(data_in_1),
  .error(error_bus)
  ); 
 
 deltaU u_deltaU 
 ( 
 .error(error),
 .errorPrev(error_prev),
 .deltaU(deltaU_bus)
 ); 
 
 saturation sat
 ( 
 .clk(clk), 
 .reset_n(reset_n), 
 .state(current_state), 
 .delta_u(deltaU),
 .u_prev(u_prev),
 .u_out(u_out_bus)
 ); 
   
  //FSM 
  always @ (posedge clk) 
    begin 
        if (!reset_n)
            current_state <= IDLE; 
        else 
            current_state <= next_state; 
    end
    
always @ (posedge clk) 
    begin 
        
        if (!reset_n) 
            next_state <= IDLE; 
        
        else 
            begin 
                    
                 case (current_state)
                 
                 IDLE: if (data_ready) 
                         begin 
                         next_state <= readADC; 
                         end 
                       else 
                         next_state <= IDLE;
                         
                readADC: next_state <= computeError; 
                computeError: next_state <= computeDeltaU; 
                computeDeltaU: next_state <= computeU; 
                computeU: next_state <= latchDAC;
                latchDAC: next_state <= IDLE; 
                default: next_state <= IDLE; 
                
                endcase
           end
     end
     
always @ (posedge clk) 
    begin 
    
        if (!reset_n) 
            begin 
                pi_ready <= 0; 
                u <= 0; 
            end  
            
        else  
            begin 
                
                if (current_state == IDLE) 
                   begin 
                   pi_ready <= 1; 
                   u <= u; 
                   end 
                else if (current_state == readADC) 
                    begin 
                    pi_ready <= 0; 
                    end
                else if (current_state == computeError) 
                    begin 
                    error <= error_bus; 
                    error_prev <= error; 
                    end 
                else if (current_state == computeDeltaU) 
                    begin 
                    deltaU <= deltaU_bus; 
                    end 
                else if (current_state == computeU) 
                    begin 
                    u <= u_out_bus; 
                    u_prev <= u; 
                    end
                else if (current_state <= latchDAC) 
                    begin 
                    pi_ready <= 1'b1; 
                    end 
             end    
      end          
                         



endmodule