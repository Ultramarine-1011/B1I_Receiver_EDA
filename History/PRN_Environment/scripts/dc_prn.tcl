# Adapted from scripts/h0_dc_prn.tcl at fb662d3 for IC_EDA only.
set_app_var sh_enable_page_mode false
set_host_options -max_cores 1
set library_dir /home/ic_libs/TSMC.90/aci/sc-x/synopsys
set db_file $library_dir/typical.db
set_app_var search_path [concat $search_path $library_dir]
set_app_var target_library [list $db_file]
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var link_library [list * $db_file dw_foundation.sldb]
define_design_lib WORK -path ./WORK
set report_dir ../../reports/dc
file mkdir $report_dir

if {[analyze -format sverilog ../../rtl/b1i_prn_gen.sv] == 0} { exit 1 }
if {[elaborate b1i_prn_gen] == 0} { exit 1 }
current_design b1i_prn_gen
if {[link] == 0} { exit 1 }
redirect $report_dir/check_design_pre.rpt { check_design }
set_operating_conditions typical -library typical

# Experimental constraints, time in ns and capacitance in pF.
create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks clk]
set_clock_transition 0.1 [get_clocks clk]
set data_inputs [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]
set_input_delay -clock clk -max 1.0 $data_inputs
set_input_delay -clock clk -min 0.0 $data_inputs
set_output_delay -clock clk -max 1.0 [all_outputs]
set_output_delay -clock clk -min 0.0 [all_outputs]
set_driving_cell -lib_cell INVX1 -library typical $data_inputs
set inv_load [load_of typical/INVX1/A]
set output_load [expr {4.0 * $inv_load}]
set_load $output_load [all_outputs]
set_false_path -from [get_ports rst_n]
set_wire_load_mode enclosed
puts "IC_EDA_OUTPUT_LOAD_PF $output_load"
redirect $report_dir/library.rpt { list_libs }
redirect $report_dir/host_options.rpt { report_host_options }

if {[compile] == 0} { exit 1 }
redirect $report_dir/check_design_post.rpt { set design_ok [check_design] }
if {$design_ok == 0} { exit 1 }
set unmapped [get_cells -hierarchical -filter {is_hierarchical == false && is_unmapped == true}]
puts "IC_EDA_UNMAPPED_CELLS [sizeof_collection $unmapped]"
if {[sizeof_collection $unmapped] != 0} { exit 1 }

redirect $report_dir/area.rpt { report_area -hierarchy }
redirect $report_dir/references.rpt { report_reference -hierarchy }
redirect $report_dir/resources.rpt { report_resources }
redirect $report_dir/qor.rpt { report_qor }
redirect $report_dir/design.rpt { report_design }
redirect $report_dir/timing_max.rpt { report_timing -delay max -max_paths 10 -nworst 1 -significant_digits 6 }
redirect $report_dir/timing_min.rpt { report_timing -delay min -max_paths 10 -nworst 1 -significant_digits 6 }
redirect $report_dir/constraints.rpt { report_constraint -all_violators -significant_digits 6 }
redirect $report_dir/check_timing.rpt { check_timing }
write -format verilog -hierarchy -output $report_dir/b1i_prn_gen_tsmc90.v
write_sdc $report_dir/b1i_prn_gen_tsmc90.sdc
write -format ddc -hierarchy -output $report_dir/b1i_prn_gen_tsmc90.ddc
puts "IC_EDA_DC_COMPILE_DONE"
exit 0
