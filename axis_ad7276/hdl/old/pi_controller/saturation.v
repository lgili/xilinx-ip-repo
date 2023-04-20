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

module control_output(clk, reset_n, state, delta_u, u_prev, u_out);

    parameter DATA_WIDTH = 16; 

    input clk; 
    input reset_n; 
    input [3:0] state; 
    input signed [DATA_WIDTH-1:0] delta_u; 
    input signed [DATA_WIDTH-1:0] u_prev; 
    output reg signed [DATA_WIDTH-1:0] u_out; 
    
    parameter computeU = 0003; 
    parameter integratorClip = 11'd181; 
    
    always @ (posedge clk) 
        begin 
        
            if (!reset_n) 
                u_out <= 0; 
               
               else 
                    begin
                            if (state == computeU) 
                                begin 
                                    if (u_prev <= integratorClip && u_prev >= 0) 
                                        u_out <= delta_u + u_prev; 
                                    else if (u_prev < 0) 
                                        u_out <= delta_u + 0; 
                                    else if (u_prev > integratorClip) 
                                        u_out <= delta_u + integratorClip; 
                                    else 
                                        u_out <= 0; 
                                 end 
                            else 
                                u_out <= u_out; 
                   end 
          end   
     
endmodule