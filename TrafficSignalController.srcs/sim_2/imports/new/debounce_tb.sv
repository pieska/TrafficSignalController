program debounce_tb
#(
    parameter int JITTER_LEN = 25  // should be 20-50ms, <debouncetime in ms>/(1/clk*1000)
)
(
    input logic clk,
    input logic debounced_out,
    output logic rst_n_tb,
    output logic raw_in_tb
);

    timeunit 1ns/1ps;

    logic raw_in_array_tb[JITTER_LEN];
    
    // apply stimulus
    initial
    begin
        #0 rst_n_tb = 0;
        #200 rst_n_tb = 1;

        // create test vector starting with 0 and ending with 1 and 25% 1'b1
        assert(std::randomize(raw_in_array_tb) with {
/*
    funktioniert mit dynamischen arrays, die sind aber nicht traceable
            raw_in_array_tb.size() == JITTER_LEN;
*/
            raw_in_array_tb[JITTER_LEN - 1] == 1;
            foreach (raw_in_array_tb[i]){
                raw_in_array_tb[i] dist { 0 := 1, 1 := 1 };
            }
        });
        
        // assign textvector with random delay
        foreach(raw_in_array_tb[i])
            #($urandom_range(3,7)) raw_in_tb = raw_in_array_tb[i];

        wait(debounced_out == 'b1);
        #10 $finish;
        
    end

endprogram: debounce_tb
