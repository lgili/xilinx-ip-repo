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

/*
 * Interface for the ADC ad9226
 */
module ad_9226#
(
    // Width of input and ouput in bits of the ADC
    parameter ADC_DATA_WIDTH = 12
)
(
    input wire clk,
    input wire rst_n,

    /*
     * CLK to adc sample
     */
    input wire clk_sample,

    // ADC ready and end of conversion status
    input wire ready,        
    output reg eoc,

    /*
     * ADC input
     */
    input wire  [ADC_DATA_WIDTH-1:0] data_in0,
    input wire  [ADC_DATA_WIDTH-1:0] data_in1,
    input wire  [ADC_DATA_WIDTH-1:0] data_in2,
    input wire  [ADC_DATA_WIDTH-1:0] data_in3,

    /*
     * ADC ouput
     */
    output reg [ADC_DATA_WIDTH-1:0] data_out0,
    output reg [ADC_DATA_WIDTH-1:0] data_out1,
    output reg [ADC_DATA_WIDTH-1:0] data_out2,
    output reg [ADC_DATA_WIDTH-1:0] data_out3
       
        
);

localparam HIGH =1;
localparam ACQ  =2;
localparam HOLD =3;
localparam LOW  =4;

reg [3:0] fsm_cs;
reg [3:0] fsm_ns;  
wire lambda;
reg sigma;
reg flag;   

assign lambda = clk_sample;
 
initial begin 
    fsm_cs   = HIGH;
    fsm_ns   = HIGH;    
end 

// Clock enable  
always @(negedge clk) begin
    eoc <= flag;           
end
   
// FSM Sequential Behaviour
always @(negedge clk) begin
    if(rst_n == 0)
        fsm_cs <= HIGH;
    else
        fsm_cs <= fsm_ns;         
end
    
    
// FSM Combinational Behaviour
always @(fsm_cs,lambda) begin
    sigma <= 0;
    flag  <= 0;
    
    case(fsm_cs)
    
    HIGH : 
            begin       
            if (lambda == 0)
                fsm_ns <= ACQ;
            else
                fsm_ns <= HIGH;
            end      
    ACQ:
        begin
            sigma <= 1;
            fsm_ns <= HOLD;
        end    
    HOLD:
        begin
            sigma <= 1;
            fsm_ns <= LOW;
        end   
    LOW:
        begin
            flag <= 1;
            if (lambda == 1)
                fsm_ns <= HIGH;
            else
                fsm_ns <= LOW;  
        end          
    endcase
end
    
// Update Sample Register
always @(negedge clk) begin
    if (rst_n == 0) begin // zera saidas em reset
        data_out0 <= 12'h0; 
        data_out1 <= 12'h0;
        data_out2 <= 12'h0;
        data_out3 <= 12'h0;
    end
    else if (sigma == 1) begin
        if(ready == 1) begin
            data_out0 <= data_in0; 
            data_out1 <= data_in1;
            data_out2 <= data_in2;
            data_out3 <= data_in3;
        end
        else begin
            data_out0 <= 0; 
            data_out1 <= 0;
            data_out2 <= 0;
            data_out3 <= 0;
        end
    end        
end

// Output Mapping
// End of Conversion (EOC)
//assign eoc = flag;
endmodule



