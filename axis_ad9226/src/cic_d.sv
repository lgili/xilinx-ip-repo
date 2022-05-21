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



module cic_d
/*********************************************************************************************/
#(parameter DATA_IN_WIDTH = 8, DATA_OUT_WIDTH = 8, DECIMATION_RATIO = 4, ORDER = 4, DIFFERENCIAL_DELAY = 1)
/*********************************************************************************************/
//ORDER - CIC order (comb chain length, integrator chain length)
//DECIMATION_RATIO - interpolation ratio
//DATA_IN_WIDTH - input data width
//DATA_OUT_WIDTH - output data width
//DIFFERENCIAL_DELAY - differential delay in combs
/*********************************************************************************************/
(
    input   clk,
    input   reset_n,
    input   signed [DATA_IN_WIDTH-1:0] data_in,
    output  signed [DATA_OUT_WIDTH-1:0] data_out,
    output  out_dv
);


/*********************************************************************************************/
localparam  b_max = $clog2((DECIMATION_RATIO*DIFFERENCIAL_DELAY)**ORDER)+DATA_IN_WIDTH;
/*********************************************************************************************/
genvar  i;
generate
    for (i = 0; i < ORDER; i++) begin:int_stage
        localparam idw_cur = b_max-cic_package::B(i+1,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH)+1;
        localparam odw_cur = idw_cur;
        localparam odw_prev = (i!=0) ? b_max-cic_package::B(i,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH)+1 : 0;
        wire signed [idw_cur-1:0] int_in;
        if (i!=0)
            assign int_in = int_stage[i-1].int_out[odw_prev-1:odw_prev-idw_cur];
        else
            assign int_in = data_in;
        wire signed [odw_cur-1:0] int_out;
        integrator #(idw_cur, odw_cur) int_inst(.clk(clk) , .reset_n(reset_n) , .data_in(int_in) , .data_out(int_out));
    end
endgenerate
/*********************************************************************************************/
localparam ds_dw = b_max-cic_package::B(ORDER,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH)+1;
wire signed [ds_dw-1:0] ds_out;
wire    ds_dv;
/*********************************************************************************************/
downsampler #(ds_dw, DECIMATION_RATIO) u1
(
    .clk(clk),
    .reset_n(reset_n),
    .data_in(int_stage[ORDER-1].int_out),
    .data_out(ds_out),
    .dv(ds_dv)
);
/*********************************************************************************************/
genvar  j;
generate
    for (j = 0; j < ORDER; j++) begin:comb_stage
        localparam idw_cur = b_max-cic_package::B(ORDER+j+1,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH);
        localparam odw_cur = idw_cur;
        localparam odw_prev = (j!=0) ? b_max-cic_package::B(ORDER+j,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH) : 0;
        wire signed [idw_cur-1:0] comb_in;
        if (j!=0)
            assign comb_in = comb_stage[j-1].comb_out[odw_prev-1:odw_prev-idw_cur];
        else
            assign comb_in = ds_out[ds_dw-1:ds_dw-idw_cur];
        wire signed [odw_cur-1:0] comb_out;
        comb #(idw_cur, odw_cur, DIFFERENCIAL_DELAY) comb_inst(.clk(clk) , .reset_n(reset_n) , .in_dv(ds_dv) , .data_in(comb_in) , .data_out(comb_out));
    end
endgenerate
/*********************************************************************************************/
localparam dw_out = b_max-cic_package::B(2*ORDER,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH);
assign data_out = comb_stage[ORDER-1].comb_out[dw_out-1:dw_out-DATA_OUT_WIDTH];
assign out_dv = ds_dv;
/*********************************************************************************************/
endmodule