proc backend_reports {prefix} {
    global report_dir
    redirect $report_dir/${prefix}check_design.rpt {check_design}
    redirect $report_dir/${prefix}check_timing.rpt {check_timing}
    redirect $report_dir/${prefix}area.rpt {report_area -hierarchy}
    redirect $report_dir/${prefix}qor.rpt {report_qor}
    redirect $report_dir/${prefix}references.rpt {report_reference -hierarchy}
    redirect $report_dir/${prefix}hierarchy.rpt {report_hierarchy}
    redirect $report_dir/${prefix}design.rpt {report_design}
    redirect $report_dir/${prefix}clocks.rpt {report_clock}
    redirect $report_dir/${prefix}timing_max.rpt {report_timing -delay max -max_paths 20 -nworst 1 -significant_digits 6 -nets -transition_time -capacitance}
    redirect $report_dir/${prefix}timing_min.rpt {report_timing -delay min -max_paths 20 -nworst 1 -significant_digits 6}
    redirect $report_dir/${prefix}constraints.rpt {report_constraint -all_violators -significant_digits 6}
    redirect $report_dir/${prefix}fanout.rpt {report_net_fanout -high_fanout -threshold 64 -nosplit}
    set inputs [all_inputs]
    set outputs [all_outputs]
    # Clock objects select sequential boundaries without expanding thousands of
    # individual start/end pins into an expensive Cartesian path query.
    set clocks [all_clocks]
    foreach category {i2r r2r r2o i2o} from [list $inputs $clocks $clocks $inputs] to [list $clocks $clocks $outputs $outputs] {
        redirect $report_dir/${prefix}${category}.rpt {report_timing -from $from -to $to -delay max -max_paths 6 -significant_digits 6}
    }
    set async_pins [get_pins -hier -filter {is_async_pin == true}]
    if {[sizeof_collection $async_pins]} {
        redirect $report_dir/${prefix}recovery.rpt {report_timing -to $async_pins -delay max -max_paths 10 -significant_digits 6}
        redirect $report_dir/${prefix}removal.rpt {report_timing -to $async_pins -delay min -max_paths 10 -significant_digits 6}
    }
    set leaf [get_cells -hier -filter {is_hierarchical == false}]
    # DC represents constant drivers as **logic_0**/**logic_1** pseudo cells.
    # They have is_black_box=true and are excluded by report_qor's leaf count.
    set constants [filter_collection $leaf {ref_name == "**logic_0**" || ref_name == "**logic_1**"}]
    set leaf [remove_from_collection $leaf $constants]
    set unmapped [filter_collection $leaf {is_unmapped == true}]
    set blackboxes [get_cells -hier -filter {is_black_box == true}]
    set blackboxes [remove_from_collection $blackboxes $constants]
    puts "BACKEND_LEAF [sizeof_collection $leaf] UNMAPPED [sizeof_collection $unmapped] BLACKBOX [sizeof_collection $blackboxes] CONSTANT_PSEUDO [sizeof_collection $constants]"
    foreach_in_collection cell $blackboxes {
        puts "BACKEND_BLACKBOX [get_object_name $cell] [get_attribute $cell ref_name]"
    }
    set sink [open $report_dir/${prefix}leaf_libraries.txt w]
    puts $sink [lsort -unique [get_attribute $leaf ref_name]]
    close $sink
}
