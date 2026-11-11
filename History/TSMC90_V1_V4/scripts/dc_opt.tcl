# IC_EDA original-RTL baseline. Run from the frozen experiment root.
set_app_var sh_enable_page_mode false
set_host_options -max_cores 1
set stage $env(BASELINE_STAGE)
set report_dir $env(BASELINE_REPORT_DIR)
file mkdir $report_dir
define_design_lib WORK -path ./WORK
set library_dir /home/ic_libs/TSMC.90/aci/sc-x/synopsys
set db_file $library_dir/typical.db
set rtl sources/student_release/student_release/rtl
set_app_var search_path [concat [list rtl $rtl $library_dir .] $search_path]
set_app_var target_library [list $db_file]
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var link_library [list * $db_file dw_foundation.sldb]
puts "BASELINE_STAGE $stage"
# The DC banner in run.log records the precise version and build date.
puts "BASELINE_DW_FILE [which dw_foundation.sldb]"
puts "BASELINE_COMPILE_COMMAND compile -map_effort medium"
set list_file [open filelists/$stage.txt r]
set sources [split [string trim [read $list_file]] \n]
close $list_file
foreach path $sources {
    puts "BASELINE_SOURCE $path"
    if {[analyze -format sverilog -define SYNTHESIS $path] == 0} { exit 1 }
}
if {$stage == "B0"} {
    if {[elaborate tracking_channel_minimal -parameters "ENABLE_FLL=1,ENABLE_CARRIER_AID=1"] == 0} { exit 1 }
    # elaborate selects the parameterized design. Keep its actual current name.
    set reset_port reset_n
} else {
    if {[elaborate bds_bb_6ch_core] == 0} { exit 1 }
    set reset_port rst_n
}
puts "BASELINE_ELABORATED [get_object_name [current_design]]"
if {[link] == 0} { exit 1 }
if {$stage == "B1"} {
    set acq [get_cells acquisition]
    if {[sizeof_collection $acq] != 1} { exit 1 }
    set_dont_touch $acq true
    set_boundary_optimization $acq false
    puts "BASELINE_ISOLATED acquisition [get_attribute $acq ref_name]"
}
set_operating_conditions typical -library typical
source scripts/baseline.sdc
redirect $report_dir/host_options.rpt { report_host_options }
redirect $report_dir/library.rpt { list_libs }
redirect $report_dir/design_pre.rpt { report_design }
redirect $report_dir/check_design_pre.rpt { check_design }
redirect $report_dir/check_timing_pre.rpt { check_timing }
redirect $report_dir/resources_pre.rpt { report_resources -hierarchy }
redirect $report_dir/hierarchy_pre.rpt { report_hierarchy }
write_sdc $report_dir/constraints_pre.sdc
puts "BASELINE_COMPILE_BEGIN [clock seconds]"
if {[compile -map_effort medium] == 0} { exit 1 }
puts "BASELINE_COMPILE_END [clock seconds]"
# Export immediately after successful compile, before optional reports.
write -format verilog -hierarchy -output $report_dir/mapped.v
write_sdc $report_dir/mapped.sdc
write -format ddc -hierarchy -output $report_dir/mapped.ddc
redirect $report_dir/check_design_post.rpt { set design_ok [check_design] }
set unmapped [get_cells -hierarchical -filter {is_hierarchical == false && is_unmapped == true}]
puts "BASELINE_UNMAPPED [sizeof_collection $unmapped]"
redirect $report_dir/area.rpt { report_area -hierarchy }
redirect $report_dir/references.rpt { report_reference -hierarchy }
redirect $report_dir/resources_post.rpt { report_resources -hierarchy }
redirect $report_dir/qor.rpt { report_qor }
redirect $report_dir/design_post.rpt { report_design }
redirect $report_dir/timing_max.rpt { report_timing -delay max -max_paths 20 -nworst 1 -significant_digits 6 }
redirect $report_dir/timing_min.rpt { report_timing -delay min -max_paths 20 -nworst 1 -significant_digits 6 }
redirect $report_dir/constraints.rpt { report_constraint -all_violators -significant_digits 6 }
redirect $report_dir/check_timing_post.rpt { check_timing }
redirect $report_dir/hierarchy_post.rpt { report_hierarchy }
if {$stage == "B0" && ($design_ok == 0 || [sizeof_collection $unmapped] != 0)} { exit 1 }
puts "BASELINE_REPORTS_DONE $stage"
exit 0
