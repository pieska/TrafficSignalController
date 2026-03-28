module top_sync_async_tb;

    timeunit 1ns/1ps;

    logic clk_tb;
    logic rst_n_tb;
    logic async_in_tb;
    logic sync_out;

    // reset synchronizer
    sync_async dut0(.clk(clk_tb), .rst_n(rst_n_tb), .async_in(async_in_tb), .sync_out(sync_out));

    // testbench
    sync_async_tb tb(.clk(clk_tb), .rst_n_tb(rst_n_tb), .async_in_tb(async_in_tb));

    // Set up clock
    initial
    begin
        clk_tb = 0;
        forever #5 clk_tb = ~clk_tb;
    end

    // Set up monitor
    initial
        $monitor($stime, " : clk_tb = %b rst_n_tb = %b async_in = %b sync_out = %b", clk_tb, rst_n_tb, async_in_tb, sync_out);
    
endmodule: top_sync_async_tb
