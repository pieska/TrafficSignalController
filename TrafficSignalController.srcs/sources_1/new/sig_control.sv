module sig_control #(parameter HOLD_FACTOR = 1)(
    input logic clk,
    input logic rst_n,
    input logic test_failsafe,                  // check failsafe mode
    input logic car_on_cntryrd,                 // if TRUE, indicates that there is car on the country road, otherwise FALSE
    output common::sig_colors_e hwy_sig,        // 2-bit output fpr 3 states of signal GREEN, YELLOW, RED
    output common::sig_colors_e cntryrd_sig,    // 2-bit output fpr 3 states of signal GREEN, YELLOW, RED
    output logic failsafe_entered               // failsafe mode entered
);    

    timeunit 1ns/1ns;

    // hold tomes- 1 because counter is 0-based
    localparam R_HOLD  = (4 * HOLD_FACTOR),  // holdtime yellow
               Y_HOLD  = (2 * HOLD_FACTOR),  // holdtime red
               G_HOLD  = (3 * HOLD_FACTOR),  // holdtime green
               Y_BLINK = (2 * HOLD_FACTOR);  // blinktime yellow in failsafe state

    // state enum type    
    typedef enum {
        INIT,
        HWTG,
        HWOG,
        HWTR,
        CRTG,
        CROG,
        CRTR,
        FAIL,
        FAIL0,
        FAIL1
    } state_e;

    // https://docs.amd.com/r/en-US/ug912-vivado-properties/FSM_SAFE_STATE
    // if something goes wrong go into default state
    (* fsm_encoding = "one_hot", fsm_safe_state = "default_state" *) state_e current;
    
    // state struct 
    struct {
        state_e state;
        int unsigned hold_time;
    } next;
    
    int unsigned counter;

    /*
    ** simple 2-process FSM with combinatorical output
    */
    
    // state changes only at positive edge and held by hold_time
    always_ff @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            current <= INIT;
            counter <= 0;
            failsafe_entered <= 'b0;
        end else if(test_failsafe && !failsafe_entered)
        begin
            current <= FAIL;
        end else if(counter == 0) // if counter == 0, set state and hold it fpr <hold>,hold == 0 means no hold
        begin
            current <= next.state;
            counter <= next.hold_time;
        end else
            counter <= counter - 1;
    end;

    // state and output logic
    always_comb
    begin
        hwy_sig = common::RED;
        cntryrd_sig = common::RED;
        next = '{current, 0};
        unique case(current)
            INIT:       next = '{HWTG, R_HOLD};
            HWTG:       next = '{HWOG, G_HOLD};
            HWOG:       begin
                            hwy_sig = common::GREEN;
                            if(car_on_cntryrd)
                                next = '{HWTR, Y_HOLD};
                        end
            HWTR:       begin
                            hwy_sig = common::YELLOW;
                            next = '{CRTG, R_HOLD};
                        end
            CRTG:       next = '{CROG, G_HOLD};
            CROG:       begin
                            cntryrd_sig = common::GREEN;
                            if(!car_on_cntryrd)
                                next = '{CRTR, Y_HOLD};
                        end
            CRTR:       begin
                            cntryrd_sig = common::YELLOW;
                            next = '{HWTG, R_HOLD};
                        end
            // can be reached by bit error only, switch to failsafe immediately
            default:    begin
                            failsafe_entered = 'b1;
                            hwy_sig = common::OFF;
                            cntryrd_sig = common::OFF;                            
                            next = '{FAIL0, Y_BLINK};
                        end
            FAIL0:      begin
                            hwy_sig = common::YELLOW;
                            cntryrd_sig = common::YELLOW;                            
                            next = '{FAIL1, Y_BLINK};
                        end
            FAIL1:      begin
                            hwy_sig = common::OFF;
                            cntryrd_sig = common::OFF;                            
                            next = '{FAIL0, Y_BLINK};
                        end
        endcase 
    end

