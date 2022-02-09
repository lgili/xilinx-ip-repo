module iverilog_dump();
initial begin
    $dumpfile("ad7276_v1_m_axis.fst");
    $dumpvars(0, ad7276_v1_m_axis);
end
endmodule
