module iverilog_dump();
initial begin
    $dumpfile("pwm_wrapper.fst");
    $dumpvars(0, pwm_wrapper);
end
endmodule
