module debounce
#(
    parameter int STABLE_TICKS = 5_000_000  // should be 20-50ms, <debouncetime in ms>/(1/clk*1000)
)
(
    input logic clk,
    input logic rst_n,
    input logic raw_in,
    output logic debounced_out
);

    timeunit 1ns/1ns;
  
    logic last_raw_in;
    int unsigned counter;
    
    always_ff @(posedge clk, negedge rst_n)
    begin
        if(!rst_n)
        begin
            last_raw_in <= 0;
            debounced_out <= 0;
            counter <= STABLE_TICKS;
        end else
            if(last_raw_in == raw_in)   // transition?
                // no, long enough stable?
                if(counter == 0)
                    debounced_out <= raw_in;    // yes, set out
                else
                   counter <= counter - 1;  // no, wait
            else
            begin
                // yes, reset counter
                last_raw_in <= raw_in;
                counter <= STABLE_TICKS;
            end
    end

    // raw_in chnanges -> raw_in stable next STABLE_TICKS -> debounced_out changes to raw_in    
    property stable_raw_in_debounced_out;
        @(posedge clk)
        disable iff (!rst_n)
        $changed(raw_in) ##1 $stable(raw_in)[*STABLE_TICKS + 1] |=> ($changed(debounced_out) && debounced_out == raw_in);
   endproperty
   
   assert property(stable_raw_in_debounced_out);

endmodule: debounce
