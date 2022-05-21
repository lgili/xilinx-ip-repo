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

function reg signed [63:0] nchoosek;
    input   signed [63:0] n;
    input   signed [63:0] k;
    reg signed [63:0] tmp;
    reg signed [63:0] i;
    begin
        tmp = 1.0;
        for (i=1;i<=(n-k);i=i+1)
            tmp = tmp*(k+i)/i;
        nchoosek = tmp;
    end
endfunction

/*********************************************************************************************/
function reg signed [63:0] B;
    input   signed [63:0] j;
    input   signed [63:0] R;
    input   signed [63:0] G;
    input   signed [63:0] M;
    input   signed [63:0] dw_in;
    input   signed [63:0] dw_out;
    reg signed [63:0] B_max;
    reg signed [63:0] sigma_T;
    reg signed [63:0] tmp;
    begin
        B_max = $clog2((R*G)**M)+dw_in-1;
        sigma_T = (2**(2*(B_max-dw_out+1)))/12;
        tmp = (6*sigma_T)/(M*F(j,R,G,M));
        B = (clog2_l(tmp)-1)/2;
    end
endfunction
/*********************************************************************************************/

/*********************************************************************************************/
function reg signed [63:0] clog2_l;
    input signed [63:0] depth;
    reg signed [63:0] i;
    begin
        i = depth;        
        for(clog2_l = 0; i > 0; clog2_l = clog2_l + 1)
            i = i >> 1;
    end
endfunction
/*********************************************************************************************/
function reg signed [63:0] h;
    input   signed [63:0] j;
    input   signed [63:0] k;
    input   signed [63:0] R;
    input   signed [63:0] M;
    input   signed [63:0] N;
    reg signed [63:0] c_stop;
    reg signed [63:0] i;
    reg signed [63:0] tmp;
    begin
        c_stop = k/(R*M);
        if ((j>=1)&&(j<=N)) begin
            tmp=0.0;
            for (i=0;i<=c_stop;i=i+1) begin
                if (i%2)
                    tmp = tmp - nchoosek(N,i)*nchoosek(N-j+k-R*M*i,k-R*M*i);
                else
                    tmp = tmp + nchoosek(N,i)*nchoosek(N-j+k-R*M*i,k-R*M*i);
            end
        end
        else begin
            tmp = nchoosek(2*N+1-j,k);
            if (k%2)
                tmp = -tmp;
        end
        h = tmp;
    end
endfunction
/*********************************************************************************************/
function reg signed [63:0] F;
    input   signed [63:0] j;
    input   signed [63:0] R;
    input   signed [63:0] G;
    input   signed [63:0] M;
    reg signed [63:0] c_stop;
    reg signed [63:0] tmp;
    reg signed [63:0] i;
    begin
        tmp = 0.0;
        if (j<=M)
            c_stop=(((R*G-1)*M)+j-1);
        else
            c_stop=2*M+1-j;
        for (i=0;i<=c_stop;i=i+1) begin
            tmp = tmp + h(j,i,R,G,M)*h(j,i,R,G,M);
        end
        F = tmp;
    end
endfunction
/*********************************************************************************************/
localparam  b_max = $clog2((DECIMATION_RATIO*DIFFERENCIAL_DELAY)**ORDER)+DATA_IN_WIDTH;
/*********************************************************************************************/
genvar  i;
generate
    for (i = 0; i < ORDER; i=i+1) begin:int_stage
        localparam idw_cur = b_max- B(i+1,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH)+1;
        localparam odw_cur = idw_cur;
        localparam odw_prev = (i!=0) ? b_max- B(i,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH)+1 : 0;
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
localparam ds_dw = b_max- B(ORDER,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH)+1;
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
    for (j = 0; j < ORDER; j=j+1) begin:comb_stage
        localparam idw_cur = b_max- B(ORDER+j+1,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH);
        localparam odw_cur = idw_cur;
        localparam odw_prev = (j!=0) ? b_max- B(ORDER+j,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH) : 0;
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
localparam dw_out = b_max- B(2*ORDER,DECIMATION_RATIO,DIFFERENCIAL_DELAY,ORDER,DATA_IN_WIDTH,DATA_OUT_WIDTH);
assign data_out = comb_stage[ORDER-1].comb_out[dw_out-1:dw_out-DATA_OUT_WIDTH];
assign out_dv = ds_dv;
/*********************************************************************************************/
endmodule