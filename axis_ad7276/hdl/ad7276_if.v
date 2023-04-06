
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

module ad7276_if
    (
        //clock and reset signals
        input           fpga_clk_i,
        input           adc_clk_i,
        input           reset_n_i,
        
        //IP control and data interface
        input           en_0_i,
        input           en_1_i,        
        output          data_rdy_o,
        output          data_clk,
        output  [11:0]  data_0_o,
        output  [11:0]  data_1_o,
        
        //ADC control and data interface
        input           data_0_i,
        input           data_1_i,
        output          sclk_o,
        output          cs_o
    );

//------------------------------------------------------------------------------
//----------- Registers Declarations -------------------------------------------
//------------------------------------------------------------------------------
reg [ 7:0]  adc_state; 
reg [ 7:0]  adc_next_state;
reg [ 7:0]  adc_state_m1;
reg [31:0]  adc_tcycle_cnt;
reg [31:0]  adc_tcs_cnt;  
reg [31:0]  sclk_cnt;
reg         data_rd_rdy_s;
reg         adc_cs_s;
reg [15:0]  data_0_s;
reg [15:0]  data_1_s;
reg         adc_clk_en;

//------------------------------------------------------------------------------
//----------- Local Parameters -------------------------------------------------
//------------------------------------------------------------------------------
localparam      ADC_IDLE_STATE      = 8'b00000001;
localparam      ADC_START_STATE     = 8'b00000010;
localparam      ADC_READ_STATE      = 8'b00000100;
localparam      ADC_DONE_STATE      = 8'b00001000;

localparam real FPGA_CLOCK_FREQ     = 100000000;
localparam real ADC_CYCLE_TIME      = 0.000001000; 
localparam real ADC_CS_TIME         = 0.000000020; 
localparam      ADC_CYCLE_CNT       = FPGA_CLOCK_FREQ * ADC_CYCLE_TIME - 1;
localparam      ADC_CS_CNT          = FPGA_CLOCK_FREQ * ADC_CS_TIME;
localparam      ADC_SCLK_PERIODS    = 16; 

//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------
assign sclk_o       = (adc_clk_en == 1'b1)&&(sclk_cnt >= 32'd0) ? adc_clk_i : 1'b1;
assign cs_o         =  adc_cs_s; 
assign data_0_o     = (data_rd_rdy_s == 1'b1) ? data_0_s[13:2] : data_0_o;
assign data_1_o     = (data_rd_rdy_s == 1'b1) ? data_1_s[13:2] : data_1_o;  
assign data_rdy_o   = data_rd_rdy_s && adc_clk_en; // (adc_cs_s == 1'b1 && adc_clk_en == 1'b1) ? 1'b1 : 1'b0;

always @(posedge fpga_clk_i)
begin
    if(reset_n_i == 1'b0)
    begin
        adc_tcycle_cnt  <= 32'd0;
        adc_tcs_cnt     <= ADC_CS_CNT;
    end
    else
    begin
        if(adc_tcycle_cnt != 32'd0)
        begin   
            adc_tcycle_cnt <= adc_tcycle_cnt - 32'd1;
        end
        else if(adc_state == ADC_IDLE_STATE)
        begin
            adc_tcycle_cnt <= ADC_CYCLE_CNT;
        end
        
        if(adc_state == ADC_START_STATE)
        begin
            adc_tcs_cnt <= adc_tcs_cnt - 32'd1;
        end
        else
        begin
            adc_tcs_cnt <= ADC_CS_CNT;
        end
    end
end

always @(negedge adc_clk_i)
begin
    if(adc_clk_en == 1'b1)
    begin
        sclk_cnt <= sclk_cnt - 32'd1;
        data_0_s <= {data_0_s[14:0], data_0_i};
        data_1_s <= {data_1_s[14:0], data_1_i};
    end
    else
    begin
        sclk_cnt <= ADC_SCLK_PERIODS;
    end
end

always @(posedge adc_clk_i)
begin
    adc_state_m1 <= adc_state;
    adc_clk_en   <= ((adc_state_m1 == ADC_READ_STATE) && (sclk_cnt != 0) && (adc_state != ADC_IDLE_STATE)) ? 1'b1 : 1'b0;    
end

always @(adc_state, adc_tcycle_cnt, adc_tcs_cnt, sclk_cnt)
begin
    adc_next_state <= adc_state;
    case(adc_state)
        ADC_IDLE_STATE:
            begin
                if(((en_0_i == 1'b1)||(en_1_i == 1'b1))&&(adc_tcycle_cnt == 32'd0))
                begin
                    adc_next_state <= ADC_START_STATE;
                end
            end
        ADC_START_STATE:
            begin
                if(adc_tcs_cnt == 32'd0)
                begin
                    adc_next_state <= ADC_READ_STATE;
                end
            end
        ADC_READ_STATE:
            begin                
                if(sclk_cnt == 32'd0)
                begin
                    adc_next_state <= ADC_DONE_STATE;
                end
            end
        ADC_DONE_STATE:
            begin
                adc_next_state <= ADC_IDLE_STATE;
            end
        default:
            begin
                adc_next_state <= ADC_IDLE_STATE;
            end
    endcase
end

always @(posedge fpga_clk_i)
begin
    if(reset_n_i == 1'b0)
    begin
        adc_state       <= ADC_IDLE_STATE;
        data_rd_rdy_s   <= 1'b0;
        adc_cs_s        <= 1'b1;
    end
    else
    begin
        adc_state <= adc_next_state;
        case(adc_state)
            ADC_IDLE_STATE:
                begin
                    data_rd_rdy_s   <= 1'b0;  
                    adc_cs_s        <= 1'b1;
                end
            ADC_START_STATE:
                begin
                    data_rd_rdy_s   <= 1'b0;
                    adc_cs_s        <= 1'b1;
                end
            ADC_READ_STATE:
                begin
                    data_rd_rdy_s   <= 1'b0;
                    adc_cs_s        <= 1'b0;
                end
            ADC_DONE_STATE:
                begin
                    data_rd_rdy_s   <= 1'b1;
                    adc_cs_s        <= 1'b0;
                end
            default:
                begin
                    data_rd_rdy_s   <= 1'b0;
                    adc_cs_s        <= 1'b1;
                end
        endcase
    end
end


assign data_clk = adc_clk_en;

endmodule
