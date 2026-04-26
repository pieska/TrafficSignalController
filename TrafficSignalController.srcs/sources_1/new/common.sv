package common;

    typedef enum logic [2:0] {
        RED    = 'b100,
        YELLOW = 'b010,
        GREEN  = 'b001,
        OFF    = 'b000
    } sig_colors_e;

    localparam int unsigned CLK_FREQ_HZ = 100_000_000;  // 100 MHz

    function automatic int unsigned ms_to_ticks(input int unsigned ms);
        return (CLK_FREQ_HZ / 1000) * ms;
    endfunction

    function automatic int unsigned s_to_ticks(input int unsigned s);
        return CLK_FREQ_HZ * s;
    endfunction

endpackage
