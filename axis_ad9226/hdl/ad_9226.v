`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2021 20:00:06
// Design Name: 
// Module Name: ad_9226
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module ad_9226#(

        parameter ADC_DATA_WIDTH = 12)
        (
        input clk,
        input rst_n,
        input clk_sample,
        input wire ready,
        //input wire clk_enable,
        output wire eoc,
        input wire  [ADC_DATA_WIDTH-1:0] data_in0,
        input wire  [ADC_DATA_WIDTH-1:0] data_in1,
        input wire  [ADC_DATA_WIDTH-1:0] data_in2,
        input wire  [ADC_DATA_WIDTH-1:0] data_in3,
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
/*always @(posedge clk)
    begin
        if(clk_enable == 0)
            lambda <= 0;
        else
            lambda <= clk_sample; 
           
    end
    */
// FSM Sequential Behaviour
    always @(posedge clk)
    begin
        if(rst_n == 0)
            fsm_cs <= HIGH;
        else
            fsm_cs <= fsm_ns; 
           
    end
    
    
    // FSM Combinational Behaviour
    always @(fsm_cs,lambda)
    begin
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
    always @(posedge clk)
    begin
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
    assign eoc = flag;
endmodule
