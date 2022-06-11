`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/08/2022 05:43:56 AM
// Design Name: 
// Module Name: seno
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


module display(
    
    input ENABLE,   
    input [30:0] COMPARE,
    input [11:0] ADC_1_DATA_INPUT,
    input [11:0] ADC_2_DATA_INPUT,
    input [11:0] ADC_3_DATA_INPUT,
    input CLK,
    output reg [31:0] ADC_1_DATA_OUTPUT,
    output reg [31:0] ADC_2_DATA_OUTPUT,
    output reg [31:0] ADC_3_DATA_OUTPUT,
    output reg [1:0] NEW_DATA 

    );


     reg [30:0] count; 
     reg [31:0] adc_1_media;
     reg [31:0] adc_2_media;
     reg [31:0] adc_3_media;
     reg [31:0] adc_div;
     reg [31:0] adc_acc;     
 

 initial begin
        adc_acc = 128;      // parâmetros internos para média 
        adc_div = 7;        // ...
    end
    
    
    always @(posedge CLK)
	begin
	  if (!ENABLE)
	    begin
	      count <= 0;
	      ADC_1_DATA_OUTPUT <= 0;
	      ADC_2_DATA_OUTPUT <= 0;
	      ADC_3_DATA_OUTPUT <= 0;
	      NEW_DATA <= 2'b0;
	      adc_1_media <= 0;
	      adc_2_media <= 0;
	      adc_3_media <= 0;
	    end 
	  else
	    begin    
  
          if (count < 128)
          begin
            adc_1_media <= adc_1_media + {20'd0, ADC_1_DATA_INPUT};  
            adc_2_media <= adc_2_media + {20'd0, ADC_2_DATA_INPUT}; 
            adc_3_media <= adc_3_media + {20'd0, ADC_3_DATA_INPUT}; 
	        count <= count+1;
          end 
          else if (count == 128)
          begin
            adc_1_media <= adc_1_media >> 7;  
            adc_2_media <= adc_2_media >> 7;
            adc_3_media <= adc_3_media >> 7; 
            count <= count + 1;    
          end                        
	      else if (count == COMPARE)
	      begin
	          NEW_DATA <= NEW_DATA + 1;
	          ADC_1_DATA_OUTPUT <= adc_1_media;           // register read data
	          ADC_2_DATA_OUTPUT <= adc_2_media;     // register read data
	          ADC_3_DATA_OUTPUT <= adc_3_media;     // register read data
	          count <= 0;
              adc_1_media = 0;
	         adc_2_media = 0;
	        	adc_3_media = 0;
	      end 	      
	    //   else if (count > COMPARE)  begin
	    //   		adc_1_media <= 0;
	    //     	adc_2_media <= 0;
	    //     	adc_3_media <= 0;
	    //     	count <= 0;
	    //   end 	      
	      else
	      begin
	        count <= count + 1;
	      end 
    
	    end
	end    
	// User logic ends
    

endmodule
