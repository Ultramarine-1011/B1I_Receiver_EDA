# M2 candidate IO environment. Reset recovery/removal remains timed.
create_clock -name clk -period $env(CLOCK_NS) [get_ports pad_clk]
# Include real PAD/clock-cell arcs in pre-layout STA and the exported SDF.
set_propagated_clock [get_clocks clk]
set_clock_uncertainty $env(UNCERTAINTY_NS) [get_clocks clk]
set_clock_transition $env(INPUT_TRANSITION_NS) [get_clocks clk]
set inputs [get_ports {pad_rst_n pad_IF[*] pad_if_valid pad_cfg_valid pad_cfg_channel[*] pad_cfg_prn[*] pad_cfg_enable}]
set outputs [get_ports {pad_if_ready pad_capture_ok[*] pad_bit_sync_ok[*] pad_nav_data[*] pad_nav_valid[*]}]
set_input_transition $env(INPUT_TRANSITION_NS) $inputs
set_input_delay -clock clk -max $env(IO_MAX_NS) $inputs
set_input_delay -clock clk -min $env(IO_MIN_NS) $inputs
set_output_delay -clock clk -max $env(IO_MAX_NS) $outputs
set_output_delay -clock clk -min $env(IO_MIN_NS) $outputs
set_load $env(OUTPUT_LOAD_PF) $outputs
if {[info exists env(MAX_FANOUT)] && $env(MAX_FANOUT) ne ""} {set_max_fanout $env(MAX_FANOUT) [current_design]}
