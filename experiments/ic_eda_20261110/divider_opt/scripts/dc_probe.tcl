set_app_var sh_enable_page_mode false
set_host_options -max_cores 1
set report_dir $env(BASELINE_REPORT_DIR)
file mkdir $report_dir
define_design_lib WORK -path ./WORK
set db_file /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db
set_app_var target_library [list $db_file]
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var link_library [list * $db_file dw_foundation.sldb]
if {[analyze -format sverilog -define SYNTHESIS work/norm_probes.sv] == 0} { exit 1 }
if {[analyze -format sverilog work/probe_registers.sv] == 0} { exit 1 }
if {[elaborate probe_$env(PROBE_VERSION)] == 0} { exit 1 }
if {[link] == 0} { exit 1 }
set reset_port reset_n
set_operating_conditions typical -library typical
source scripts/baseline.sdc
redirect $report_dir/resources_pre.rpt { report_resources -hierarchy }
redirect $report_dir/hierarchy_pre.rpt { report_hierarchy }
puts "PROBE_COMPILE_BEGIN [clock seconds]"
if {[compile -map_effort medium] == 0} { exit 1 }
puts "PROBE_COMPILE_END [clock seconds]"
redirect $report_dir/area.rpt { report_area -hierarchy }
redirect $report_dir/qor.rpt { report_qor }
redirect $report_dir/timing_max.rpt { report_timing -delay max -max_paths 3 -significant_digits 6 }
redirect $report_dir/references.rpt { report_reference -hierarchy }
redirect $report_dir/check_design_post.rpt { check_design }
write -format verilog -hierarchy -output $report_dir/mapped.v
puts "PROBE_REPORTS_DONE"
exit 0
