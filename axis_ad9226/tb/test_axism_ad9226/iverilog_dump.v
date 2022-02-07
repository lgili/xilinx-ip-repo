module iverilog_dump();
initial begin
    $dumpfile("ad9226_v1_m_axis.fst");
    $dumpvars(0, ad9226_v1_m_axis);
end
endmodule
