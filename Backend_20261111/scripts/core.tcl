# One six-channel attempt. Only the M2 acquisition block is isolated.
source scripts/library.tcl
source scripts/reports.tcl
set report_dir $env(REPORT_DIR)
source scripts/channel_cache.tcl
# Read and rename the complete cache while no elaborated RTL designs exist.
read_ddc $env(CHANNEL_DIR)/mapped.ddc
set mapped_channel [freeze_mapped_channel CACHED_]
set stream [open filelists/B1.txt r]
foreach path [split [string trim [read $stream]] \n] {
    if {![analyze -format sverilog -define SYNTHESIS [string trim $path]]} {exit 1}
}
close $stream
if {![elaborate bds_bb_6ch_core] || ![link]} {exit 1}
attach_mapped_channels $mapped_channel
set channels [get_cells -hier -filter "ref_name == $mapped_channel"]
set acq [get_cells acquisition]
if {[sizeof_collection $acq] != 1} {exit 1}
set_dont_touch $acq true
set_boundary_optimization $acq false
puts "CORE_PCPS_ISOLATED acquisition STORAGE_NOT_SYNTHESIZED"
puts "CORE_TRACKING_INSTANCES [sizeof_collection $channels]"
redirect $report_dir/hierarchy_pre.rpt {report_hierarchy}
redirect $report_dir/check_design_pre.rpt {check_design}
# The chip interface does not consume receiver record_data. Flatten these
# wrappers before mapping so DC can prune the unused timestamp dividers before
# it builds six copies of them. The verified tracking designs stay intact.
source scripts/prune_core.tcl
prune_core_records
redirect $report_dir/hierarchy_pruned_input.rpt {report_hierarchy}
set_operating_conditions $env(OPCOND) -library $env(STD_LIB)
set reset_port rst_n
source scripts/baseline.sdc
puts "CORE_COMPILE_BEGIN"
if {![compile -map_effort medium]} {exit 1}
write -format verilog -hierarchy -output $report_dir/mapped.v
write -format ddc -hierarchy -output $report_dir/mapped.ddc
write_sdc $report_dir/mapped.sdc
backend_reports ""
set channels [get_cells -hier -filter "ref_name == $mapped_channel"]
if {[sizeof_collection $channels] != 6} {exit 1}
if {[sizeof_collection [get_cells -hier -filter {is_hierarchical == false && is_unmapped == true}]]} {exit 1}
puts "BACKEND_CORE_ISOLATED_PASS CHANNELS=6"
exit 0
