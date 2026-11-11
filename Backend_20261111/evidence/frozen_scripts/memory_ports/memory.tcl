source scripts/library.tcl
set report_dir $env(REPORT_DIR)
if {![analyze -format sverilog probes/memory.sv]} {exit 1}
foreach type {async sync} {
    foreach depth {16 64} {
        if {![elaborate memory_$type -parameters "DEPTH=$depth,WIDTH=16"] || ![link]} {exit 1}
        set_operating_conditions $env(OPCOND) -library $env(STD_LIB)
        create_clock -name clk -period 10 [get_ports clk]
        set data_inputs [remove_from_collection [all_inputs] [get_ports clk]]
        set_input_delay -clock clk -max 1 $data_inputs
        set_input_delay -clock clk -min 0 $data_inputs
        set_output_delay -clock clk -max 1 [all_outputs]
        set_output_delay -clock clk -min 0 [all_outputs]
        set_driving_cell -library $env(STD_LIB) -lib_cell $env(DRIVE_CELL) $data_inputs
        set_load [expr {4.0 * [load_of $env(STD_LIB)/$env(DRIVE_CELL)/$env(DRIVE_PIN)]}] [all_outputs]
        redirect $report_dir/${type}_${depth}_resources.rpt {report_resources -hierarchy}
        if {![compile -map_effort medium]} {exit 1}
        redirect $report_dir/${type}_${depth}_area.rpt {report_area}
        redirect $report_dir/${type}_${depth}_qor.rpt {report_qor}
        redirect $report_dir/${type}_${depth}_timing.rpt {report_timing -delay max -max_paths 1 -significant_digits 6}
        redirect $report_dir/${type}_${depth}_references.rpt {report_reference -hierarchy}
        write -format verilog -hierarchy -output $report_dir/${type}_${depth}.v
        puts "MEMORY_PROBE_DONE $type $depth"
    }
}
puts "BACKEND_MEMORY_PASS"
exit 0
