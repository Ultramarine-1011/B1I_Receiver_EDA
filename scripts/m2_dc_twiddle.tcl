# Map eight constant addresses of the real FFT twiddle functions.
set_app_var sh_enable_page_mode false
set std_db /home/share/libs/tsmc28/logic/selected_db/tcbn28hpcplusbwp40p140tt0p9v25c.db
set_app_var target_library [list $std_db]
set_app_var link_library [list * $std_db]
set report_dir reports
file mkdir $report_dir

set_app_var search_path [concat [list .] $search_path]
if {[analyze -format sverilog twiddle_probe.sv] == 0} {
    puts "TWIDDLE_ANALYZE_FAIL"
    exit 1
}
if {[elaborate twiddle_probe] == 0} {
    puts "TWIDDLE_ELABORATE_FAIL"
    exit 1
}
current_design twiddle_probe
link
create_clock -name clk -period 10
if {[compile] == 0} {
    puts "TWIDDLE_COMPILE_FAIL"
    exit 1
}
redirect $report_dir/twiddle_area.rpt { report_area }
write -format verilog -hierarchy -output $report_dir/twiddle_probe_mapped.v
puts "TWIDDLE_COMPILE_DONE"
exit 0
