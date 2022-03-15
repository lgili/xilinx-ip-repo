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


module ab_dq#
(
    parameter DATA_WIDTH = 32,
    parameter FP_WIDTH   = 24
) 
(
    input wire Clk,
    input wire Resetn,

    input signed [DATA_WIDTH-1:0] alpha,
    input signed [DATA_WIDTH-1:0] beta,
    input [DATA_WIDTH-1:0] theta,
    
    output reg signed [DATA_WIDTH-1:0] d,
    output reg signed [DATA_WIDTH-1:0] q,

    input wire aligned_to_zero,

    input wire  in_data_valid, // this will indacate the freq of calculation
    output reg  in_data_ready,

    output reg  out_data_valid,
    input wire  out_data_ready

);


//begin initial 
//    theta <= 0;
//end



//------------------------------------------------------------------------------
//----------- Local Parameters -------------------------------------------------
//------------------------------------------------------------------------------


`define FSM_STATE_IDLE		0 
`define FSM_STATE_1  		1 
`define FSM_STATE_2 		2 
`define FSM_STATE_3 		3 
`define FSM_STATE_4 		4 

localparam VALUE = 32767/1.164435; // reduce by a factor of 1.647 since thats the gain of the system


//------------------------------------------------------------------------------
//----------- Registers Declarations -------------------------------------------
//------------------------------------------------------------------------------
reg [2:0] state;
reg signed [15:0] sin;
reg signed [15:0] cos;

reg signed [DATA_WIDTH-1:0] result_alpha_cos;
reg signed [DATA_WIDTH-1:0] result_beta_sin;

reg signed [2*DATA_WIDTH-1:0] result_alpha_cos_temp;
reg signed [2*DATA_WIDTH-1:0] result_beta_sin_temp;

reg signed [DATA_WIDTH-1:0] result_alpha_sin;
reg signed [DATA_WIDTH-1:0] result_beta_cos;

reg signed [2*DATA_WIDTH-1:0] result_alpha_sin_temp;
reg signed [2*DATA_WIDTH-1:0] result_beta_cos_temp;

reg signed [2*DATA_WIDTH-1:0] d_temp;
reg signed [2*DATA_WIDTH-1:0] q_temp;

reg signed [DATA_WIDTH-1:0] sin_32;
reg signed [DATA_WIDTH-1:0] cos_32;
//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------



cordic #
(
    .DATA_WIDTH(DATA_WIDTH)
) sin_cos
(
    .i_clk(Clk),
    .i_reset(!Resetn),
    .i_ce(in_data_valid),
    .i_phase(theta), 
    .i_xval(VALUE), 
    .i_yval(1'd0), 
    .o_xval(cos),
    .o_yval(sin)    
);

assign sin_32 =  sin << (FP_WIDTH-14); // fixing size from Q1.14 to Q16.16
assign cos_32 =  cos << (FP_WIDTH-14);

// d part
//qmult mult1 (alpha, cos_32 , result_alpha_cos);
//qmult mult2 (beta, sin_32 , result_beta_sin);

//qmult mult3 (beta, cos_32 , result_beta_cos);
//qmult mult4 (alpha, sin_32 , result_alpha_sin);

//assign d = (aligned_to_zero) ? (result_alpha_cos + result_beta_sin) : (result_alpha_sin - result_beta_cos);
//assign q = (aligned_to_zero) ? (result_beta_cos - result_alpha_sin) : (result_alpha_cos + result_beta_sin);


always @(posedge Clk)  
	if ( ! Resetn ) begin 
        out_data_valid <= 0;
        state <= `FSM_STATE_IDLE;
    end
    else begin
         if(out_data_ready == 1) begin
            in_data_ready <= 1;
        end
        else begin 
            in_data_ready <= 0;
        end

        case(state)
        `FSM_STATE_IDLE: begin
            out_data_valid <=0;
            if(out_data_ready) begin 
			    if(in_data_valid) begin
                    state <=  `FSM_STATE_1;
                end
                else begin
                    state <=  `FSM_STATE_IDLE;
                end
            end   
            else begin
                state <=  `FSM_STATE_IDLE;
            end 

        end
        `FSM_STATE_1: begin
            
            // d part
            result_alpha_cos_temp <= alpha * cos_32;
            result_beta_sin_temp <= beta * sin_32;

            result_alpha_cos <= result_alpha_cos_temp >> FP_WIDTH;
            result_beta_sin <= result_beta_sin_temp >> FP_WIDTH;

            // q part
            result_beta_cos_temp <= beta * cos_32;
            result_alpha_sin_temp <= alpha * sin_32;

            result_beta_cos <= result_beta_cos_temp >> FP_WIDTH;
            result_alpha_sin <= result_alpha_sin_temp >> FP_WIDTH;           
            

            state <=  `FSM_STATE_2;
            
        end

        `FSM_STATE_2: begin            
            
            if(aligned_to_zero) begin 
                d <= result_alpha_cos + result_beta_sin;
                q <= result_beta_cos - result_alpha_sin;
            end 
            else begin 
                d <= result_alpha_sin - result_beta_cos;
                q <= result_alpha_cos + result_beta_sin;
            end 
            
            state <=  `FSM_STATE_3;           

        end

        `FSM_STATE_3: begin
            out_data_valid <= 1;
            state <=  `FSM_STATE_IDLE;
        end 
               
        default: begin 
			state <= `FSM_STATE_IDLE;			
		end 
		endcase
    
       
    end





endmodule