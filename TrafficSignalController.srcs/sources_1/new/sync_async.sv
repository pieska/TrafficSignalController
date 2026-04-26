module sync_async
#(
    parameter int unsigned SYNC_STAGES = 2,
    parameter logic RST_TO = 0
)
(
    input logic clk,
    input logic rst_n,
    input logic async_in,
    output logic sync_out
);

    timeunit 1ns/1ps;

    // check parameter
    generate
        if (SYNC_STAGES < 2) $fatal(0, "STAGES < 2");
    endgenerate

    // https://docs.xilinx.com/r/en-US/ug912-vivado-properties/ASYNC_REG
    (* ASYNC_REG = "TRUE" *) logic [SYNC_STAGES-1:0] sync_ff;

    always_ff @(posedge clk, negedge rst_n)
    begin
        if(!rst_n)
            sync_ff <= {SYNC_STAGES{RST_TO}}; // reset to RST_TO, // STAGES'(RST_ACTIVE) sets onl y1 bit
        else
            sync_ff <= {sync_ff[SYNC_STAGES - 2 : 0], async_in};
    end    

    assign sync_out = sync_ff[SYNC_STAGES - 1];

    /*
    ** asserts
    */
    
    // After raw_in is stable for SYNC_STAGES cycles, raw_in_sync must follow
    property async_in_sync_out;
       @(posedge clk)
        disable iff (!rst_n)
        $changed(async_in) |-> ##SYNC_STAGES (sync_out == $past(async_in, SYNC_STAGES));
    endproperty
   
   assert property(async_in_sync_out);

endmodule: sync_async
