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


module alphaBeta#
(
    parameter DATA_WIDTH = 32,
    parameter FP_WIDTH   = 24
) 
(
    input wire Clk,
    input wire Resetn,

    input signed [DATA_WIDTH] phase_a,
    input signed [DATA_WIDTH] phase_b,
    input signed [DATA_WIDTH] phase_c,


    output reg signed [DATA_WIDTH] alpha,
    output reg signed [DATA_WIDTH] beta,

    input wire  in_data_valid, // this will indacate the freq of calculation
    output reg  in_data_ready,

    output reg  out_data_valid,
    input wire  out_data_ready

);


//------------------------------------------------------------------------------
//----------- Local Parameters -------------------------------------------------
//------------------------------------------------------------------------------


`define FSM_STATE_IDLE		0 
`define FSM_STATE_1  		1 
`define FSM_STATE_2 		2 
`define FSM_STATE_3 		3 
`define FSM_STATE_4 		4 


// use in python to convert
// x = Fxp(2/3, True, 32, 24)
// print(int(x.hex(),0))
localparam OneHalf = 8388608; // -1/2 in 32 bits 24 fractionary signed
localparam RTSD   =  14529495; // sqrt(3)/2
localparam DST    =  11184810; // 2/3



//------------------------------------------------------------------------------
//----------- Registers Declarations -------------------------------------------
//------------------------------------------------------------------------------
reg [1:0] state;
reg signed [DATA_WIDTH-1:0] result_hfb;
reg signed [DATA_WIDTH-1:0] result_hfc;

reg signed [2*DATA_WIDTH-1:0] result_hfb_temp;
reg signed [2*DATA_WIDTH-1:0] result_hfc_temp;


reg signed [DATA_WIDTH-1:0] sum_alpha;
reg signed [DATA_WIDTH-1:0] sum_beta;

reg signed [DATA_WIDTH-1:0] result_rtsdb;
reg signed [DATA_WIDTH-1:0] result_rtsdc;

reg signed [2*DATA_WIDTH-1:0] result_rtsdb_temp;
reg signed [2*DATA_WIDTH-1:0] result_rtsdc_temp;

reg signed [2*DATA_WIDTH-1:0]  alpha_temp;
reg signed [2*DATA_WIDTH-1:0]  beta_temp;

//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------

// Alpha part
//qmult mult1 (OneHalf, phase_b , result_hfb);
//qmult mult2 (OneHalf, phase_c , result_hfc);
//assign sum_alpha = phase_a - result_hfb - result_hfc;
//qmult mult3 (sum_alpha, DST , alpha);


// Beta part
//qmult mult4 (RTSD, phase_b,  result_rtsdb);
//qmult mult5 (RTSD, phase_c , result_rtsdc);
//assign sum_beta =  result_rtsdb - result_rtsdc;
//qmult mult6 (sum_beta, DST , beta);


//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------


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
            
            // Alpha part
            result_hfb_temp <= OneHalf * phase_b ;
            result_hfc_temp <= OneHalf * phase_c ;

            result_hfb <= result_hfb_temp >> FP_WIDTH;
            result_hfc <= result_hfc_temp >> FP_WIDTH;

            // Beta part
            result_rtsdb_temp <= RTSD * phase_b;
            result_rtsdc_temp <= RTSD * phase_c;

            result_rtsdb <= result_rtsdb_temp >> FP_WIDTH;
            result_rtsdc <= result_rtsdc_temp >> FP_WIDTH;

            state <=  `FSM_STATE_2;
            
        end

        `FSM_STATE_2: begin
            sum_alpha <= phase_a - result_hfb - result_hfc;
            sum_beta <=  result_rtsdb - result_rtsdc;

            state <=  `FSM_STATE_3;

        end
        `FSM_STATE_3: begin
            alpha_temp <= sum_alpha * DST;
            beta_temp <= sum_beta * DST;

            alpha <= alpha_temp >> FP_WIDTH;
            beta <= beta_temp  >> FP_WIDTH;

            out_data_valid <= 1;
            state <=  `FSM_STATE_IDLE;

        end    

       
        default: begin 
			state <= `FSM_STATE_IDLE;			
		end 
		endcase
    
       
    end


endmodule