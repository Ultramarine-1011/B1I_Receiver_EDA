# Experimental baseline. Time ns, capacitance pF. Same IO model as prior PRN run.
create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty -setup 0.2 [get_clocks clk]
set_clock_uncertainty -hold 0.2 [get_clocks clk]
set_clock_transition 0.1 [get_clocks clk]
set data_inputs [remove_from_collection [all_inputs] [get_ports [list clk $reset_port]]]
set_input_delay -clock clk -max 1.0 $data_inputs
set_input_delay -clock clk -min 0.0 $data_inputs
set_output_delay -clock clk -max 1.0 [all_outputs]
set_output_delay -clock clk -min 0.0 [all_outputs]
set_driving_cell -lib_cell INVX1 -library typical $data_inputs
set output_load [expr {4.0 * [load_of typical/INVX1/A]}]
set_load $output_load [all_outputs]
# Only asynchronous external reset is excepted. All functional data paths stay timed.
set_false_path -from [get_ports $reset_port]
set_wire_load_mode enclosed
puts "BASELINE_OUTPUT_LOAD_PF $output_load"
