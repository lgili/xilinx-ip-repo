`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2021 03:23:09 PM
// Design Name: 
// Module Name: spi_rx
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


module spi_rx #(
    parameter ADC_LENGTH = 12
    )(
    input 		    clk,
    input 		    rst,    
    input           inData1,
    input           inData2,
    input  reg [31:0]   sampleEnableDiv,
    output reg [ADC_LENGTH-1:0]   adcData1,
    output reg [ADC_LENGTH-1:0]   adcData2,
    output reg         cs,
    output wire        sclk

    );
    
    // Define our states
   typedef enum {IDLE, READING, ENDING}  state;

   state current_state = IDLE;
   state next_state = IDLE ;
   reg [31:0] count = 0;
   
   reg [31:0] sampleCount = 0;
   reg [31:0] sample_compare_value;
   logic sampleDone;
   
   
   assign sample_compare_value = (sampleEnableDiv == 0) ? 'd48 : sampleEnableDiv;
   
   assign sclk  = clk;
   
// sample rate generation
always @(posedge clk)
  begin
	if(rst == 1'b0) begin
           sampleCount <= '0;
	end
	else begin
           // Reset at state transition
           if (sampleDone) 
              sampleCount <= '0;           
           else 
              sampleCount <= sampleCount + 'd1;           
	end
end

// sample is done
assign sampleDone = (sampleCount == sample_compare_value-1) ? 1'b1 : 1'b0;
   
    
    
// update next state    
always @(posedge clk)
 begin
        if(rst == 1'b0) begin
               current_state <= IDLE;
        end
        else begin
               current_state <= next_state;
        end

 end
   
   
// find next state   
always @(*) begin
    
    case (current_state)
      IDLE   :   begin
            if(sampleDone)
                next_state  = READING;
            else
                next_state  =  IDLE;    
        end   
        
      READING :  begin
            if(count == 13)
                next_state = ENDING;
            else
                next_state  = READING;
      end       
         
      ENDING :
            next_state = IDLE;  
    
    endcase        

end


// process data based on current state
reg [ADC_LENGTH:0] data_temp1;
reg [ADC_LENGTH:0] data_temp2; 
always @(*) begin

    case (current_state)
          IDLE   :   begin
                  cs = 1'b1;                   
                  //tValid1 <= 1'b0;  
                 // tValid2 <= 1'b0;             
                  //tLast1 <= 1'b0;                              
                 // tLast2 <= 1'b0;          
          end
          READING :   begin
                cs = 1'b0;   
                if(clk) begin               
                    if(count == 13)
                        count = 0;
                    else
                        count = count + 1;        
                 end  
                 
                if(~clk) begin
                    data_temp1 = {data_temp1[11:0], inData1};
                    data_temp2 = {data_temp2[11:0], inData2}; 
                
                end         
                  
          
          end
          ENDING :    begin
                cs = 1'b1;
                adcData1 = data_temp1;
                adcData2 = data_temp2;
          end
          
          
    endcase      
end
   
  

endmodule
