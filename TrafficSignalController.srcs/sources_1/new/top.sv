module top
(
	input logic GCLK,
	input logic BTNC,
	input logic BTND,
	input logic SW0,
    output logic LD0,   // cntryrd green
    output logic LD1,   // cntryrd yellow
    output logic LD2,   // cntryrd red
    output logic LD3,   // hwy green
    output logic LD4,   // hwy yellow
    output logic LD5,   // hwy red
    output logic LD7,   // failsafe
    
    // debug pins
    output logic JC1_P,
    output logic JC1_N,
    output logic JC2_P,
    output logic JC2_N,
    output logic JC3_P,
    output logic JC3_N,
    output logic JC4_P,
    output logic JC4_N
);

    timeunit 1ns/1ps;

    common::sig_colors_e hwy_sig, cntryrd_sig;
    logic rst_n;
    logic test_failsafe;
    logic car_on_cntryrd;
    logic car_on_cntryrd_stable;
    logic failsafe_entered;

    // reset synchronizer
    sync_async rs
    (
        .clk(GCLK),
        .rst_n(~BTNC),
        .async_in(~BTNC),
        .sync_out(rst_n)
    );

    // switch synchronizer
    debounce #(.STABLE_TICKS(common::ms_to_ticks(50))) sw_deb(
        .clk(GCLK),
        .rst_n(rst_n),
        .raw_in(SW0),
        .debounced_out(car_on_cntryrd)
    );
    
    // stable filter
    presence_filter #(.TICKS_HI(common::s_to_ticks(10)), .TICKS_LO(common::s_to_ticks(20))) pf_car_on_cntryrd(
        .clk(GCLK),
        .rst_n(rst_n),
        .raw_in(car_on_cntryrd),
        .filtered_out(car_on_cntryrd_stable)
    );

    // button synchronizer
    debounce #(.STABLE_TICKS(common::ms_to_ticks(50))) btnd_deb(
        .clk(GCLK),
        .rst_n(rst_n),
        .raw_in(BTND),
        .debounced_out(test_failsafe)
    );

    // signal controller
    sig_control #(.HOLD_FACTOR(common::s_to_ticks(1))) sc(
        .clk(GCLK),
        .rst_n(rst_n),
        .test_failsafe(test_failsafe),
        .hwy_sig(hwy_sig),
        .cntryrd_sig(cntryrd_sig),
        .car_on_cntryrd(car_on_cntryrd_stable),
        .failsafe_entered(failsafe_entered)
    );

    assign LD7 = failsafe_entered;

    assign {LD5, LD4, LD3} = hwy_sig;
    assign {LD2, LD1, LD0} = cntryrd_sig;

    // debug pins
    assign {JC4_N, JC4_P, JC3_N, JC3_P, JC2_N, JC2_P, JC1_N, JC1_P} = {BTNC, hwy_sig, SW0, cntryrd_sig};
    
endmodule: top
