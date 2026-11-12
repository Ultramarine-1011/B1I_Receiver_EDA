proc teacher_probe {} {
    global env report_dir
    set_app_var sh_enable_page_mode false
    set_host_options -max_cores 1
    set_app_var target_library /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db
    set_app_var link_library [list * /home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db dw_foundation.sldb]
    define_design_lib WORK -path ./WORK
    analyze -format sverilog ../teacher/bdi_b1i_prn_pkg.sv
    analyze -format sverilog ../teacher/bdi_capture_channel_6sat.sv
    elaborate bdi_capture_channel_6sat
    if {![link]} {error "Teacher capture link failed"}
    create_clock -name clk -period 10 [get_ports clk_16m368]
    set_clock_uncertainty -setup 0.2 [get_clocks clk]
    set_clock_uncertainty -hold 0.2 [get_clocks clk]
    set_clock_transition 0.1 [get_clocks clk]
    set data [remove_from_collection [all_inputs] [get_ports {clk_16m368 rst_n}]]
    set_input_delay -clock clk -max 1 $data
    set_input_delay -clock clk -min 0 $data
    set_driving_cell -lib_cell INVX1 -library typical $data
    set_output_delay -clock clk -max 1 [all_outputs]
    set_output_delay -clock clk -min 0 [all_outputs]
    set_load [expr {4*[load_of typical/INVX1/A]}] [all_outputs]
    set_false_path -from [get_ports rst_n]
    set_operating_conditions typical -library typical
    if {![compile -map_effort medium]} {error "Teacher capture mapping failed"}
    set report_dir $env(REPORT_DIR)
    write -format verilog -hierarchy -output $report_dir/mapped.v
    write -format ddc -hierarchy -output $report_dir/mapped.ddc
    write_sdc $report_dir/mapped.sdc
    redirect $report_dir/area.rpt {report_area -hierarchy}
    redirect $report_dir/timing_max.rpt {report_timing -delay max -max_paths 1 -significant_digits 6}
    redirect $report_dir/timing_min.rpt {report_timing -delay min -max_paths 1 -significant_digits 6}
    puts "TEACHER_CAPTURE_PROBE_PASS SEARCH_PHASES=2046 FREQUENCY_BINS=1 SV_ID=6"
}
if {[catch {teacher_probe} failure]} {
    puts stderr "TEACHER_CAPTURE_PROBE_FAILED $failure"
    exit 1
}
exit 0
