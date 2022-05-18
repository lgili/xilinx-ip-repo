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
    input wire  [ADC_DATA_WIDTH-1:0] data_in,  

    /*
     * ADC ouput
     */
    (* mark_debug = "true", keep = "true" *) 
    output wire [ADC_DATA_WIDTH-1:0] data_out,  

    /*
     * ADC config
     */   
    input wire  [31:0] configAdc
       
        
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

wire [ADC_DATA_WIDTH-1:0] offsetUsed;
reg [5:0] waitCycles = 4;
reg [31:0] countCycles;

reg signed [ADC_DATA_WIDTH-1:0] signed_data_out;


assign offsetUsed = (configAdc[31] == 1) ? configAdc[30:0] : 0;
assign data_out = signed_data_out;

 
initial begin 
    fsm_cs   = HIGH;
    fsm_ns   = HIGH;    
end 

// Clock enable  
always @(posedge clk) begin
    eoc <= flag;           
end
   
// FSM Sequential Behaviour
always @(posedge clk) begin
    if(rst_n == 0) begin
        fsm_cs <= HIGH;
        countCycles <= 0;
    end    
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
            //flag <= 1;
            if (lambda == 1) begin
                fsm_ns <= HIGH;
                // fix glitch on firsts clock off reading
                if(countCycles <= waitCycles)begin
                    countCycles <= countCycles + 1;
                end
                else 
                    flag <= 1;
            end        
            else
                fsm_ns <= LOW;  
        end          
    endcase
end
    
// Update Sample Register
always @(negedge clk) begin
    if (rst_n == 0) begin // zera saidas em reset
        signed_data_out <= 12'h0;         
    end
    else if (sigma == 1) begin
        if(ready == 1) begin
            signed_data_out <= data_in - offsetUsed;             
        end
        else begin
            signed_data_out <= 0;             
        end
    end                 
end


endmodule