/*
** no 'disable iff (!rst_n)', output must be checked even at reset
**
** parametrized properties hang xelab
**
** $rose(SIG == COLOR1) |=> SIG == COLOR1[*TIME:$] ##1 SIG == COLOR2
**
** if SIG changes to COLOR1, it must stay in COLOR1 for at least TIME and then change to COLOR2
*/
    property light_change_hwy_R2G;
        @(posedge clk)
        disable iff (failsafe_entered)
        $rose(hwy_sig == common::RED) |=> hwy_sig == common::RED[*R_HOLD:$] ##1 hwy_sig == common::GREEN;
    endproperty

    property light_change_cntryrd_R2G;
        @(posedge clk) 
        disable iff (failsafe_entered)
        $rose(cntryrd_sig == common::RED) |=> cntryrd_sig == common::RED[*R_HOLD:$] ##1 cntryrd_sig == common::GREEN;
    endproperty

    property light_change_hwy_G2Y;
        @(posedge clk) 
        disable iff (failsafe_entered)
        $rose(hwy_sig == common::GREEN) |=> hwy_sig == common::GREEN[*G_HOLD:$] ##1 hwy_sig == common::YELLOW;
    endproperty

    property light_change_cntryrd_G2Y;
        @(posedge clk) 
        disable iff (failsafe_entered)
        $rose(cntryrd_sig == common::GREEN) |=> cntryrd_sig == common::GREEN[*G_HOLD:$] ##1 cntryrd_sig == common::YELLOW;
    endproperty

    property light_change_hwy_Y2R;
        @(posedge clk) 
        disable iff (failsafe_entered)
        $rose(hwy_sig == common::YELLOW) |=> hwy_sig == common::YELLOW[*Y_HOLD:$] ##1 hwy_sig == common::RED;
    endproperty

    property light_change_cntryrd_Y2R;
        @(posedge clk)
        disable iff (failsafe_entered)
        $rose(cntryrd_sig == common::YELLOW) |=> cntryrd_sig == common::YELLOW[*Y_HOLD:$] ##1 cntryrd_sig == common::RED;
    endproperty

    // mit failsafe alles
    property failsafe;
        @(posedge clk)
        $rose(failsafe_entered) |-> (hwy_sig == common::OFF) && (cntryrd_sig == common::OFF);
    endproperty

    property failsafe_hwy_O2Y;
        @(posedge clk)
        disable iff (!failsafe_entered)
        $rose(hwy_sig == common::OFF) |=> hwy_sig == common::OFF[*Y_BLINK:$] ##1 (hwy_sig == common::YELLOW);
    endproperty

    property failsafe_cntryrd_O2Y;
        @(posedge clk)
        disable iff (!failsafe_entered)
        $rose(cntryrd_sig == common::OFF) |=> cntryrd_sig == common::OFF[*Y_BLINK:$] ##1 (cntryrd_sig == common::YELLOW);
    endproperty

    property failsafe_hwy_Y2O;
        @(posedge clk)
        disable iff (!failsafe_entered)
        $rose(hwy_sig == common::YELLOW) |=> hwy_sig == common::YELLOW[*Y_BLINK:$] ##1 (hwy_sig == common::OFF);
    endproperty

    property failsafe_cntryrd_Y2O;
        @(posedge clk)
        disable iff (!failsafe_entered)
        $rose(cntryrd_sig == common::YELLOW) |=> cntryrd_sig == common::YELLOW[*Y_BLINK:$] ##1 (cntryrd_sig == common::OFF);
    endproperty

    assert property(light_change_hwy_R2G);
    assert property(light_change_hwy_G2Y);
    assert property(light_change_hwy_Y2R);

    assert property(light_change_cntryrd_R2G);
    assert property(light_change_cntryrd_G2Y);
    assert property(light_change_cntryrd_Y2R);

    assert property(failsafe);
    assert property(failsafe_hwy_O2Y);
    assert property(failsafe_cntryrd_O2Y);
    assert property(failsafe_hwy_Y2O);
    assert property(failsafe_cntryrd_Y2O);

endmodule: sig_control
