module top_presence_filter_tb;

    timeunit 1ns/1ps;

    logic clk_tb;
    logic rst_n_tb;
    logic raw_in_tb;
    logic filtered_out;

    presence_filter #(
        .TICKS_HI(5),
        .TICKS_LO(10)
    ) dut0 (
        .clk(clk_tb),
        .rst_n(rst_n_tb),
        .raw_in(raw_in_tb),
        .filtered_out(filtered_out)
    );

    // testbench
    presence_filter_tb tb(
        .clk(clk_tb),
        .rst_n_tb(rst_n_tb),
        .raw_in_tb(raw_in_tb)
    );

    initial
    begin
        clk_tb = 0;
        forever #5 clk_tb = ~clk_tb;
    end

    // Monitor
    initial
        $monitor($stime,
                 " : clk = %b  rst_n = %b  raw_in = %b  filtered_out = %b",
                 clk_tb, rst_n_tb, raw_in_tb, filtered_out);

endmodule: top_presence_filter_tb