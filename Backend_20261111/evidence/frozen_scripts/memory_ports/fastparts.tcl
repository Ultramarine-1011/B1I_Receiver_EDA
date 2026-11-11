# Same V6 arithmetic, with a shorter budget for the three serial feedback blocks.
source scripts/library.tcl
set report_dir $env(REPORT_DIR)
foreach name {tracking_atan tracking_ratio_code} {
    file copy $env(BASE_CACHE_DIR)/${name}.ddc $report_dir/${name}.ddc
}
if {![analyze -format sverilog -define SYNTHESIS rtl/tracking_channel_minimal.sv]} {exit 1}
foreach name {tracking_ratio_phase tracking_divide_step tracking_divide_aid} {
    if {![elaborate $name] || ![link]} {exit 1}
    set_operating_conditions $env(OPCOND) -library $env(STD_LIB)
    create_clock -name module_clk -period 4
    set_clock_uncertainty -setup 0.2 [get_clocks module_clk]
    set_clock_uncertainty -hold 0.2 [get_clocks module_clk]
    set_input_delay -clock module_clk -max 0 [all_inputs]
    set_input_delay -clock module_clk -min 0 [all_inputs]
    set_output_delay -clock module_clk -max 0 [all_outputs]
    set_output_delay -clock module_clk -min 0 [all_outputs]
    set_driving_cell -library $env(STD_LIB) -lib_cell $env(DRIVE_CELL) [all_inputs]
    set_load [expr {4.0 * [load_of $env(STD_LIB)/$env(DRIVE_CELL)/$env(DRIVE_PIN)]}] [all_outputs]
    puts "FAST_PARTITION_BEGIN $name"
    if {![compile -map_effort medium]} {exit 1}
    redirect $report_dir/${name}_qor.rpt {report_qor}
    redirect $report_dir/${name}_timing.rpt {report_timing -delay max -max_paths 1 -significant_digits 6}
    ungroup -all -flatten
    reset_design
    set_dont_touch [current_design] true
    write -format ddc -hierarchy -output $report_dir/${name}.ddc
    write -format verilog -hierarchy -output $report_dir/${name}.v
    puts "FAST_PARTITION_DONE $name"
}
puts "BACKEND_PARTITIONS_PASS"
exit 0
