# M2 candidate constraints for bds_bb_6ch_pad_top.
# The 10 ns period is the functional 100 MHz candidate. It is not a closed
# TSMC28 timing specification. Delays below are off-chip budgets; pad-cell
# arcs stay inside the design.
#
# Chosen from tphn28hpcpgv18tt0p9v1p8v25c.lib (time unit 1 ns, cap unit 1 pF):
#   default_max_transition = 5.0 ns
#   PDDW08DGZ_H_G PAD->C cell_rise at the first table index = 0.5165 ns
#   PDDW08DGZ_H_G PAD pin max_capacitance = 100 pF
#   C pin max_capacitance = 0.5 pF
# External data transition 0.5 ns is the same order as that fast PAD->C arc
# and is inside the 5 ns library maximum. External load 5 pF is inside the
# 100 pF PAD limit. Input/output delay 2.0 ns is 20% of the candidate period.
# Clock uncertainty 0.10 ns is a candidate allowance, not a clock-tree result.

create_clock -name clk -period 10.0 [get_ports pad_clk]
set_clock_uncertainty 0.10 [get_clocks clk]
set_clock_transition 0.50 [get_clocks clk]

set data_inputs [get_ports {
    pad_rst_n pad_IF[*] pad_if_valid pad_cfg_valid
    pad_cfg_channel[*] pad_cfg_prn[*] pad_cfg_enable
}]
set data_outputs [get_ports {
    pad_if_ready pad_capture_ok[*] pad_bit_sync_ok[*]
    pad_nav_data[*] pad_nav_valid[*]
}]

set_input_transition 0.50 $data_inputs
set_input_delay -clock clk -max 2.0 $data_inputs
set_input_delay -clock clk -min 0.10 $data_inputs
set_output_delay -clock clk -max 2.0 $data_outputs
set_output_delay -clock clk -min 0.10 $data_outputs
set_load 5.0 $data_outputs

# DC K-2015.06 drops the power-aware pg pins, so VDD/VSS/VDDPST/VSSPST are not
# ports of the linked logical design. Do not call get_ports on them here.
