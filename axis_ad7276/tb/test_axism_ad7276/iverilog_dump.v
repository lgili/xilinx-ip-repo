module iverilog_dump();
initial begin
    $dumpfile("adc_7276.fst");
    $dumpvars(0, adc_7276);
end
endmodule
