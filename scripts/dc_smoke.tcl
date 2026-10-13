set_app_var search_path [concat $search_path /home/IC/Foundry_Library/Digital]
set_app_var target_library [list saed90nm_typ.db]
set_app_var synthetic_library [list saed90nm_typ.db]
set_app_var link_library [list * saed90nm_typ.db]

analyze -format verilog ../../rtl/counter.v
elaborate counter
current_design counter
link
source ../../constraints/counter.sdc
check_design
compile -exact_map

redirect ../../reports/dc_area.rpt { report_area }
redirect ../../reports/dc_timing.rpt { report_timing }
write -format verilog -hierarchy -output ../../reports/counter_after_dc.v
write_sdc ../../reports/counter_after_dc.sdc
exit
