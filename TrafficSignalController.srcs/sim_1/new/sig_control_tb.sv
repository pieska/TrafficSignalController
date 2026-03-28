program sig_control_tb (
    input logic clk,
    input common::sig_colors_e hwy_sig,         // 2-bit output for 3 states of signal GREEN, YELLOW, RED
    input common::sig_colors_e cntryrd_sig,     // 2-bit output for 3 states of signal GREEN, YELLOW, RED
    input logic failsafe_entered,
    output logic rst_n_tb,
    output logic test_failsafe_tb,
    output logic car_on_cntryrd_tb              // if TRUE, indicates that there is car on the country road, otherwise FALSE
);    

    timeunit 1ns/1ns;

    // apply stimulus
    initial
    begin
        #0 rst_n_tb = 0; car_on_cntryrd_tb = 0; test_failsafe_tb = 0;
        #70 rst_n_tb = 1; 

        #36 car_on_cntryrd_tb = 1;
        
        #143 car_on_cntryrd_tb = 0;
        
        #150 test_failsafe_tb = 1;
        
        #150 rst_n_tb = 0; test_failsafe_tb = 0;
        #70 rst_n_tb = 1; 

        #36 car_on_cntryrd_tb = 1;
        
        #143 car_on_cntryrd_tb = 0;
        
        #150 $finish;
    end
    
endprogram: sig_control_tb
