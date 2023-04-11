module iverilog_dump();
initial begin
    $dumpfile("trafficgen_v1_0.fst");
    $dumpvars(0, trafficgen_v1_0);
end
endmodule
