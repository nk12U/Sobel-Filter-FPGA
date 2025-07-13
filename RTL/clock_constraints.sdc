# Clock constraints
create_clock -name "clk" -period 20ns [get_ports {clk}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

# tsu/th constraints
set_input_delay -clock clk -max 5ns [all_inputs]
set_input_delay -clock clk -min 2ns [all_inputs]

# tco constraints
set_output_delay -clock clk -max 5ns [all_outputs]
set_output_delay -clock clk -min 2ns [all_outputs]

# tpd constraints
