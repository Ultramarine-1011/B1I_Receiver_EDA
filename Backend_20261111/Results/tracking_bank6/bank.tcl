source $env(SCRIPTS_DIR)/library.tcl
source $env(SCRIPTS_DIR)/reports.tcl
source $env(CACHE_HELPER)
set report_dir $env(REPORT_DIR)
read_ddc $env(CHANNEL_DIR)/mapped.ddc
set mapped_channel [freeze_mapped_channel CACHED_]
if {![read_verilog $env(BANK_WRAPPER)]} {exit 1}
current_design tracking_bank6
if {![link]} {exit 1}
set channels [get_cells -filter "ref_name == $mapped_channel"]
if {[sizeof_collection $channels] != 6} {error "Expected six mapped bank channels"}
set_dont_touch $channels true
set_boundary_optimization $channels false
if {[sizeof_collection [get_cells -hier -filter {is_unmapped == true || ref_name =~ GTECH*}]]} {error "Bank contains unmapped logic"}
set_operating_conditions typical -library typical
set reset_port reset_n
source $env(SCRIPTS_DIR)/baseline.sdc
write -format verilog -hierarchy -output $report_dir/mapped.v
write -format ddc -hierarchy -output $report_dir/mapped.ddc
write_sdc $report_dir/mapped.sdc
backend_reports ""
puts "MAPPED_TRACKING_BANK6_PASS CHANNELS=6 SCOPE=tracking_only REOPTIMIZATION=0"
exit 0
