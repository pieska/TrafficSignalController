module sig_control
#(
    parameter int unsigned HOLD_FACTOR = common::s_to_ticks(1)
)
(
    input logic clk,
    input logic rst_n,
    input logic test_failsafe,                  // test failsafe mode
    input logic car_on_cntryrd,                 // if TRUE, indicates that there is car on the country road, otherwise FALSE
    output common::sig_colors_e hwy_sig,        // 3-bit output for 3 states of signal GREEN, YELLOW, RED, OFF
    output common::sig_colors_e cntryrd_sig,    // 3-bit output for 3 states of signal GREEN, YELLOW, RED, OFF
    output logic failsafe_entered               // failsafe mode entered
);    

    timeunit 1ns/1ps;

    localparam R_HOLD     = HOLD_FACTOR * 4,       // holdtime red
               Y_HOLD     = HOLD_FACTOR * 2,       // holdtime yellow
               G_HOLD     = HOLD_FACTOR * 3,       // holdtime green
               G_MAX_HOLD = HOLD_FACTOR * 30,      // max. holdtime green to prevent starvation
               Y_BLINK    = HOLD_FACTOR * 0.5;     // blinktime yellow in failsafe state

    // state enum type    
    typedef enum logic [3:0] {
        INIT,
        HWTG,
        HWOG,
        HWTR,
        CRTG,
        CROG,
        CRTR,
        FAIL,
        INVALID // ist nicht in case -> default
    } state_e;

    struct {
        state_e state;
        int unsigned hold_time;
    } next;

    // https://docs.amd.com/r/en-US/ug912-vivado-properties/FSM_SAFE_STATE
    // if something goes wrong go into default state
    // attributes do not work with using structs, so next as struct, current not
    (* fsm_encoding = "one_hot", fsm_safe_state = "default_state" *) state_e current_state;
    int unsigned current_hold_time;
    
    // toggle for blinking
    logic blink_on;
    
    // counter and flag for forced switch if green was too long
    int unsigned green_max_timer;
    logic green_max_timeout;

    // set flag 
    assign green_max_timeout = (green_max_timer == 0);

    // Blink toggle - only active in FAIL state to blink yellow
    always_ff @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            blink_on <= 'b0;
        end else if (current_state == FAIL && current_hold_time == 0)
        begin
            blink_on <= ~blink_on;
        end
    end

    // Maximaler Grün-Timer für cntryrd, verhindert Highway-Starvation
    always_ff @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
            green_max_timer <= G_MAX_HOLD;
        else if (current_state == CROG)
        begin
            if (green_max_timer != 0)
                green_max_timer <= green_max_timer - 1;
        end else green_max_timer <= G_MAX_HOLD;   // Reset bei jedem anderen State
    end

    /*
    ** simple 2-process FSM with combinatorical output
    */
    
    // state changes only at positive edge and held by hold_time
    always_ff @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            current_state <= INIT;
            current_hold_time <= 0;
        end else if(test_failsafe && !failsafe_entered)
        begin
            current_state <= INVALID;   // INVALID acts as the first FAIL stage
            current_hold_time <= Y_BLINK;
        end else if(current_hold_time == 0) // if hold_time == 0, set state and hold it for <hold>,hold == 0 means no hold
        begin
            current_state <= next.state;
            current_hold_time <= next.hold_time;
        end else
            current_hold_time <= current_hold_time - 1;
    end

    // state and output logic
    always_comb
    begin
        failsafe_entered = 'b0;
        hwy_sig = common::RED;
        cntryrd_sig = common::RED;
        next.state = current_state;
        next.hold_time = current_hold_time;
        unique case(current_state)
            INIT:       next = '{HWTG, R_HOLD};
            HWTG:       next = '{HWOG, G_HOLD};
            HWOG:       begin
                            hwy_sig = common::GREEN;
                            if(car_on_cntryrd)
                                next = '{HWTR, Y_HOLD}; // sobald car_on_cntryrd == 1 wird umgeschaltet
                        end
            HWTR:       begin
                            hwy_sig = common::YELLOW;
                            next = '{CRTG, R_HOLD};
                        end
            CRTG:       next = '{CROG, G_HOLD};
            CROG:       begin
                            cntryrd_sig = common::GREEN;
                            if (!car_on_cntryrd || green_max_timeout)
                                next = '{CRTR, Y_HOLD}; // sobald car_on_cntryrd == 0 oder green too long wird umgeschaltet
                        end
            CRTR:       begin
                            cntryrd_sig = common::YELLOW;
                            next = '{HWTG, R_HOLD};
                        end
            FAIL:      begin
                            failsafe_entered = 'b1;
                            hwy_sig     = blink_on ? common::YELLOW : common::OFF;
                            cntryrd_sig = blink_on ? common::YELLOW : common::OFF;
                            next = '{FAIL, Y_BLINK};
                        end
            // can be reached by bit error only, switch to failsafe immediately
            // acts as the first FAIL stage
            default:    begin
                            failsafe_entered = 'b1;
                            hwy_sig = common::YELLOW;
                            cntryrd_sig = common::YELLOW;                            
                            next = '{FAIL, Y_BLINK};
                        end
        endcase 
    end

    /*
    ** asserts
    */
    
    // Beide Signale dürfen NIE gleichzeitig GREEN sein
    property no_simultaneous_green;
        @(posedge clk)
        !(hwy_sig == common::GREEN && cntryrd_sig == common::GREEN);
    endproperty
    
    assert property(no_simultaneous_green);
    
    // bei reset IMMER alles auf rot, egal of failsafe oder nicht
    property reset_default_state;
        @(posedge clk)
        $rose(rst_n) |=> (hwy_sig == common::RED && cntryrd_sig == common::RED);
    endproperty

    assert property(reset_default_state);
    
    // mit failsafe alles auf YELLOW
    property enter_failsafe_to_yellow;
        disable iff (!rst_n)
        @(posedge clk)
        $rose(failsafe_entered) |-> (hwy_sig == common::YELLOW) && (cntryrd_sig == common::YELLOW);
    endproperty

    assert property(enter_failsafe_to_yellow);
    
    // bei failsafe yellow blinken mit Y:BLINK dauer
    property hwy_Y2O_BLINK;
        @(posedge clk)
        disable iff (!rst_n || !failsafe_entered)
        $rose(hwy_sig == common::YELLOW) |=> hwy_sig == common::YELLOW[*Y_BLINK] ##1 hwy_sig == common::OFF;
    endproperty

    assert property(hwy_Y2O_BLINK);
    
    property hwy_O2Y_BLINK;
        @(posedge clk)
        disable iff (!rst_n || !failsafe_entered)
        $rose(hwy_sig == common::OFF) |=> hwy_sig == common::OFF[*Y_BLINK] ##1 hwy_sig == common::YELLOW;
    endproperty

    assert property(hwy_O2Y_BLINK);
    
    property cntryrd_Y2O_BLINK;
        @(posedge clk)
        disable iff (!rst_n || !failsafe_entered)
        $rose(cntryrd_sig == common::YELLOW) |=> cntryrd_sig == common::YELLOW[*Y_BLINK] ##1 cntryrd_sig == common::OFF;
    endproperty

    assert property(cntryrd_Y2O_BLINK);

    property cntryrd_O2Y_BLINK;
        @(posedge clk)
        disable iff (!rst_n || !failsafe_entered)
        $rose(cntryrd_sig == common::OFF) |=> cntryrd_sig == common::OFF[*Y_BLINK] ##1 cntryrd_sig == common::YELLOW;
    endproperty

    assert property(cntryrd_O2Y_BLINK);

    // min. HOLD-times, parameterizing hangs xelab!
    property hwy_min_R_HOLD;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $rose(hwy_sig == common::RED) |=> hwy_sig == common::RED[*R_HOLD];
    endproperty

    assert property(hwy_min_R_HOLD);
    
    property cntryrd_min_R_HOLD;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $rose(cntryrd_sig == common::RED) |=> cntryrd_sig == common::RED[*R_HOLD];
    endproperty

    assert property(cntryrd_min_R_HOLD);

    property hwy_min_Y_HOLD;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $rose(hwy_sig == common::YELLOW) |=> hwy_sig == common::YELLOW[*Y_HOLD];
    endproperty

    assert property(hwy_min_Y_HOLD);

    property cntryrd_min_Y_HOLD;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $rose(cntryrd_sig == common::YELLOW) |=> cntryrd_sig == common::YELLOW[*Y_HOLD];
    endproperty

    assert property(cntryrd_min_Y_HOLD);

    property hwy_min_G_HOLD;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $rose(hwy_sig == common::GREEN) |=> hwy_sig == common::GREEN[*G_HOLD];
    endproperty

    assert property(hwy_min_G_HOLD);

    property cntryrd_min_G_HOLD;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $rose(cntryrd_sig == common::GREEN) |=> cntryrd_sig == common::GREEN[*G_HOLD];
    endproperty

    assert property(cntryrd_min_G_HOLD);

    property cntryrd_max_G_HOLD;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $rose(cntryrd_sig == common::GREEN) |=> (cntryrd_sig == common::GREEN)[*0:G_MAX_HOLD] ##1 (cntryrd_sig != common::GREEN);
    endproperty

    assert property(cntryrd_max_G_HOLD);

    /*
    ** phasenwechsel
    **
    
    ** mit parametrisierung hängt xelab und die form unten funktioniert nicht mit HOLD_TIMES gerade/ungerade
    ** daher split in assert für HOLD_TIME und assert für wechsel
    ** (!rst_n) ist wichtig, weil sonst $fell am anfang wegen X->0 triggert
    
    property light_change_hwy_R2G;
        @(posedge clk)
        disable iff (failsafe_entered)
        $rose(hwy_sig == common::RED) |=> hwy_sig == common::RED[*R_HOLD:$] ##1 hwy_sig == common::GREEN;
    endproperty
*/
    // R->G
    property light_change_hwy_R2G;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $fell(hwy_sig == common::RED) |-> hwy_sig == common::GREEN;
    endproperty

    assert property(light_change_hwy_R2G);

    property light_change_cntryrd_R2G;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $fell(cntryrd_sig == common::RED) |-> cntryrd_sig == common::GREEN;
    endproperty

    assert property(light_change_cntryrd_R2G);

    // G->Y
    property light_change_hwy_G2Y;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $fell(hwy_sig == common::GREEN) |-> hwy_sig == common::YELLOW;
    endproperty

    assert property(light_change_hwy_G2Y);

    property light_change_cntryrd_G2Y;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $fell(cntryrd_sig == common::GREEN) |-> cntryrd_sig == common::YELLOW;
    endproperty

    assert property(light_change_cntryrd_G2Y);

    // Y->R
    property light_change_hwy_Y2R;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $fell(hwy_sig == common::YELLOW) |-> hwy_sig == common::RED;
    endproperty

    assert property(light_change_hwy_Y2R);

    property light_change_cntryrd_Y2R;
        @(posedge clk)
        disable iff (!rst_n || failsafe_entered)
        $fell(cntryrd_sig == common::YELLOW) |-> cntryrd_sig == common::RED;
    endproperty

    assert property(light_change_cntryrd_Y2R);

endmodule: sig_control
