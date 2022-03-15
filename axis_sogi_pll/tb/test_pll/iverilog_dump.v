module iverilog_dump();
initial begin
    $dumpfile("pll.fst");
    $dumpvars(0, pll);
end
endmodule
