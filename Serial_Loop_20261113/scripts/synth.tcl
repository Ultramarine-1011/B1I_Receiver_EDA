proc iterative_synthesis {} {
global env report_dir search_path
set_app_var sh_enable_page_mode false
set_host_options -max_cores 1
set_app_var target_library /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db
set_app_var synthetic_library dw_foundation.sldb
set_app_var link_library [list * /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db dw_foundation.sldb]
set_app_var search_path [concat [list ../rtl] $search_path]
define_design_lib WORK -path ./WORK
foreach name {b1i_prn_gen code_nco carrier_nco_mixer epl_correlator tracking_frontend_spaced tracking_channel_minimal} {
    if {![analyze -format sverilog -define SYNTHESIS ../rtl/${name}.sv]} {exit 1}
}
if {![elaborate tracking_channel_minimal -parameters "ENABLE_FLL=1,ENABLE_CARRIER_AID=1"] || ![link]} {exit 1}
set_operating_conditions typical -library typical
set reset_port reset_n
source ../scripts/baseline.sdc
redirect $env(REPORT_DIR)/check_pre.rpt {check_design}
if {![compile -map_effort medium]} {exit 1}
write -format verilog -hierarchy -output $env(REPORT_DIR)/mapped.v
write -format ddc -hierarchy -output $env(REPORT_DIR)/mapped.ddc
write_sdc $env(REPORT_DIR)/mapped.sdc
set report_dir $env(REPORT_DIR)
source ../scripts/reports.tcl
backend_reports ""
if {[sizeof_collection [get_cells -hier -filter {is_unmapped == true && is_hierarchical == false}]]} {exit 1}
puts "ITERATIVE_TRACKING_DC_PASS"
}
if {[catch {iterative_synthesis} failure]} {
    puts stderr "ITERATIVE_TRACKING_DC_FAILED $failure"
    exit 1
}
exit 0
