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


module pi_controller#
(
    parameter DATA_WIDTH = 32,
    parameter FP_WIDTH   = 24,
    parameter KP = 1*(2 ** FP_WIDTH),
    parameter KI = 1*(2 ** FP_WIDTH),
    parameter TIME_STEP = 335  // 1/50e3
) 
(
    input wire Clk,
    input wire Resetn,

    input wire clk_control,
    input signed [DATA_WIDTH-1:0] reference,  // --user input reference
    input signed [DATA_WIDTH-1:0] input_data, // --feedbac value from sensor
    output reg signed [DATA_WIDTH-1:0] out, out_temp,        // --output of controller
    output reg signed [DATA_WIDTH-1:0] outSat,        // --output of controller

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
`define FSM_STATE_5 		5 
`define FSM_STATE_6 		6 
`define FSM_STATE_7 		7 
`define FSM_STATE_8 		8 
`define FSM_STATE_9 		9 
`define FSM_STATE_10 		10 

//------------------------------------------------------------------------------
//----------- Registers Declarations -------------------------------------------
//------------------------------------------------------------------------------
reg [3:0] current_state; 

reg signed [DATA_WIDTH-1:0] error, error_sum, error_difference;
reg signed [DATA_WIDTH-1:0] old_data, old_error;
reg signed [2*DATA_WIDTH-1:0] p_temp, i_temp1, i_temp3, outSat_temp, error_sum_temp;
reg signed [DATA_WIDTH-1:0] p, i, i_temp2;

reg signed [DATA_WIDTH-1:0] out_max, out_min,unsigned_outSat_temp;


initial begin
    out_max = 105414357; // 2pi
    out_min = 4189552939; // -2pi
    error_sum = 0;
    error_sum_temp = 0;

end
//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------


always @(posedge Clk)  //cs_n
	if ( ! Resetn ) begin 
        current_state <= `FSM_STATE_IDLE; 
		error_sum <= 0;
        error_sum_temp <= 0;
        error_difference <= 0;
        error <= 0;
        old_error <= 0;
        p <= 0;
        i <= 0;       
        old_data <= 0;
        p_temp <= 0;
        i_temp1 <= 0;
        i_temp2 <= 0;
        i_temp3 <= 0;
        out <= 0;
        outSat <= 0;
        out_data_valid <=0;
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
            out_data_valid <=0;
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
            error <= reference - input_data;
            current_state <=  `FSM_STATE_2;
        end

        `FSM_STATE_2: begin
            
             error_sum_temp  <= (error * TIME_STEP);
			
            current_state <=  `FSM_STATE_3;
        end

        `FSM_STATE_3: begin
            if(error_sum_temp === 64'bXXXXXXXXXXXXXXXX)
                error_sum <= 0;
            else                
                error_sum <= (error_sum_temp >> DATA_WIDTH) + error_sum; // integral
            p_temp <= (KP * error); 
            current_state <=  `FSM_STATE_4;
        end

        `FSM_STATE_4: begin 
             p <= p_temp >> FP_WIDTH; // fixing size cal p
             i_temp1 <= (KI * error_sum);
             current_state <=  `FSM_STATE_5;
        end

        `FSM_STATE_5: begin    
            
            i_temp2 <= i_temp1 >> FP_WIDTH; // fixing size i_temp2                        
            current_state <=  `FSM_STATE_8;
        end

       
        `FSM_STATE_6: begin   

            i_temp3 <= i_temp2 * TIME_STEP;
            
            
            current_state <=  `FSM_STATE_7;
        end

        `FSM_STATE_7: begin
            i <=  i_temp3 >> FP_WIDTH;
            current_state <=  `FSM_STATE_8;
        end

        `FSM_STATE_8: begin
            out_temp <= p + i;
            current_state <=  `FSM_STATE_9;
        end

        `FSM_STATE_9: begin
            // fixing stranges ouput  
            if(out_temp === 32'bXXXXXXXX)
                out <= 0;
            else 
                out <= out_temp;

            
            current_state <=  `FSM_STATE_10;
        end

        `FSM_STATE_10: begin
            if( out > out_max)begin
                outSat <= out_max;
            end
            else if(out < out_min) begin
                outSat <= out_min;
            end
            else begin 
                outSat <= out;
            end
            
            //outSat <= outSat_temp >> DATA_WIDTH;

            old_data <= input_data; // --storing old data
            old_error <= error; // --storing old error for derivative term
            
            
            out_data_valid <= 1;
            current_state <=  `FSM_STATE_IDLE;
                
                
        end


        default: begin 
			current_state <= `FSM_STATE_IDLE;			
		end 
		endcase
		 
	end 

endmodule