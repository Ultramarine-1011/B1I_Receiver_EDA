set_app_var sh_enable_page_mode false
set_host_options -max_cores 1
define_design_lib WORK -path ./WORK
set db_file /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db
set_app_var target_library [list $db_file]
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var link_library [list * $db_file dw_foundation.sldb]
if {[analyze -format sverilog work/identify_dividers.sv] == 0} { exit 1 }
foreach kind {code phase} {
    if {[elaborate identify_$kind] == 0} { exit 1 }
    if {[link] == 0} { exit 1 }
    redirect $env(IDENTIFY_REPORT)/${kind}_check.rpt { check_timing }
    redirect $env(IDENTIFY_REPORT)/${kind}_resources.rpt { report_resources -hierarchy }
    redirect $env(IDENTIFY_REPORT)/${kind}_hierarchy.rpt { report_hierarchy }
}
puts "IDENTIFY_DIVIDERS_DONE"
exit 0
