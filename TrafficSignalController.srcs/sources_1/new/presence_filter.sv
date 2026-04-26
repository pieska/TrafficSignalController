module presence_filter
#(
    parameter int unsigned TICKS_HI = common::s_to_ticks(10),   // 10s until HI is declared stable
    parameter int unsigned TICKS_LO = common::s_to_ticks(20)    // 20s until LO is declared stable
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic raw_in,
    output logic filtered_out
);

    timeunit 1ns/1ps;

    int unsigned counter;

    always_ff @(posedge clk, negedge rst_n)
    begin
        if(!rst_n)
        begin
            filtered_out <= 'b0;
            counter      <= TICKS_LO;
        end else if(raw_in == filtered_out) // Eingang stimmt mit aktuellem Ausgang überein -> Zähler reset
        begin
            counter <= filtered_out ? TICKS_LO : TICKS_HI;
        end else if(counter == 0)   // lange genug stabil im neuen Zustand -> übernehmen
        begin
            filtered_out <= raw_in;
            counter      <= raw_in ? TICKS_LO : TICKS_HI;
        end else
        begin
            counter <= counter - 1;
        end
    end

    /*
    ** asserts
    */

    // Steigende Flanke: muss TICKS_HI stabil sein
    property presence_rise;
        @(posedge clk)
        disable iff (!rst_n)
        $rose(raw_in) ##1 raw_in[*TICKS_HI] |=> filtered_out == 'b1;
    endproperty
    
    assert property(presence_rise);

    // Fallende Flanke: muss TICKS_LO stabil sein
    property presence_fall;
        @(posedge clk)
        disable iff (!rst_n)
        $fell(raw_in) ##1 (!raw_in)[*TICKS_LO] |=> filtered_out == 'b0;
    endproperty
    
    assert property(presence_fall);

endmodule: presence_filter
