module top_sig_control_tb;

    timeunit 1ns/1ns;

    logic clk_tb;
    logic rst_n;
    logic test_failsafe_tb;
    logic car_on_cntryrd;  // if TRUE; indicates that there is car on the country road
    logic failsafe_entered;
    common::sig_colors_e hwy_sig, cntryrd_sig;

    // reset synchronizer
    sync_async dut0(.clk(clk_tb), .rst_n(rst_n_tb), .async_in(rst_n_tb), .sync_out(rst_n));

    // switch synchronizer
    debounce #(.STABLE_TICKS(3)) dut1(.clk(clk_tb), .rst_n(rst_n), .raw_in(car_on_cntryrd_tb), .debounced_out(car_on_cntryrd));

    // button synchronizer
    debounce #(.STABLE_TICKS(5_000_000)) dut2(.clk(clk_tb), .rst_n(rst_n), .raw_in(test_failsafe_tb), .debounced_out(test_failsafe));

    // Instantiate signal controller
    sig_control dut3(
        .clk(clk_tb),
        .rst_n(rst_n),
        .test_failsafe(test_failsafe_tb),
        .hwy_sig(hwy_sig),
        .cntryrd_sig(cntryrd_sig),
        .car_on_cntryrd(car_on_cntryrd),
        .failsafe_entered(failsafe_entered)
    );

    // testbench
    sig_control_tb tb(
        .clk(clk_tb),
        .hwy_sig(hwy_sig),
        .cntryrd_sig(cntryrd_sig),
        .failsafe_entered(failsafe_entered),
        .rst_n_tb(rst_n_tb),
        .test_failsafe_tb(test_failsafe_tb),
        .car_on_cntryrd_tb(car_on_cntryrd_tb)
    );

    // Set up clock
    initial
    begin
        clk_tb = 0;
        forever #5 clk_tb = ~clk_tb;
    end
  
    // Set up monitor
    initial
        $monitor($stime, " : Main Sig = %6s (%b) Country Sig = %6s (%b) Car_on_cntryrd = %b Reset = %b Failsafe = %b", hwy_sig.name, hwy_sig, cntryrd_sig.name, cntryrd_sig, car_on_cntryrd_tb, rst_n_tb, failsafe_entered);
    
endmodule: top_sig_control_tb
