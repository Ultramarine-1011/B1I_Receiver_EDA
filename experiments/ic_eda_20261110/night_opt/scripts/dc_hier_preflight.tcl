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

set arithmetic_instances [get_cells -hierarchical -filter {ref_name =~ tracking_ratio_* || ref_name =~ tracking_atan* || ref_name =~ tracking_divide_*}]
puts "HIER_PREFLIGHT_INSTANCES [sizeof_collection $arithmetic_instances]"
puts "HIER_PREFLIGHT_DESIGNS [lsort -unique [get_attribute $arithmetic_instances ref_name]]"
redirect $report_dir/hierarchy.rpt { report_hierarchy }
redirect $report_dir/check_design.rpt { check_design }
if {[sizeof_collection $arithmetic_instances] != 7} { exit 1 }
puts "HIER_PREFLIGHT_PASS"
exit 0
