###################################################################

# Created by write_sdc on Mon Sep 21 17:02:01 2026

###################################################################
set sdc_version 2.0

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
set_operating_conditions TYPICAL -library saed90nm_typ
set_wire_load_model -name tc8000000 -library saed90nm_typ
set_max_area 0
set_max_fanout 20 [current_design]
set_max_transition 2 [current_design]
set_fanout_load 20 [get_ports {out[3]}]
set_fanout_load 20 [get_ports {out[2]}]
set_fanout_load 20 [get_ports {out[1]}]
set_fanout_load 20 [get_ports {out[0]}]
create_clock [get_ports clock]  -period 20  -waveform {0 10}
set_input_delay -clock clock  -max 8  [get_ports clear]
set_input_delay -clock clock  -min 2  [get_ports clear]
set_output_delay -clock clock  -max 8  [get_ports {out[3]}]
set_output_delay -clock clock  -min 2  [get_ports {out[3]}]
set_output_delay -clock clock  -max 8  [get_ports {out[2]}]
set_output_delay -clock clock  -min 2  [get_ports {out[2]}]
set_output_delay -clock clock  -max 8  [get_ports {out[1]}]
set_output_delay -clock clock  -min 2  [get_ports {out[1]}]
set_output_delay -clock clock  -max 8  [get_ports {out[0]}]
set_output_delay -clock clock  -min 2  [get_ports {out[0]}]
