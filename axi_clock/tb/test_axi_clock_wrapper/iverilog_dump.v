module iverilog_dump();
initial begin
    $dumpfile("axi_clock_wrapper.fst");
    $dumpvars(0, axi_clock_wrapper);
end
endmodule
