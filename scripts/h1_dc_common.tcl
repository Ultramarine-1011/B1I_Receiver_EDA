# Shared H1 Design Compiler body. Each module has its own entry script.
# Invoke those entries from the matching work/h1_dc_* directory.
# The 10 ns clock, 1.0 ns IO delay and 4x INVX1 load follow the H0
# observation baseline. They are not a teacher signoff constraint.

set_app_var sh_enable_page_mode false
set_app_var search_path [concat $search_path /home/IC/Foundry_Library/Digital]
set_app_var target_library [list saed90nm_typ.db]
set_app_var link_library [list * saed90nm_typ.db]

set report_dir ../../reports/local/h1_vm
file mkdir $report_dir

puts "H1_TOP $H1_TOP"
puts "H1_SOURCES $H1_SOURCES"
puts "H1_TARGET_LIBRARY $target_library"
puts "H1_CLOCK_NS 10 experimental_not_signoff"

foreach src $H1_SOURCES {
  if {[analyze -format sverilog $src] == 0} {
    puts "H1_DC_ANALYZE_FAIL $src"
    exit 1
  }
}
puts "H1_DC_ANALYZE_OK"

if {[elaborate $H1_TOP] == 0} {
  puts "H1_DC_ELABORATE_FAIL"
  exit 1
}
puts "H1_DC_ELABORATE_OK"
current_design $H1_TOP

if {[link] == 0} {
  puts "H1_DC_LINK_FAIL"
  exit 1
}
puts "H1_DC_LINK_OK"

redirect $report_dir/${H1_TOP}_check_design_pre.rpt { check_design }

create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks clk]
set data_inputs [remove_from_collection [all_inputs] [get_ports {clk reset_n}]]
set_input_delay -clock clk 1.0 $data_inputs
set_output_delay -clock clk 1.0 [all_outputs]
set_driving_cell -lib_cell INVX1 $data_inputs
set inv_load [load_of saed90nm_typ/INVX1/INP]
set_load [expr {4.0 * $inv_load}] [all_outputs]
puts "H1_INVX1_INP_LOAD_FF $inv_load"
puts "H1_OUTPUT_LOAD_FF [expr {4.0 * $inv_load}]"
set_false_path -from [get_ports reset_n]
puts "H1_CONSTRAINT experimental_10ns_not_teacher_signoff"

set cd_status [check_design]
puts "H1_CHECK_DESIGN_STATUS $cd_status"
redirect $report_dir/${H1_TOP}_check_design.rpt { check_design }

if {[compile] == 0} {
  puts "H1_DC_COMPILE_FAIL"
  exit 1
}

set cd_post [check_design]
puts "H1_CHECK_DESIGN_POST_STATUS $cd_post"
redirect $report_dir/${H1_TOP}_check_design_post.rpt { check_design }

redirect $report_dir/${H1_TOP}_area.rpt { report_area }
redirect -append $report_dir/${H1_TOP}_area.rpt { report_reference -hierarchy }
redirect $report_dir/${H1_TOP}_resources.rpt { report_resources }
redirect $report_dir/${H1_TOP}_qor.rpt { report_qor }
redirect $report_dir/${H1_TOP}_timing.rpt { report_timing -delay max -max_paths 5 -nworst 1 -significant_digits 3 }
redirect $report_dir/${H1_TOP}_timing_path.rpt { report_timing -delay max -path full -max_paths 3 -nworst 1 -significant_digits 3 }
redirect $report_dir/${H1_TOP}_constraint.rpt { report_constraint -all_violators }

if {[catch {set latches [all_registers -level_sensitive]} msg]} {
  puts "H1_LATCH_QUERY_FAIL $msg"
} else {
  puts "H1_LATCH_COUNT [sizeof_collection $latches]"
  if {[sizeof_collection $latches] > 0} {
    redirect $report_dir/${H1_TOP}_latches.rpt { report_cell -nosplit $latches }
  } else {
    set latch_file [open $report_dir/${H1_TOP}_latches.rpt w]
    puts $latch_file "H1_LATCH_COUNT 0"
    close $latch_file
  }
}

if {[catch {set bbox [get_cells -quiet -hierarchical -filter "is_black_box == true"]} msg]} {
  puts "H1_BLACKBOX_QUERY_FAIL $msg"
} else {
  puts "H1_BLACKBOX_COUNT [sizeof_collection $bbox]"
  if {[sizeof_collection $bbox] > 0} {
    redirect $report_dir/${H1_TOP}_blackbox.rpt { report_cell -nosplit $bbox }
  }
}

if {[catch {set unmapped [get_cells -quiet -hierarchical -filter "is_unmapped == true"]} msg]} {
  puts "H1_UNMAPPED_QUERY_FAIL $msg"
} else {
  puts "H1_UNMAPPED_COUNT [sizeof_collection $unmapped]"
  if {[sizeof_collection $unmapped] > 0} {
    redirect $report_dir/${H1_TOP}_unmapped.rpt { report_cell -nosplit $unmapped }
  }
}

write -format verilog -hierarchy -output $report_dir/${H1_TOP}_saed90nm.v
write_sdc $report_dir/${H1_TOP}_saed90nm.sdc
puts "H1_DC_COMPILE_DONE"
exit 0
