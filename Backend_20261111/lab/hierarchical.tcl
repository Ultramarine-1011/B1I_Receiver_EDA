# Fresh mapping in the selected laboratory technology, with a channel checkpoint.
set report_dir $env(REPORT_DIR)
file mkdir $report_dir
source $env(LAB_DIR)/library.tcl
source $env(EXPERIMENT_ROOT)/scripts/reports.tcl
define_design_lib WORK -path ./WORK
set stage_root $env(EXPERIMENT_ROOT)/work/stage
set_app_var search_path [concat [list $stage_root/rtl $stage_root/sources/student_release/student_release/rtl] $search_path]

proc channel_constraints {} {
    global env
    apply_corners
    create_clock -name clk -period $env(CLOCK_NS) [get_ports clk]
    set_clock_uncertainty $env(UNCERTAINTY_NS) [get_clocks clk]
    set_clock_transition 0.1 [get_clocks clk]
    set inputs [remove_from_collection [all_inputs] [get_ports clk]]
    # Internal channel budget follows the local V6 IO model. PAD loads are
    # applied only when the assembled chip is finally constrained and timed.
    set_input_delay -clock clk -max 1.0 $inputs
    set_input_delay -clock clk -min 0.0 $inputs
    set data_inputs [remove_from_collection $inputs [get_ports reset_n]]
    set_driving_cell -library $env(STD_SS_LIB) -lib_cell $env(BLOCK_DRIVE_CELL) $data_inputs
    set_input_transition 0.1 [get_ports reset_n]
    set_output_delay -clock clk -max 1.0 [all_outputs]
    set_output_delay -clock clk -min 0.0 [all_outputs]
    set_load [expr {4 * [load_of $env(STD_SS_LIB)/$env(BLOCK_DRIVE_CELL)/$env(BLOCK_DRIVE_PIN)]}] [all_outputs]
}

