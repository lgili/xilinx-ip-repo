
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

module integrator#
(
    parameter DATA_WIDTH = 12,
    parameter RESOLUTION = 32000
)
(
    input wire clk,
    input wire rst_n,
    input wire ready,

    input data_in
);

//------------------------------------------------------------------------------
//----------- Local Parameters -------------------------------------------------
//------------------------------------------------------------------------------
localparam real CLOCK_FREQ     = 100000000;
localparam real ADC_CYCLE_TIME      = 0.000001000;
localparam TS                       = 


//------------------------------------------------------------------------------
//----------- Registers Declarations -------------------------------------------
//------------------------------------------------------------------------------
`define FSM_STATE_STEP_1	0 
`define FSM_STATE_STEP_2 	1
`define FSM_STATE_STEP_3	2

reg [1:0] state;
reg [DATA_WIDTH:0] tmp;

//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------



always @(posedge Clk) begin
    if (!rst_n) begin
      state <= FSM_STATE_STEP_1;
      tmp <= 0;
      cum_out <= 0;
      err_overflow <= 1'b0;
    end
    else begin
      case(state)

        `FSM_STATE_STEP_1 : begin
          tmp[7:0] <= data_in; // y1
          if (ready) state <= `FSM_STATE_STEP_2;
        end

        `FSM_STATE_STEP_2 : begin
          tmp[8:0] <= tmp[7:0] + s_in; // y1+y2
          state <= `FSM_STATE_STEP_3; // gray code
        end

       `FSM_STATE_STEP_3 : begin
          tmp <= s_in * tmp[8:0]; // x*(y1+y2)
          state <= `FSM_STATE_STEP_4; // gray code
        end

       `FSM_STATE_STEP_5 : begin
          {err_overflow,cum_out} <= cum_out + tmp[16:1]; // tmp[16:1] === tmp/2
          state <= `FSM_STATE_STEP_0;
        end
      endcase
    end
  end





endmodule