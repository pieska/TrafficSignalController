module top_debounce_tb;

    timeunit 1ns/1ps;

    localparam TICKS = 5;
    localparam JITTER_LEN = 25;

    logic clk_tb, rst_n_tb, raw_in_tb, debounced_out;

    debounce #(.STABLE_TICKS(TICKS)) dut0(.clk(clk_tb), .rst_n(rst_n_tb), .raw_in(raw_in_tb), .debounced_out(debounced_out));

    // testbench
    debounce_tb #(.JITTER_LEN(JITTER_LEN)) tb(.clk(clk_tb), .debounced_out(debounced_out), .rst_n_tb(rst_n_tb), .raw_in_tb(raw_in_tb));

    // Set up clock
    initial
    begin
        clk_tb = 0;
        forever #5 clk_tb = ~clk_tb;
    end

    // Set up monitor
    initial
        $monitor($stime, " : clk_tb = %b rst_n_tb = %b raw_in_tb = %b debbounced_out = %b", clk_tb, rst_n_tb, raw_in_tb, debounced_out);
    
endmodule: top_debounce_tb
