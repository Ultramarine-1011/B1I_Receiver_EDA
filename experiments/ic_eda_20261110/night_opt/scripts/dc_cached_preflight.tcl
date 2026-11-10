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

# Resume from completed, fully mapped arithmetic partitions produced in run V6.
# The complete channel is still checked and timed under the original B0 SDC.
set top_design [get_object_name [current_design]]
set cached_designs [list tracking_atan tracking_divide_aid tracking_divide_step tracking_ratio_code tracking_ratio_phase]
remove_design [get_designs $cached_designs]
foreach arithmetic $cached_designs {
    read_ddc $env(CACHED_ARITH_DIR)/${arithmetic}.ddc
    current_design $arithmetic
    set missing [get_cells -hierarchical -filter {is_hierarchical == false && is_unmapped == true}]
    if {[sizeof_collection $missing] != 0} { exit 1 }
    set_dont_touch [current_design] true
    puts "CACHED_PARTITION_LOADED $arithmetic"
}
current_design $top_design
if {[link] == 0} { exit 1 }
set arithmetic_cells [get_cells -hierarchical -filter {ref_name =~ tracking_ratio_* || ref_name =~ tracking_atan* || ref_name =~ tracking_divide_*}]
if {[sizeof_collection $arithmetic_cells] != 7} { exit 1 }
set actual_references [lsort -unique [get_attribute $arithmetic_cells ref_name]]
foreach arithmetic $actual_references {
    current_design $arithmetic
    set missing [get_cells -hierarchical -filter {is_hierarchical == false && is_unmapped == true}]
    if {[sizeof_collection $missing] != 0} { exit 1 }
}
current_design $top_design
set_dont_touch $arithmetic_cells true
set_boundary_optimization $arithmetic_cells false
puts "CACHED_FIXED_INSTANCES [sizeof_collection $arithmetic_cells]"

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
puts "CACHED_PREFLIGHT_PASS"
exit 0
