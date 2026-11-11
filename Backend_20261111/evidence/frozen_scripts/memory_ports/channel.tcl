source scripts/library.tcl
source scripts/reports.tcl
set report_dir $env(REPORT_DIR)
set stream [open filelists/B0.txt r]
set sources [split [string trim [read $stream]] \n]
close $stream
foreach path $sources {
    if {![analyze -format sverilog -define SYNTHESIS [string trim $path]]} {exit 1}
}
if {![elaborate tracking_channel_minimal -parameters "ENABLE_FLL=1,ENABLE_CARRIER_AID=1"] || ![link]} {exit 1}
set top_design [get_object_name [current_design]]
set names {tracking_atan tracking_divide_aid tracking_divide_step tracking_ratio_code tracking_ratio_phase}
remove_design [get_designs $names]
foreach name $names {
    read_ddc $env(CACHE_DIR)/${name}.ddc
    current_design $name
    set_dont_touch [current_design] true
}
current_design $top_design
if {![link]} {exit 1}
set arithmetic [get_cells -hier -filter {ref_name =~ tracking_ratio_* || ref_name =~ tracking_atan* || ref_name =~ tracking_divide_*}]
if {[sizeof_collection $arithmetic] != 7} {exit 1}
set_dont_touch $arithmetic true
set_boundary_optimization $arithmetic false
set_operating_conditions $env(OPCOND) -library $env(STD_LIB)
set reset_port reset_n
source scripts/baseline.sdc
redirect $report_dir/check_pre.rpt {check_design}
puts "CHANNEL_COMPILE_BEGIN"
if {![compile -map_effort medium]} {exit 1}
write -format verilog -hierarchy -output $report_dir/mapped.v
write -format ddc -hierarchy -output $report_dir/mapped.ddc
write_sdc $report_dir/mapped.sdc
backend_reports ""
if {[sizeof_collection [get_cells -hier -filter {is_unmapped == true && is_hierarchical == false}]]} {exit 1}
puts "BACKEND_CHANNEL_PASS"
exit 0
