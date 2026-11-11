###################################################################

# Created by write_sdc on Wed Nov 11 12:07:02 2026

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_operating_conditions -analysis_type bc_wc -max slow -max_library slow\
                         -min fast -min_library fast
set_load -pin_load 0.01 [get_ports {count[7]}]
set_load -pin_load 0.01 [get_ports {count[6]}]
set_load -pin_load 0.01 [get_ports {count[5]}]
set_load -pin_load 0.01 [get_ports {count[4]}]
set_load -pin_load 0.01 [get_ports {count[3]}]
set_load -pin_load 0.01 [get_ports {count[2]}]
set_load -pin_load 0.01 [get_ports {count[1]}]
set_load -pin_load 0.01 [get_ports {count[0]}]
create_clock [get_ports clk]  -period 20  -waveform {0 10}
set_input_delay -clock clk  -clock_fall  0.01  [get_ports reset_n]
set_input_delay -clock clk  -clock_fall  0.01  [get_ports enable]
set_output_delay -clock clk  -max 1  [get_ports {count[7]}]
set_output_delay -clock clk  -min 0  [get_ports {count[7]}]
set_output_delay -clock clk  -max 1  [get_ports {count[6]}]
set_output_delay -clock clk  -min 0  [get_ports {count[6]}]
set_output_delay -clock clk  -max 1  [get_ports {count[5]}]
set_output_delay -clock clk  -min 0  [get_ports {count[5]}]
set_output_delay -clock clk  -max 1  [get_ports {count[4]}]
set_output_delay -clock clk  -min 0  [get_ports {count[4]}]
set_output_delay -clock clk  -max 1  [get_ports {count[3]}]
set_output_delay -clock clk  -min 0  [get_ports {count[3]}]
set_output_delay -clock clk  -max 1  [get_ports {count[2]}]
set_output_delay -clock clk  -min 0  [get_ports {count[2]}]
set_output_delay -clock clk  -max 1  [get_ports {count[1]}]
set_output_delay -clock clk  -min 0  [get_ports {count[1]}]
set_output_delay -clock clk  -max 1  [get_ports {count[0]}]
set_output_delay -clock clk  -min 0  [get_ports {count[0]}]
set_input_transition -max 0.1  [get_ports reset_n]
set_input_transition -min 0.1  [get_ports reset_n]
set_input_transition -max 0.1  [get_ports enable]
set_input_transition -min 0.1  [get_ports enable]
