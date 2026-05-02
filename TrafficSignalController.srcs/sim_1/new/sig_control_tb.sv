program sig_control_tb (
    input logic clk,
    input common::sig_colors_e hwy_sig,         // 2-bit output for 3 states of signal GREEN, YELLOW, RED
    input common::sig_colors_e cntryrd_sig,     // 2-bit output for 3 states of signal GREEN, YELLOW, RED
    input logic failsafe_entered,
    output logic rst_n_tb,
    output logic test_failsafe_tb,
    output logic car_on_cntryrd_tb              // if TRUE, indicates that there is car on the country road, otherwise FALSE
);    

    timeunit 1ns/1ps;

    // apply stimulus
    initial
    begin
        // reset everything
        #0 rst_n_tb = 0; car_on_cntryrd_tb = 0; test_failsafe_tb = 0;
        $display("reset asserted");
        #70 rst_n_tb = 1;
        $display("reset deasserted");

        // wait for default state, hwy green, put car on cntryrd
        wait(hwy_sig == common::GREEN);
        #40 car_on_cntryrd_tb = 1;
        $display("car on cntryrd arrived");

        // wait for cntryrd green, car on cntryrd proceeds
        wait(cntryrd_sig == common::GREEN);
        #5 car_on_cntryrd_tb = 0;
        $display("car on cntryrd left");

        // wait for default state and trigger a failsafe
        wait(hwy_sig == common::GREEN);
        #150 test_failsafe_tb = 1;
        $display("failsafe triggered");
 
        // reset everything, is the only way out
        #200 rst_n_tb = 0; test_failsafe_tb = 0;
        $display("reset asserted");
        #70 rst_n_tb = 1;
        $display("reset deasserted");

        // wait for default state and put a car on cntryrd again
        wait(hwy_sig == common::GREEN);
        #40 car_on_cntryrd_tb = 1;
        $display("car on cntryrd arrived");

        // wait for cntryrd green
        wait(cntryrd_sig == common::GREEN);

        // let car_on_cntryrd_tb high and wait for a forced switch,
        wait(cntryrd_sig == common::YELLOW);
        $display("switch forced");

        // wait for default state, cntryrd is still occupied
        wait(hwy_sig == common::GREEN);

        // wait for cnryrd green because car_on_cntryrd is still high, cars proceed
        wait(cntryrd_sig == common::GREEN);
        #5 car_on_cntryrd_tb = 0;
        $display("car on cntryrd left");

        // wait for defaulr state and trigger a failsafe
        wait(hwy_sig == common::GREEN);

        #250 $finish;
    end
    
endprogram: sig_control_tb
