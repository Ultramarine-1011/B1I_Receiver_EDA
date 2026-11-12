proc iterative_integration {} {
global env report_dir
set_app_var sh_enable_page_mode false
set_host_options -max_cores 1
set_app_var target_library /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db
set_app_var link_library [list * /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db dw_foundation.sldb]
define_design_lib WORK -path ./WORK
source ../scripts/channel_cache.tcl
set channel_reports ../channel/reports
if {[info exists env(ITERATIVE_CHANNEL_REPORTS)]} {set channel_reports $env(ITERATIVE_CHANNEL_REPORTS)}
read_ddc $channel_reports/mapped.ddc
set channel [freeze_mapped_channel ITERATIVE_]
set report_dir $env(REPORT_DIR)
source ../scripts/reports.tcl
if {$env(SCOPE) eq "bank"} {
    set loaded [read_verilog ../rtl/tracking_bank6.v]
    if {[llength $loaded]!=1} {error "Bank wrapper was not read"}
    current_design tracking_bank6
    if {![link]} {exit 1}
    set channels [get_cells -filter "ref_name == $channel"]
    if {[sizeof_collection $channels]!=6} {error "Expected six iterative trackers"}
    set_dont_touch $channels true
    set reset_port reset_n
} else {
    read_ddc /home/ICer/ic_eda_resume_tree_20261112/final_core/reports/mapped.ddc
    current_design bds_bb_6ch_core
    set channels [get_cells -hier -filter {ref_name =~ *tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1}]
    if {[sizeof_collection $channels]!=6} {error "Expected six baseline trackers"}
    set old_reference [lsort -unique [get_attribute $channels ref_name]]
    set old_interface [channel_interface [lindex $old_reference 0]]
    if {[channel_interface $channel] ne $old_interface} {error "Cached tracker interface mismatch"}
    current_design bds_bb_6ch_core
    change_link $channels $channel
    if {![link]} {exit 1}
    reset_design
    rename_design bds_bb_6ch_core bds_bb_6ch_engine
    set_dont_touch [current_design] true
    if {![analyze -format sverilog ../rtl/mapped_core_wrapper.sv]} {exit 1}
    if {![elaborate bds_bb_6ch_core] || ![link]} {exit 1}
    set_dont_touch [get_cells engine] true
    set_boundary_optimization [get_cells engine] false
    set reset_port rst_n
}
set_operating_conditions typical -library typical
source ../scripts/baseline.sdc
if {$env(SCOPE) eq "core" && ![compile -map_effort medium]} {exit 1}
write -format verilog -hierarchy -output $report_dir/mapped.v
write -format ddc -hierarchy -output $report_dir/mapped.ddc
write_sdc $report_dir/mapped.sdc
backend_reports ""
set channels [get_cells -hier -filter "ref_name == $channel"]
if {[sizeof_collection $channels]!=6} {error "Final hierarchy must contain six iterative trackers"}
if {[sizeof_collection [get_cells -hier -filter {is_hierarchical == false && is_unmapped == true}]]} {exit 1}
puts "ITERATIVE_INTEGRATION_PASS SCOPE=$env(SCOPE) CHANNELS=6"
}
if {[catch {iterative_integration} failure]} {
    puts stderr "ITERATIVE_INTEGRATION_FAILED $failure"
    exit 1
}
exit 0
