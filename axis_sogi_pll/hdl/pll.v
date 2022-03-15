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


module pll#
(
    parameter DATA_WIDTH = 32,
    parameter FP_WIDTH   = 24,
    parameter KP = 0.8*(2 ** FP_WIDTH),
    parameter KI = 1.2*(2 ** FP_WIDTH),       // 1/1e3
    parameter TIME_STEP = 335 //0.00002*(2 ** FP_WIDTH)  // 1/50e3
) 
(
    input wire Clk,
    input wire Resetn,

    input signed [DATA_WIDTH-1:0] phase_a,
    input signed [DATA_WIDTH-1:0] phase_b,
    input signed [DATA_WIDTH-1:0] phase_c,

    input wire clk_control,
    input signed [DATA_WIDTH-1:0] data,


    // remove
    input signed [DATA_WIDTH-1:0] theta

);

wire signed [DATA_WIDTH-1:0] alpha;
wire signed [DATA_WIDTH-1:0] beta;

wire signed [DATA_WIDTH-1:0] d;
wire signed [DATA_WIDTH-1:0] q;


wire signed [DATA_WIDTH-1:0] out_pi;
wire signed [DATA_WIDTH-1:0] outSat_pi;
wire out_pi_valid, out_dq_valid;
wire in_vco_ready, in_dq_ready, in_pi_ready;

wire signed [DATA_WIDTH-1:0] out_pi_sum;
wire [DATA_WIDTH-1:0] wt_cal;

reg signed [DATA_WIDTH-1:0] testkp = TIME_STEP;

wire data_valid;
wire data_ready;
wire out_ab_valid;

data_valid_gen valid
(
    .Clk(Clk),
    .clk_control(clk_control),
    .Resetn(Resetn),

    .out_data_valid(data_valid),
    .out_data_ready(data_ready)
);

alphaBeta #
(
     .DATA_WIDTH(DATA_WIDTH),
     .FP_WIDTH(FP_WIDTH)
) alphaBeta
(
    .Clk(Clk),
    .Resetn(Resetn),

    .phase_a(phase_a),
    .phase_b(phase_b),
    .phase_c(phase_c),

    .alpha(alpha),
    .beta(beta),

    .in_data_valid(data_valid),
    .in_data_ready(data_ready),

    .out_data_valid(out_ab_valid),
    .out_data_ready(in_dq_ready)     
);


ab_dq#
(
    .DATA_WIDTH(DATA_WIDTH),
    .FP_WIDTH(FP_WIDTH)
) alphaBeta_to_dq
(
    .Clk(Clk),
    .Resetn(Resetn),

    .alpha(alpha),
    .beta(beta),
    .theta(wt_cal),

    .d(d),
    .q(q),

    .aligned_to_zero(0),

    .in_data_valid(out_ab_valid),
    .in_data_ready(in_dq_ready),

    .out_data_valid(out_dq_valid),
    .out_data_ready(1'b1) //in_pi_ready 

);
/*
pi_controller #
(
    .DATA_WIDTH(DATA_WIDTH),
    .FP_WIDTH(FP_WIDTH),
    .KP(KP),
    .KI(KI),
    .TIME_STEP(TIME_STEP)
) pi
(
    .Clk(Clk),
    .Resetn(Resetn),

    .clk_control(clk_control),
    .reference(0),
    .input_data(q),
    .out(out_pi),
    .outSat(outSat_pi),

    .in_data_valid(out_dq_valid),
    .in_data_ready(in_pi_ready),

    .out_data_valid(out_pi_valid),
    .out_data_ready(in_vco_ready)
);
*/

pid#
(
    .DATA_WIDTH(DATA_WIDTH)
) pid 
(
    .Clk(clk_control),
    .Resetn(Resetn),

    .e_in(q),
    .u_out(out_pi)
);
vco#
(
    .DATA_WIDTH(DATA_WIDTH),    
    .FP_WIDTH(FP_WIDTH),
    .TIME_STEP(TIME_STEP)  // 1/50e3
) vco
(
    .Clk(Clk),
    .Resetn(Resetn),

    .in_data(out_pi),  
    .wt(wt_cal), 

    .in_data_valid(out_pi_valid),
    .in_data_ready(in_vco_ready),

    .out_data_valid(),
    .out_data_ready(1'b1)

);    
assign out_pi_sum = (out_pi_valid) ? out_pi + (24706489) : out_pi_sum;
//assign wt_cal = out_pi_sum * 6553;

endmodule