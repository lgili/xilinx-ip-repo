module iverilog_dump();
initial begin
    $dumpfile("sample_generator_v2_0.fst");
    $dumpvars(0, sample_generator_v2_0);
end
endmodule
