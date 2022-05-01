module iverilog_dump();
initial begin
    $dumpfile("ad9226_wrapper.fst");
    $dumpvars(0, ad9226_wrapper);
end
endmodule
