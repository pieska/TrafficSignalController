program sync_async_tb(
    input logic clk,
    output logic rst_n_tb
);

    timeunit 1ns/1ns;

    // apply stimulus
    initial
    begin
        #3 rst_n_tb = 0;
        #7 rst_n_tb = 1;

        #50 $finish;
    end

endprogram: sync_async_tb
