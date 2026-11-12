# Run with the six-channel core selected. Keep its mapped tracking hierarchy.
proc prune_core_records {{keep_navigation 0}} {
    set wrappers [get_cells -filter {ref_name =~ receiver_channel*}]
    if {[sizeof_collection $wrappers] != 6} {error "Expected six receiver wrappers"}
    ungroup $wrappers
    set navigation [get_cells -hier -filter {full_name =~ */navigation}]
    if {[sizeof_collection $navigation] != 6} {error "Expected six navigation blocks"}
    if {!$keep_navigation} {ungroup $navigation -flatten}
    set framers [get_cells -hier -filter {ref_name == tracking_record_framer}]
    if {[sizeof_collection $framers]} {ungroup $framers -flatten}
    set channels [get_cells -hier -filter {ref_name =~ *tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1}]
    if {[sizeof_collection $channels] != 6} {error "Tracking boundaries changed during wrapper flattening"}
    puts "CORE_WRAPPERS_FLATTENED TRACKING_PRESERVED=6 UNUSED_RECORD_LOGIC_ELIGIBLE_FOR_PRUNING"
}
