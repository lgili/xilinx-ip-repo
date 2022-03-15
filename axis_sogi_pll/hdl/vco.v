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


module vco#
(
    parameter DATA_WIDTH = 32,    
    parameter FP_WIDTH   = 24,
    parameter TIME_STEP = 335,  // 1/50e3
    parameter INV_PI2 = 2670176  // 1/2PI
) 
(
    input wire Clk,
    input wire Resetn,

    
    input signed [DATA_WIDTH-1:0] in_data,  
    output reg [DATA_WIDTH-1:0] wt, 

    input wire  in_data_valid,
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
`define FSM_STATE_5 		5 
`define FSM_STATE_6 		6 
`define FSM_STATE_7 		7 
`define FSM_STATE_8 		8 
`define FSM_STATE_9 		9 
`define FSM_STATE_10 		10  

localparam PI2F = 3162430711;  // size 33

initial begin 
    wt = 0;
end 

//------------------------------------------------------------------------------
//----------- Registers Declarations -------------------------------------------
//------------------------------------------------------------------------------
reg [3:0] current_state; 

reg signed [2*DATA_WIDTH-1:0] sum_in_ts_, div_, wt_temp;
reg signed [DATA_WIDTH-1:0] sum_in_ts, old_sum, sum_in_ts_old, div, unsigned_wt;

//reg signed [2*DATA_WIDTH:0] 

//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------

always @(posedge Clk)  //cs_n
	if ( ! Resetn ) begin 
        current_state <= `FSM_STATE_IDLE; 
        old_sum <= 0;
        sum_in_ts <= 0;
        sum_in_ts_ <= 0;
        div_ <=0;
        div <=0;
        sum_in_ts_old <= 0;
	end 
	else begin 
        if(out_data_ready == 1) begin
            in_data_ready <= 1;
        end
        else begin 
            in_data_ready <= 0;
        end


        case ( current_state )
		`FSM_STATE_IDLE: begin
            if(out_data_ready) begin 
			    if(in_data_valid) begin
                    current_state <=  `FSM_STATE_1;
                end
                else begin
                    current_state <=  `FSM_STATE_IDLE;
                end
            end   
            else begin
                current_state <=  `FSM_STATE_IDLE;
            end 

        end

        `FSM_STATE_1: begin
            sum_in_ts_ <= (in_data + PI2F);//* TIME_STEP;           
            current_state <=  `FSM_STATE_2;
        end

        `FSM_STATE_2: begin            
            sum_in_ts <= sum_in_ts_[31:0];// >> FP_WIDTH;
            current_state <=  `FSM_STATE_3;
        end

        `FSM_STATE_3: begin            
            sum_in_ts_old <=  old_sum + sum_in_ts;
            current_state <=  `FSM_STATE_4;
        end

        `FSM_STATE_4: begin
            div_ <= sum_in_ts_old * INV_PI2;           
            current_state <=  `FSM_STATE_5;
        end

        `FSM_STATE_5: begin            
            div <= div_ >> FP_WIDTH;
            current_state <=  `FSM_STATE_6;
        end

        `FSM_STATE_6: begin            
            old_sum <= div;
            if(div >= 32'h80000000) begin
				unsigned_wt <= ~div + 32'b1;
			end
			else begin 
				unsigned_wt <= div + 32'h80000000;
			end
           
            current_state <=  `FSM_STATE_7;
        end

        `FSM_STATE_7: begin            
            wt_temp <= unsigned_wt * (1 << 32) * 5340353;
            wt <= unsigned_wt * 2;
            current_state <=  `FSM_STATE_IDLE;
        end

        default: begin 
			current_state <= `FSM_STATE_IDLE;			
		end 
		endcase
             

    end

endmodule