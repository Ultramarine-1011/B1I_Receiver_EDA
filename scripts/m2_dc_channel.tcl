# M2 experiment: map one tracking channel, the unit that contains the 80-bit dividers.
# This is not the six-channel pad compile. The pad-top compile was killed on the 2GB VM.
set_app_var sh_enable_page_mode false
set std_db /home/share/libs/tsmc28/logic/selected_db/tcbn28hpcplusbwp40p140tt0p9v25c.db
set_app_var target_library [list $std_db]
set_app_var link_library [list * $std_db]
set rtl student_release/student_release/rtl
set_app_var search_path [concat [list $rtl .] $search_path]
set report_dir reports/m2_tsmc28_20261106
file mkdir $report_dir

foreach name {b1i_prn_gen.sv code_nco.sv carrier_nco_mixer.sv epl_correlator.sv tracking_frontend_spaced.sv tracking_channel_minimal.sv} {
    if {[analyze -format sverilog $rtl/$name] == 0} {
        puts "M2_CH_ANALYZE_FAIL $name"
        exit 1
    }
}
if {[elaborate tracking_channel_minimal -parameters "ENABLE_FLL=1,ENABLE_CARRIER_AID=1"] == 0} {
    puts "M2_CH_ELABORATE_FAIL"
    exit 1
}
current_design tracking_channel_minimal
link
create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty 0.10 [get_clocks clk]
set data_in [remove_from_collection [all_inputs] [get_ports {clk reset_n}]]
set_input_delay -clock clk -max 2.0 $data_in
set_input_delay -clock clk -min 0.10 $data_in
set_output_delay -clock clk -max 2.0 [all_outputs]
set_output_delay -clock clk -min 0.10 [all_outputs]
set_input_delay -clock clk -max 2.0 [get_ports reset_n]
set_input_delay -clock clk -min 0.10 [get_ports reset_n]
puts "M2_CH_FREE_BEFORE"
sh free -m
set compile_status [compile -map_effort low]
puts "M2_CH_COMPILE_STATUS $compile_status"
redirect $report_dir/channel_area.rpt { report_area }
redirect $report_dir/channel_resources.rpt { report_resources }
redirect $report_dir/channel_qor.rpt { report_qor }
redirect $report_dir/channel_timing.rpt {
    report_timing -delay max -max_paths 5 -nworst 1 -significant_digits 3
}
puts "M2_CH_FREE_AFTER"
sh free -m
puts "M2_CH_DONE"
exit 0
