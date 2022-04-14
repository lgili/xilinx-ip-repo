module iverilog_dump();
initial begin
    $dumpfile("axis_async_fifo_wrapper.fst");
    $dumpvars(0, axis_async_fifo_wrapper);
end
endmodule
