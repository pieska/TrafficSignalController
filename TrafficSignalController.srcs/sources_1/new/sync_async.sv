module sync_async
#(
    parameter int STAGES = 2,
    parameter logic RST_TO = 0
)
(
    input logic clk,
    input logic rst_n,
    input logic async_in,
    output logic sync_out
);

    timeunit 1ns/1ns;

    // check parameter
    generate
        if (STAGES < 2) $fatal(0, "STAGES < 2");
    endgenerate

    // https://docs.xilinx.com/r/en-US/ug912-vivado-properties/ASYNC_REG
    (* ASYNC_REG = "TRUE" *) logic [STAGES-1:0] sync_ff;

    always_ff @(posedge clk, negedge rst_n)
    begin
        if(!rst_n)
            sync_ff <= {STAGES{RST_TO}}; // reset to RST_TO, // STAGES'(RST_ACTIVE) sets onl y1 bit
        else
            sync_ff <= {sync_ff[STAGES - 2 : 0], async_in};
    end    

    assign sync_out = sync_ff[STAGES - 1];
        
    // async_in chnanges -> 2 cycles -> sync_out changes to async_in    
    property async_in_sync_out;
        @(posedge clk)
        disable iff (!rst_n)
        $changed(async_in) |=> ##1 ($changed(sync_out) && sync_out == async_in);
   endproperty
   
   assert property(async_in_sync_out);

endmodule: sync_async
