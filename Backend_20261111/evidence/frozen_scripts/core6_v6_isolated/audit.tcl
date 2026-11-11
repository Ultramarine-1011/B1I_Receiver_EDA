source scripts/library.tcl
source scripts/reports.tcl
set report_dir $env(REPORT_DIR)
set old /home/ICer/ic_eda_night_20261110/runs/full_v6_cached_10ns/reports
read_ddc $old/mapped.ddc
current_design tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1
if {![link]} {exit 1}
backend_reports ddc_
write -format verilog -hierarchy -output $report_dir/ddc_export.v
remove_design -all
read_verilog $old/mapped.v
current_design tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1
if {![link]} {exit 1}
read_sdc $old/mapped.sdc
backend_reports verilog_
puts "BACKEND_AUDIT_PASS"
exit 0
