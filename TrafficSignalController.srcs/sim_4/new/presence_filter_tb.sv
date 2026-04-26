program presence_filter_tb(
    input  logic clk,
    output logic rst_n_tb,
    output logic raw_in_tb
);

    timeunit 1ns/1ps;

    initial
    begin
        // ---- Phase 0: Reset ----
        #3  rst_n_tb = 0; raw_in_tb = 0;
        #17 rst_n_tb = 1;                   // t=20:  Reset deassert

        // ---- Phase 1: sauberer rise (>= TICKS_HI stabil) ----
        #20 raw_in_tb = 1;                  // t=40:  raw_in steigt
                                            // t~110: filtered_out sollte 1 sein
        #120;                               // t=160: warten bis filtered=1

        // ---- Phase 2: kurzer Lo-Glitch (< TICKS_LO) ----
        raw_in_tb = 0;                      // t=160: raw_in fällt kurz
        #50 raw_in_tb = 1;                  // t=210: zurück, < 100ns → filtered bleibt 1
        #50;                                // t=260: noch stabil

        // ---- Phase 3: sauberer fall (>= TICKS_LO stabil) ----
        raw_in_tb = 0;                      // t=260: raw_in fällt
                                            // t~370: filtered_out sollte 0 sein
        #150;                               // t=410: warten bis filtered=0

        // ---- Phase 4: kurzer Hi-Glitch (< TICKS_HI) ----
        raw_in_tb = 1;                      // t=410: raw_in kurz hoch
        #30 raw_in_tb = 0;                  // t=440: zurück, < 50ns → filtered bleibt 0
        #30;                                // t=470

        // ---- Phase 5: nochmal sauberer rise zur Verifikation ----
        raw_in_tb = 1;                      // t=470: raw_in steigt
        #100;                               // t=570: filtered sollte wieder 1 sein

        #50 $finish;
    end

endprogram: presence_filter_tb