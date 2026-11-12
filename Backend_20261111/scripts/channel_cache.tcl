# Isolate mapped design names before elaborating a different hierarchy.
proc channel_interface {design} {
    current_design $design
    set signature {}
    foreach_in_collection port [get_ports *] {
        lappend signature [list [get_object_name $port] [get_attribute $port direction]]
    }
    return [lsort $signature]
}

proc freeze_mapped_channel {prefix} {
    set channel tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1
    set signature [channel_interface $channel]
    if {![link]} {error "Mapped channel failed to link"}
    set leaves [get_cells -hier -filter {is_hierarchical == false}]
    if {[sizeof_collection [filter_collection $leaves {is_unmapped == true}]]} {
        error "Mapped channel already contains unmapped leaves"
    }
    set count [sizeof_collection $leaves]
    # -dont_link_with_original_name prevents the linker from resolving new RTL
    # references to a context-optimized mapped subdesign with the same old name.
    rename_design -prefix $prefix -update_links -dont_link_with_original_name [get_designs *]
    set reference ${prefix}${channel}
    if {[channel_interface $reference] ne $signature} {error "Namespace rename changed the channel interface"}
    if {![link]} {error "Renamed mapped channel failed to link"}
    if {[sizeof_collection [get_cells -hier -filter {is_hierarchical == false}]] != $count} {
        error "Namespace rename changed the mapped channel leaf count"
    }
    reset_design
    set_dont_touch [get_designs ${prefix}*] true
    puts "CHANNEL_CACHE_FROZEN REFERENCE=$reference LEAVES_WITH_CONSTANTS=$count UNMAPPED=0 PORTS=[llength $signature]"
    return $reference
}

proc attach_mapped_channels {reference} {
    set signature [channel_interface tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1]
    if {[channel_interface $reference] ne $signature} {error "Mapped channel interface mismatch"}
    current_design bds_bb_6ch_core
    set channels [get_cells -hier -filter {ref_name == tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1}]
    if {[sizeof_collection $channels] != 6} {error "Expected six original tracking instances"}
    change_link $channels $reference
    if {![link]} {error "Core failed to link after channel replacement"}
    set channels [get_cells -hier -filter "ref_name == $reference"]
    if {[sizeof_collection $channels] != 6} {error "Expected six isolated mapped tracking instances"}
    set_dont_touch $channels true
    set_boundary_optimization $channels false
    # Inspect the actual linked design after core elaboration, when collisions
    # in the old importer used to reintroduce GTECH below the cached channel.
    current_design $reference
    set leaves [get_cells -hier -filter {is_hierarchical == false}]
    if {[sizeof_collection [filter_collection $leaves {is_unmapped == true}]]} {
        error "Core linking reintroduced unmapped channel logic"
    }
    puts "CORE_DDC_INTERFACE_MATCH PORTS=[llength $signature] LINKED_CHANNEL_LEAVES=[sizeof_collection $leaves] UNMAPPED=0"
    set expected_leaves [expr {6 * [sizeof_collection $leaves]}]
    current_design bds_bb_6ch_core
    set linked_leaves [get_cells -hier -filter {is_hierarchical == false && full_name =~ */tracking/*}]
    set unmapped [filter_collection $linked_leaves {is_unmapped == true}]
    set gtech [filter_collection $linked_leaves {ref_name =~ GTECH*}]
    puts "CORE_ACTUAL_TRACKING_LEAVES=[sizeof_collection $linked_leaves] GTECH=[sizeof_collection $gtech] UNMAPPED=[sizeof_collection $unmapped]"
    if {[sizeof_collection $linked_leaves] != $expected_leaves || [sizeof_collection $unmapped] || [sizeof_collection $gtech]} {
        error "Actual core instance hierarchy differs from the mapped channel cache"
    }
}
