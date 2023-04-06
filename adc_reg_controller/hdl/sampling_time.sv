`timescale 1ns / 1ps

module sampling_time(
    input [4:0] scale_in,
    output wire [31:0] time_sampling
    );
    
    logic [31:0] time_out;
    
    assign time_sampling = time_out;
    
    always_comb begin
        case(scale_in)
            1:  time_out =        4;//25MHz
            2:  time_out =        6;//16.6
            3:  time_out =        10;//10
            4:  time_out =       100;//1
            5:  time_out =       200;//500khz
            6:  time_out =       1000;//100
            7:  time_out =      2000;//50
            8:  time_out =      10000;//10
            9:  time_out =      20000;//5
            10:  time_out =    100000;//1
            11:  time_out =    200000;//500Hz
            12:  time_out =    400000;//200m
            13:  time_out =   1000000;//500m
            14:  time_out =   2000000;//1
            15:  time_out =   4000000;//2
            16:  time_out =  10000000;//5
            default:  time_out =  10000;//1
        endcase
    end
    
endmodule
