program sync_async_tb(
    input logic clk,
    output logic rst_n_tb,
    output logic async_in_tb
);

    timeunit 1ns/1ps;

    // apply stimulus
    initial
    begin
        #3 rst_n_tb = 0; async_in_tb = 0;
        #7 rst_n_tb = 1;

        #12 async_in_tb = 1;
        #22 async_in_tb = 0;
        #20 async_in_tb = 1;
        
        #50 $finish;
    end

endprogram: sync_async_tb
