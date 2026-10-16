# H0 experimental Design Compiler run for b1i_prn_gen.
# Invoke from work/h0_dc so the relative RTL and report paths stay stable.
# The 10 ns clock is an experiment for this smoke, not a course clock requirement.

set_app_var sh_enable_page_mode false
set_app_var search_path [concat $search_path /home/IC/Foundry_Library/Digital]
set_app_var target_library [list saed90nm_typ.db]
set_app_var link_library [list * saed90nm_typ.db]

set report_dir ../../reports/local/h0_vm
file mkdir $report_dir

if {[analyze -format sverilog ../../rtl/b1i_prn_gen.sv] == 0} {
  puts "H0_DC_ANALYZE_FAIL"
  exit 1
}
if {[elaborate b1i_prn_gen] == 0} {
  puts "H0_DC_ELABORATE_FAIL"
  exit 1
}
current_design b1i_prn_gen
if {[link] == 0} {
  puts "H0_DC_LINK_FAIL"
  exit 1
}

redirect $report_dir/check_design_pre_constraint.rpt { check_design }

# Experimental constraint: 100 MHz, 1 ns input/output delay, async reset excluded.
create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks clk]
set data_inputs [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]
set_input_delay -clock clk 1.0 $data_inputs
set_output_delay -clock clk 1.0 [all_outputs]
set_driving_cell -lib_cell INVX1 $data_inputs
# saed90nm_typ capacitive_load_unit is 1 fF. Use four INVX1 input pins.
set inv_load [load_of saed90nm_typ/INVX1/INP]
set_load [expr {4.0 * $inv_load}] [all_outputs]
puts "H0_INVX1_INP_LOAD_FF $inv_load"
puts "H0_OUTPUT_LOAD_FF [expr {4.0 * $inv_load}]"
set_false_path -from [get_ports rst_n]

redirect $report_dir/check_design.rpt { check_design }

if {[compile] == 0} {
  puts "H0_DC_COMPILE_FAIL"
  exit 1
}

redirect $report_dir/check_design_post_compile.rpt { check_design }

redirect $report_dir/dc_area.rpt { report_area }
redirect -append $report_dir/dc_area.rpt { report_reference -hierarchy }
redirect $report_dir/dc_resources.rpt { report_resources }
redirect $report_dir/dc_qor.rpt { report_qor }
redirect $report_dir/dc_timing.rpt { report_timing -delay max -max_paths 5 -nworst 1 -significant_digits 3 }
redirect $report_dir/dc_timing_path.rpt { report_timing -delay max -path full -max_paths 3 -nworst 1 -significant_digits 3 }
redirect $report_dir/dc_constraint.rpt { report_constraint -all_violators }

write -format verilog -hierarchy -output $report_dir/b1i_prn_gen_saed90nm.v
write_sdc $report_dir/b1i_prn_gen_saed90nm.sdc
puts "H0_DC_COMPILE_DONE"
exit