set channel tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1
if {[info exists env(CHANNEL_CHECKPOINT)] && $env(CHANNEL_CHECKPOINT) ne ""} {
    # The shell verified the checkpoint, source, libraries and numeric settings.
    if {$env(SYNTH_SCOPE) ne "channel"} {error "Checkpoint restore requires channel scope"}
    read_ddc $env(CHANNEL_CHECKPOINT)/mapped.ddc
    current_design $channel
    if {![link]} {exit 1}
    read_sdc $env(CHANNEL_CHECKPOINT)/mapped.sdc
    apply_corners
    puts "LAB_CHANNEL_CHECKPOINT_RESTORED"

} else {
    # Map the complete standalone channel first. Elaborate the core only after
    # all mapped channel design names have been isolated from the RTL names.
    set stream [open $stage_root/filelists/B0.txt r]
    foreach path [split [string trim [read $stream]] \n] {
        if {![analyze -format sverilog -define SYNTHESIS $stage_root/[string trim $path]]} {exit 1}
    }
    close $stream
    if {![elaborate tracking_channel_minimal -parameters "ENABLE_FLL=1,ENABLE_CARRIER_AID=1"] || ![link]} {exit 1}
    file mkdir output/parts
    foreach name {tracking_atan tracking_divide_aid tracking_divide_step tracking_ratio_code tracking_ratio_phase} {
        current_design $name
        apply_corners
        set period 4
        if {$name == "tracking_atan" || $name == "tracking_ratio_code"} {set period $env(CLOCK_NS)}
        create_clock -name module_clk -period $period
        set_clock_uncertainty $env(UNCERTAINTY_NS) [get_clocks module_clk]
        set_input_delay -clock module_clk -max 0 [all_inputs]
        set_input_delay -clock module_clk -min 0 [all_inputs]
        set_output_delay -clock module_clk -max 0 [all_outputs]
        set_output_delay -clock module_clk -min 0 [all_outputs]
        set_driving_cell -library $env(STD_SS_LIB) -lib_cell $env(BLOCK_DRIVE_CELL) [all_inputs]
        set_load [expr {4 * [load_of $env(STD_SS_LIB)/$env(BLOCK_DRIVE_CELL)/$env(BLOCK_DRIVE_PIN)]}] [all_outputs]
        puts "LAB_PARTITION_BEGIN $name"
        if {![compile -map_effort medium]} {exit 1}
        redirect $report_dir/${name}_qor.rpt {report_qor}
        redirect $report_dir/${name}_timing.rpt {report_timing -delay max -max_paths 1 -significant_digits 6}
        ungroup -all -flatten
        reset_design
        set_dont_touch [current_design] true
        write -format ddc -hierarchy -output output/parts/${name}.ddc
        write -format verilog -hierarchy -output output/parts/${name}.v
        puts "LAB_PARTITION_DONE $name"
    }
    current_design $channel
    if {![link]} {exit 1}
    set arithmetic [get_cells -hier -filter {ref_name =~ tracking_ratio_* || ref_name =~ tracking_atan* || ref_name =~ tracking_divide_*}]
    if {[sizeof_collection $arithmetic] != 7} {error "Expected seven channel arithmetic instances"}
    set_dont_touch $arithmetic true
    set_boundary_optimization $arithmetic false
    channel_constraints
    puts "LAB_CHANNEL_COMPILE_BEGIN"
    if {![compile -map_effort medium]} {exit 1}
    if {[sizeof_collection [get_cells -hier -filter {is_hierarchical == false && is_unmapped == true}]]} {error "Channel has unmapped cells"}
    # Save a usable smaller result before attempting the six-channel shell.
    file mkdir output/channel
    write -format verilog -hierarchy -output output/channel/mapped.v
    write -format ddc -hierarchy -output output/channel/mapped.ddc
    write_sdc output/channel/mapped.sdc
    set outer_report_dir $report_dir
    set report_dir [file normalize output/channel/reports]
    file mkdir $report_dir
    backend_reports ""
    set report_dir $outer_report_dir
    set stream [open output/channel/checkpoint.sha256 w]
    puts $stream [exec sha256sum [file normalize output/channel/mapped.v] [file normalize output/channel/mapped.ddc] [file normalize output/channel/mapped.sdc] [file normalize output/config.json] [file normalize output/inputs.sha256] [file normalize output/libraries.sha256]]
    close $stream
    puts "LAB_CHANNEL_CHECKPOINT_COMPLETE"
    if {$env(SYNTH_SCOPE) == "six"} {
        source $stage_root/scripts/channel_cache.tcl
        set mapped_channel [freeze_mapped_channel LAB_MAPPED_]
        set stream [open $stage_root/filelists/B1.txt r]
        foreach path [split [string trim [read $stream]] \n] {
            if {![analyze -format sverilog -define SYNTHESIS $stage_root/[string trim $path]]} {exit 1}
        }
        close $stream
        if {![analyze -format sverilog $env(REPO_ROOT)/rtl/bds_bb_6ch_pad_top.sv]} {exit 1}
        if {![elaborate $env(TOP)] || ![link]} {exit 1}
        attach_mapped_channels $mapped_channel
        set acq [get_cells acquisition]
        if {[sizeof_collection $acq] != 1} {error "Missing PCPS isolation boundary"}
        set_dont_touch $acq true
        set_boundary_optimization $acq false
        source $stage_root/scripts/prune_core.tcl
        prune_core_records
        current_design $env(TOP)
        if {![link]} {exit 1}
        set pads [get_cells -hier -filter {ref_name =~ PD* || ref_name =~ PV*}]
        if {![sizeof_collection $pads]} {error "Real PAD cells are missing"}
        set_dont_touch $pads true
        set_dont_use [get_lib_cells $env(PAD_SS_LIB)/*]
        apply_corners
        source $env(LAB_DIR)/pad.sdc
        redirect $report_dir/check_pre.rpt {check_design}
        puts "LAB_PCPS_ISOLATED_STORAGE_NOT_SYNTHESIZED"
        puts "LAB_CORE_COMPILE_BEGIN CHANNELS=6"
        if {![compile -map_effort medium]} {exit 1}
        set channels [get_cells -hier -filter "ref_name == $mapped_channel"]
        if {[sizeof_collection $channels] != 6} {error "Six-channel mapping lost a tracking instance"}
    }
}
if {[sizeof_collection [all_clocks]] != 1} {error "Expected exactly one functional clock"}
write -format verilog -hierarchy -output output/final.v
write -format ddc -hierarchy -output output/final.ddc
write_sdc output/final.sdc
backend_reports ""
puts "LAB_SYNTH_EXPORTED SCOPE=$env(SYNTH_SCOPE)"
exit 0
