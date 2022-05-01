module iverilog_dump();
initial begin
    $dumpfile("axi_dma_wrapper.fst");
    $dumpvars(0, axi_dma_wrapper);
end
endmodule
