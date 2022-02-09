
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

module spi_rx #(
    parameter ADC_LENGTH = 12,
    parameter ADC_QTD = 3
)(
    input 		                    i_clk,
    input 		                    i_rst,    
    input  wire  [1:0]              i_data,    
    output reg [2*ADC_LENGTH-1:0]   o_data,  
        
    output reg                    o_cs,
    output wire                   o_sclk,

    input        [31:0]          i_sampleEnableDiv,
    output wire  [31:0]          o_clockdivReg,
        
    output  reg  [1:0]            o_tValid,    
    output  reg  [1:0]            o_tLast    

);
    
    // Define our states   
   parameter IDLE      = 'd0;
   parameter READING   = 'd1;
   parameter ENDING    = 'd2;

   parameter sizeAdcHalf = ADC_QTD/2;
   
   reg [1:0]  next_state = IDLE ;
   
   
   reg [31:0] sampleCount = 0;
   reg [31:0] sample_compare_value;
   
   wire sampleDone;
   reg [1:0]  current_state = IDLE;
   reg [3:0] count = 0;
   
   
   assign o_sclk = i_clk;
   
      
   //assign sample_compare_value = (i_sampleEnableDiv == 0) ? 'd48 : i_sampleEnableDiv;
   assign o_clockdivReg = sample_compare_value;  
   
   
always @(*) begin
    case (i_sampleEnableDiv)
        50: begin
            sample_compare_value = 50;
        end 
        100: begin
            sample_compare_value = 100;
        end
        150: begin
            sample_compare_value = 150;
        end
        200: begin
            sample_compare_value = 200;
        end
        250: begin
            sample_compare_value = 250;
        end 
        300: begin
            sample_compare_value = 300;
        end 
        350: begin
            sample_compare_value = 350;
        end 
        400: begin
            sample_compare_value = 400;
        end
        default: begin
            sample_compare_value = 48;
        end
    endcase
     
 end     
   
// sample rate generation
always @(posedge i_clk)
  begin
	if(i_rst == 1'b0) begin
           sampleCount <= 'd0;
	end
	else begin
           // Reset at state transition
           if (sampleDone) 
              sampleCount <= 'd0;           
           else 
              sampleCount <= sampleCount + 'd1;           
	end
end

// sample is done
assign sampleDone = (sampleCount == sample_compare_value-1) ? 1'b1 : 1'b0;
   
    
    
// update next state    
always @(posedge i_clk)
 begin
        if(i_rst == 1'b0) begin
               current_state <= IDLE;
        end
        else begin
               current_state <= next_state;
        end

 end
   
   
// update next state    
always @(posedge i_clk)
 begin
        if(i_rst == 1'b0) begin
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
            if(count == 15)
                next_state = ENDING;
            else
                next_state  = READING;
      end       
         
      ENDING :
            next_state = IDLE;  
    
    endcase        

end


// process data based on current state
reg [ADC_LENGTH+1:0] data_temp1 ;
reg [ADC_LENGTH+1:0] data_temp2 ;
reg [ADC_LENGTH-1:0] data_temp1_last ;
reg [ADC_LENGTH-1:0] data_temp2_last ;

/*reg signed [ADC_LENGTH-1:0] error1 ;
reg signed [ADC_LENGTH-1:0] error2 ;
reg inrange1;
reg inrange2;*/

integer i;

always @(posedge i_clk) begin

    case (current_state)
        IDLE   :   begin
                  o_cs <= 1'b1; 
                  data_temp1 <= 12'd0;
                  data_temp2 <= 12'd0;
                  
                  o_tValid <= 2'h0; 
                  o_tLast <= 2'h0;                                       
                            
        end
        READING :   begin
                  o_cs <= 1'b0;
                                         
                  o_tValid <= 2'h0; 
                  o_tLast <= 2'h0;                      
                       
                   
                  
                   if(count == 15)
                        count <= 0;
                   else
                        count <= count + 1;              
               
                 
                    data_temp1 <= {data_temp1[12:0], i_data[0]};
                    data_temp2 <= {data_temp2[12:0], i_data[1]};
             
        end
        
        ENDING :    begin
                
                 o_tValid <= 2'h3; 
                  o_tLast <= 2'h3;
                 
                 o_cs <= 1'b1;
                 
                 
                 /*error1 <= data_temp1 - data_temp1;    
                 if(error1 > -12'd100 && error1 < 12'd100)     
                    inrange1  = 1'b1;
                 else
                    inrange1 = 1'b0;           
                 error2 <= data_temp2 - data_temp2;
                 if(error2 > -12'd100 && error2 < 12'd100)     
                    inrange2  = 1'b1;
                 else
                    inrange2 = 1'b0;*/
                    
//most significant bit of data_temp1 is a zero
//two least significant bits of data_temp1 are zero
//the rest of the bits make up the 12-bit sample   

                 //data_temp1 >=  12'b0000_0000_1111 &&
                 //if( data_temp1 <=  12'b1111_1111_1111)
                    o_data[11:0] <= data_temp1[12:1];
                 //if(data_temp2 <=  12'b1111_1111_1111)   
                    o_data[23:12] <= data_temp2[12:1];
                    
                    //data_temp1_last <= data_temp1;
                    //data_temp2_last <= data_temp2;
               
                
                              
         end
        
        
    endcase     


end









endmodule
