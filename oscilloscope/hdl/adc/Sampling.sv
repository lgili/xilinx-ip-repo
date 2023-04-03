`timescale 1 ns / 1 ps
`default_nettype none

module Sampling #(
    parameter DSIZE = 12,
	parameter ASIZE = 9,
    parameter reg_size = 2**ASIZE) (
    input wire rst_n,
    input wire CLK100MHz,
    input wire CLKADC,
    input wire trig_off,
    input wire [11:0] ch1_data,
    input wire [11:0] ch2_data,
    input wire ch1_en,
    input wire ch2_en,
    input wire ch1_couple,
    input wire ch2_couple,
    input wire [3:0] ch1_scale,
    input wire [3:0] ch2_scale,
    input wire [4:0] time_scale,
    input wire [9:0] trig,
    input wire [9:0] ch1_offset,
    input wire [9:0] ch2_offset,
    output reg [9:0] data_out_1 [reg_size - 1:0],
    output reg [9:0] data_out_2 [reg_size - 1:0],
    output reg clk_sampling,
    output wire sclk,
    output wire cs_n,

    output reg [DSIZE-1:0] data_out_ch1,
    output wire data_ready_ch1,
    input wire en_read,
    output reg TxD_start,
    input wire TxD_busy,
    input wire clk_reading
    );
    
    logic dis_en, ready1;//, clk_sampling;
    logic [1:0] reg_count;
    logic [7:0] clk_count;
    logic [9:0] trig_level;
    logic [9:0] data_reg [3:0];
    logic [15:0] data_count, data_ch1, data_ch2, out_count, sample_count;
    logic [31:0] data_cal_ch1, data_cal_ch2, data_tran, dis_count, time_sampling;
    // reg [11:0] adc0,adc1;
    assign trig_level = trig;

    
    // ad7276_if adc (
    //     //clock and reset signals
    //     .fpga_clk_i(CLK100MHz),
    //     .adc_clk_i(CLKADC),
    //     .reset_n_i(rst_n),
            
    //     //IP control and data interface
    //     .en_0_i(ch1_en),
    //     .en_1_i(ch2_en),        
    //     .data_rdy_o(ready1),
    //     .data_0_o(adc0),
    //     .data_1_o(adc1),
            
    //     //ADC control and data interface
    //     .data_0_i(ch1_data),
    //     .data_1_i(ch2_data),
    //     .sclk_o(sclk),
    //     .cs_o(cs_n)    
    // ); 

    always @(posedge CLK100MHz, negedge rst_n) begin
        if(~rst_n) dis_count <= 0;
        else begin
            dis_count <= dis_count + 1;
            if(dis_count >= time_sampling) dis_count <= 0;
        end
    end
    
    assign clk_sampling = (dis_count <= time_sampling/2);
    
    always @(posedge clk_sampling) begin         
        data_ch1 <= ch1_data;           
        data_ch2 <= ch2_data;      
    
    end

    always @(posedge CLK100MHz, negedge rst_n) begin
        if(~rst_n) begin
            reg_count <= 0;
        end else begin
            if(dis_count == 0) begin
                data_reg[reg_count] <= data_cal_ch1;
                reg_count <= reg_count - 1;
            end
        end
    end
    
    always @(posedge CLK100MHz, negedge rst_n) begin
        if(~rst_n) begin
            dis_en <= 0;
        end else begin
            if(data_reg[0] <= trig_level & data_reg[1] <= trig_level & data_reg[2] >= trig_level & data_reg[3] >= trig_level &
                data_reg[0] <= data_reg[1] & data_reg[1] <= data_reg[2] & data_reg[2] <= data_reg[3]) dis_en <= 1;
            else if(~rst_n | data_count >= reg_size - 1)  dis_en <= 0;
        end
    end

   
    always @(posedge clk_sampling, negedge rst_n) begin
        if(~rst_n) begin
            data_count <= 0;           
        end    
        else if((dis_en | trig_off) && r_is_empty) begin
            data_out_1[data_count] <= data_cal_ch1;
            data_out_2[data_count] <= data_cal_ch2;
            
            if(data_count >= reg_size - 1) begin
                data_count <= 0;                
            end
            else data_count <= data_count + 1;
        end
    end
    
    Data_transfer ch1_data_transfer(.couple_in(ch1_couple), .offset_in(ch1_offset), .scale_in(ch1_scale), .data_in(data_ch1), .data_out(data_cal_ch1));
    Data_transfer ch2_data_transfer(.couple_in(ch2_couple), .offset_in(ch2_offset), .scale_in(ch2_scale), .data_in(data_ch2), .data_out(data_cal_ch2));
    Sampling_time sampling_time(.scale_in(time_scale), .time_sampling);
    


    ///////////////////////////////////////////////////////////////////////////////////
    reg [ASIZE-1:0] wraddress;
    reg [ASIZE-1:0] rdaddress;
    reg [ASIZE-1:0] wraddress_triggerpoint;
    reg [ASIZE-1:0] SendCount;
    reg [ASIZE-1:0] samplecount;
    reg r_is_empty, w_is_full;
    reg Threshold1, Threshold2;
    wire Trigger;
    reg startAcquisition, startAcquisition1, startAcquisition2;
    reg Acquiring,Acquiring1,Acquiring2;
    reg Sending;
    wire AcquisitionStarted;
    reg PreOrPostAcquiring, AcquiringAndTriggered;
    always@(posedge clk_sampling) begin 
        if ( !rst_n) begin 
            startAcquisition <= 0;
            startAcquisition1 <= 0;
            startAcquisition2 <= 0;
            Acquiring <= 0;
            Acquiring1 <= 0;
            Acquiring2 <= 0;
            wraddress <= 0;
            rdaddress <= 0;
            samplecount <= 0;
            wraddress_triggerpoint <= 0;
            SendCount <= 0;
            Sending <= 0;
            PreTriggerPointReached <=0;
            AcquiringAndTriggered <= 0;
            Threshold1 <= 0;
            Threshold2 <= 0;
            // data_cal_ch1 <= 0;
        end 	
    end

    
    always @(posedge clk_sampling) 
    if(data_cal_ch1>=8'h80)
        Threshold1 <= 1;
    else 
        Threshold1 <= 0;    
    always @(posedge clk_sampling) Threshold2 <= Threshold1;

    assign Trigger = Threshold1 & ~Threshold2;  // if positive edge, trigger! 

    reg PreTriggerPointReached;
    
    always @(posedge clk_sampling) PreTriggerPointReached <= (samplecount==256);

    always @(posedge clk_reading)
    if(~startAcquisition)
    startAcquisition <= 1;
    // else
    //     if(AcquisitionStarted)
    //         startAcquisition <= 0;

    always @(posedge clk_sampling) startAcquisition1 <= startAcquisition ;
    always @(posedge clk_sampling) startAcquisition2 <= startAcquisition1;

    always @(posedge clk_sampling)
    if(~Acquiring)  begin
        Acquiring <= startAcquisition2;  // start acquiring?
        PreOrPostAcquiring <= startAcquisition2;
    end
    else
    if(&samplecount)  // got 511 bytes? stop acquiring
    begin
        Acquiring <= 0;
        AcquiringAndTriggered <= 0;
        PreOrPostAcquiring <= 0;
    end
    else
    if(PreTriggerPointReached)  // 256 bytes acquired already?
    begin
        PreOrPostAcquiring <= 0;
    end
    else
    if(~PreOrPostAcquiring)
    begin
        AcquiringAndTriggered <= Trigger;  // Trigger? 256 more bytes and we're set
        PreOrPostAcquiring <= Trigger;
        if(Trigger) wraddress_triggerpoint <= wraddress;  // keep track of where the trigger happened
    end

    always @(posedge clk_sampling) if(Acquiring) wraddress <= wraddress + 1;
    always @(posedge clk_sampling) if(PreOrPostAcquiring) samplecount <= samplecount + 1;

    always @(posedge clk_reading) Acquiring1 <= AcquiringAndTriggered;
    always @(posedge clk_reading) Acquiring2 <= Acquiring1;
    assign AcquisitionStarted = Acquiring2; 

    always @(posedge clk_reading)
    if(~Sending)
    begin
    Sending <= AcquisitionStarted;
    if(AcquisitionStarted) rdaddress <= (wraddress_triggerpoint ^ 9'h100);
    end
    else
    if(~TxD_busy)
    begin
    rdaddress <= rdaddress + 1;
    SendCount <= SendCount + 1;
    if(&SendCount) Sending <= 0;
    end

    reg rden;
    always @(posedge clk_reading) begin
        TxD_start <= ~TxD_busy & Sending;
        rden <= TxD_start;
    end
    // wire busy = ~TxD_busy;
    // TxD_start = busy & Sending;
    // wire rden = TxD_start;    

    async_fifo
	#(
		DSIZE,
		ASIZE
    )
    fifo
    (
		.wclk(clk_sampling),
		.wrst_n(rst_n),
		.winc(Acquiring),
		.wdata(data_cal_ch1), 
		.wfull(w_is_full),
		.awfull(),
		.rclk(clk_reading),
		.rrst_n(rst_n),
		.rinc(rden),
		.rdata(data_out_ch1),
		.rempty(r_is_empty),
		.arempty()
    );
endmodule

`resetall
