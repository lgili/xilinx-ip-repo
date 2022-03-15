module iverilog_dump();
initial begin
    $dumpfile("qmath.fst");
    $dumpvars(0, qmath);
end
endmodule
