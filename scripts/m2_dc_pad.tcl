# M2 first DC of bds_bb_6ch_pad_top.
# Large PCPS/FFT storage is replaced by synth/m2_isolate/acquisition_pcps_blackbox.sv.
# That isolation is an experiment. It is not a full six-channel compile.
# Run from the repository root on the Linux host after sourcing ~/eda_env.sh.
set_app_var sh_enable_page_mode false
set std_db /home/share/libs/tsmc28/logic/selected_db/tcbn28hpcplusbwp40p140tt0p9v25c.db
set pad_db /home/share/libs/tsmc28/pad/timing_nldm/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn28hpcpgv18_170a/tphn28hpcpgv18tt0p9v1p8v25c.db
set std_lib tcbn28hpcplusbwp40p140tt0p9v25c
set pad_lib tphn28hpcpgv18tt0p9v1p8v25c
set_app_var target_library [list $std_db]
set_app_var link_library [list * $std_db $pad_db]

set rtl student_release/student_release/rtl
set report_dir reports/m2_tsmc28_20261106
file mkdir $report_dir

# Only the pad-top hierarchy. satellite_manager is not instantiated here and
# uses $countones, which DC K-2015.06 rejects (ELAB-939). The old multichannel
# tops, stream unpacker and serial acquisition are also outside this cone.
set skip_note {satellite_manager.sv receiver_multichannel.sv receiver_single.sv student_receiver_core.sv stream_unpacker.sv acquisition_serial.sv acquisition_pcps.sv fft4096_serial.sv}
set sources [list \
    $rtl/receiver_contract_pkg.sv \
    $rtl/b1i_prn_gen.sv \
    $rtl/code_nco.sv \
    $rtl/carrier_nco_mixer.sv \
    $rtl/epl_correlator.sv \
    $rtl/tracking_frontend.sv \
    $rtl/tracking_frontend_spaced.sv \
    $rtl/tracking_channel_minimal.sv \
    $rtl/nh20_sync.sv \
    $rtl/d1_word_sync.sv \
    $rtl/navigation_d1.sv \
    $rtl/tracking_record_framer.sv \
    $rtl/receiver_channel.sv \
    $rtl/acquisition_refine.sv \
    $rtl/bds_bb_6ch_core.sv \
    synth/m2_isolate/acquisition_pcps_blackbox.sv \
    rtl/bds_bb_6ch_pad_top.sv]
puts "M2_OUTSIDE_HIERARCHY $skip_note"

set_app_var search_path [concat [list $rtl .] $search_path]

puts "M2_FILELIST_BEGIN"
foreach path $sources { puts "M2_FILE $path" }
puts "M2_FILELIST_END"
puts "M2_ISOLATED acquisition_pcps fft4096_serial"

foreach path $sources {
    if {[analyze -format sverilog $path] == 0} {
        puts "M2_ANALYZE_FAIL $path"
        exit 1
    }
}
if {[elaborate bds_bb_6ch_pad_top] == 0} {
    puts "M2_ELABORATE_FAIL"
    exit 1
}
current_design bds_bb_6ch_pad_top
if {[link] == 0} {
    puts "M2_LINK_FAIL"
    exit 1
}
redirect $report_dir/link.rpt { link }

puts "M2_LINK_OK"
puts "M2_FREE_AFTER_LINK"
sh free -m

set_operating_conditions tt0p9v25c -library $std_lib
if {[catch {source constraints/bds_bb_6ch_pad_top_m2.sdc} sdc_error]} {
    puts "M2_SDC_FAIL $sdc_error"
    exit 1
}
puts "M2_SDC_SOURCED"

foreach_in_collection cell [get_cells -hier *] {
    set ref [get_attribute $cell ref_name]
    if {[string match "PD*" $ref] || [string match "PV*" $ref]} {
        set_dont_touch $cell
    }
}
set acq [get_cells -quiet core/acquisition]
if {[sizeof_collection $acq] > 0} {
    set_dont_touch $acq
    puts "M2_ACQUISITION_INSTANCE [get_attribute [index_collection $acq 0] ref_name]"
} else {
    puts "M2_ACQUISITION_INSTANCE_MISSING"
}
set_dont_use [get_lib_cells $pad_lib/*]

redirect $report_dir/check_design_pre.rpt { check_design }
puts "M2_FREE_BEFORE_COMPILE"
sh free -m

set compile_status [compile -map_effort low]
puts "M2_COMPILE_STATUS $compile_status"
puts "M2_COMPILE_DONE"

redirect $report_dir/check_design.rpt { check_design }
redirect $report_dir/area.rpt { report_area }
redirect $report_dir/resources.rpt { report_resources }
redirect $report_dir/qor.rpt { report_qor }
redirect $report_dir/timing_max.rpt {
    report_timing -delay max -max_paths 5 -nworst 1 -significant_digits 3
}
redirect $report_dir/timing_min.rpt {
    report_timing -delay min -max_paths 3 -nworst 1 -significant_digits 3
}
puts "M2_FREE_AFTER_COMPILE"
sh free -m
puts "M2_DC_PAD_DONE"
exit 0
