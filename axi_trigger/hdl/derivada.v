`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2022 12:59:33 PM
// Design Name: 
// Module Name: derivada
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


module derivada
    (
    input MOD_ENABLED,
    input CH_ENABLED,
    input [11:0] ADC_DATA,
    input CLK,
    input RST,
    input signed [31:0] USER_DV,
    input [31:0] USER_DT,
    output reg signed [31:0] MAX_DV,
    output reg TRIGGED,
    output reg TRIG_EDGE
    );

    reg [31:0] count;
    reg signed [31:0] adc_past;
    reg signed [31:0] adc_dv;

    wire signed [31:0] adc_input;
    assign adc_input = {20'b0, ADC_DATA};


     always @( posedge CLK ) begin
      if (!RST  || !MOD_ENABLED) begin
          count <= 0;     
          adc_past <= 0;
          TRIGGED <= 0; 
          MAX_DV <= 0;
      end 
      else if (!TRIGGED) begin
        
        if (count == 1) begin       
          adc_past <= adc_input;
          count <= count + 1;                                           
        end   
        else if (count == USER_DT) begin
            adc_dv <= adc_input - adc_past;
            count <= count + 1;            
        end       
        else if (count > USER_DT) begin
            
            if (adc_dv > MAX_DV) MAX_DV = adc_dv;         // Encontra a maior derivada, seja positiva ou negativa
            else if (adc_dv < -MAX_DV) MAX_DV = -adc_dv;

            if ((adc_dv > USER_DV) && (CH_ENABLED))  begin     // se o módulo está ativado, verifica se o deltaV passou max DV                
              TRIGGED <= 1'b1;  // trigou
              TRIG_EDGE <= 1'b1;  // borda subida
            end  
            else if ((adc_dv < -USER_DV) && (CH_ENABLED == 1'b1))  begin                      
              TRIGGED <= 1'b1;  // trigou
              TRIG_EDGE <= 1'b0;  // borda descida
            end            
            else begin
              count <= 0;
            end    
 
        end                  
        else begin
          count <= count + 1;
        end 

                         
      end

    end    





    
    
    
    
    
endmodule
