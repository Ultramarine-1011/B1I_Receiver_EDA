# One six-channel attempt. Only the M2 acquisition block is isolated.
source scripts/library.tcl
source scripts/reports.tcl
set report_dir $env(REPORT_DIR)
set stream [open filelists/B1.txt r]
foreach path [split [string trim [read $stream]] \n] {
    if {![analyze -format sverilog -define SYNTHESIS [string trim $path]]} {exit 1}
}
close $stream
if {![elaborate bds_bb_6ch_core] || ![link]} {exit 1}
set stream [open $env(CHANNEL_DIR)/mapped.v r]
set netlist [read $stream]
close $stream
# Replace precisely the designs contained in the verified mapped channel.
# The six core instances relink to the parameter-identical imported design.
foreach {whole name} [regexp -all -inline -line {^module +([^ (\r\n]+)} $netlist] {
    set existing [get_designs -quiet $name]
    if {[sizeof_collection $existing]} {remove_design $existing}
}
read_ddc $env(CHANNEL_DIR)/mapped.ddc
current_design tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1
reset_design
set_dont_touch [current_design] true
current_design bds_bb_6ch_core
if {![link]} {exit 1}
set channels [get_cells -hier -filter {ref_name == tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1}]
if {[sizeof_collection $channels] != 6} {error "Expected six complete mapped tracking channels"}
set_dont_touch $channels true
set_boundary_optimization $channels false
set acq [get_cells acquisition]
if {[sizeof_collection $acq] != 1} {exit 1}
set_dont_touch $acq true
set_boundary_optimization $acq false
puts "CORE_PCPS_ISOLATED acquisition STORAGE_NOT_SYNTHESIZED"
puts "CORE_TRACKING_INSTANCES [sizeof_collection $channels]"
redirect $report_dir/hierarchy_pre.rpt {report_hierarchy}
redirect $report_dir/check_design_pre.rpt {check_design}
set_operating_conditions $env(OPCOND) -library $env(STD_LIB)
set reset_port rst_n
source scripts/baseline.sdc
puts "CORE_COMPILE_BEGIN"
if {![compile -map_effort medium]} {exit 1}
write -format verilog -hierarchy -output $report_dir/mapped.v
write -format ddc -hierarchy -output $report_dir/mapped.ddc
write_sdc $report_dir/mapped.sdc
backend_reports ""
set channels [get_cells -hier -filter {ref_name == tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1}]
if {[sizeof_collection $channels] != 6} {exit 1}
if {[sizeof_collection [get_cells -hier -filter {is_hierarchical == false && is_unmapped == true}]]} {exit 1}
puts "BACKEND_CORE_ISOLATED_PASS CHANNELS=6"
exit 0
