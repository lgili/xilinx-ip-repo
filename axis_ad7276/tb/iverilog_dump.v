module iverilog_dump();
initial begin
    $dumpfile("ad7276_wrapper.fst");
    $dumpvars(0, ad7276_wrapper);
end
endmodule
