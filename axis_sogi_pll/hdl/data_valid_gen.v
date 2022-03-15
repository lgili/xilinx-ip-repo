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


module data_valid_gen
(
    input wire Clk,
    input wire clk_control,
    input wire Resetn,

    output reg out_data_valid,
    input wire  out_data_ready

);
//------------------------------------------------------------------------------
//----------- Local Parameters -------------------------------------------------
//------------------------------------------------------------------------------


`define FSM_STATE_IDLE		0 
`define FSM_STATE_1  		1 


reg [1:0] state;

//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------


always @(posedge Clk)  
	if ( ! Resetn ) begin 
        out_data_valid <= 0;
        state <= 0;
    end
    else begin
    
        case(state)
        `FSM_STATE_IDLE: begin
            out_data_valid <=0;

            if(clk_control && out_data_ready) begin 			   
                state <=  `FSM_STATE_1;                
            end   
            else begin
                state <=  `FSM_STATE_IDLE;
            end 

        end
         `FSM_STATE_1: begin
            if(!clk_control) begin 
                out_data_valid <=1;
                state <=  `FSM_STATE_IDLE;
            end  
        end

        default: begin 
			state <= `FSM_STATE_IDLE;			
		end 
		endcase
    
       
    end



endmodule
