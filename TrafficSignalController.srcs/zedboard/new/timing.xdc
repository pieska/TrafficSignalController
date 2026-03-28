create_clock -period 10.000 [get_ports GCLK]

set_false_path -from [get_ports BTNC]
set_false_path -from [get_ports SW0]

set_false_path -to [get_ports LD?]
set_false_path -to [get_ports JC?_?]
