module debounce
#(
    parameter int unsigned STABLE_TICKS = common::ms_to_ticks(50),  // should be 20-50ms
    parameter int unsigned SYNC_STAGES = 2
)
(
    input logic clk,
    input logic rst_n,
    input logic raw_in,
    output logic debounced_out
);

    timeunit 1ns/1ps;

    logic raw_in_sync;
    logic last_raw_in;
    int unsigned counter;
    
    sync_async #(.SYNC_STAGES(SYNC_STAGES)) sa(.clk(clk), .rst_n(rst_n), .async_in(raw_in), .sync_out(raw_in_sync));

    always_ff @(posedge clk, negedge rst_n)
    begin
        if(!rst_n)
        begin
            last_raw_in <= 0;
            debounced_out <= 0;
            counter <= STABLE_TICKS;
        end else
            if(last_raw_in == raw_in_sync)   // transition?
                // no, long enough stable?
                if(counter == 0)
                    debounced_out <= raw_in_sync;    // yes, set out
                else
                   counter <= counter - 1;  // no, wait
            else
            begin
                // yes, reset counter
                last_raw_in <= raw_in_sync;
                counter <= STABLE_TICKS;
            end
    end

    /*
    ** asserts
    */

    // raw_in changes -> raw_in stable for SYNC_STAGES + STABLE_TICKS -> debounced_out changes to raw_in
    property stable_raw_in_debounced_out;
        @(posedge clk)
        disable iff (!rst_n)
        $changed(raw_in) ##1 $stable(raw_in)[*SYNC_STAGES+STABLE_TICKS] |=> ##1 (debounced_out == raw_in);
   endproperty
   
   assert property(stable_raw_in_debounced_out);

endmodule: debounce
