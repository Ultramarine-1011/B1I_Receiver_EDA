# Exact SS/FF library pairs provide the MAX/MIN delays of the same final netlist.
set_app_var sh_enable_page_mode false
set_host_options -max_cores 1
set standard [list $env(STD_TT) $env(STD_SS) $env(STD_FF)]
set pads {}
if {$env(LOCAL_PROBE) == 0} {set pads [list $env(PAD_TT) $env(PAD_SS) $env(PAD_FF)]}
foreach path [concat $standard $pads] {
    if {![file readable $path]} {error "Required library is unreadable: $path"}
    read_db $path
}
set_app_var target_library [list $env(STD_SS)]
set_app_var synthetic_library [list dw_foundation.sldb]
set pad_link {}
if {$env(LOCAL_PROBE) == 0} {set pad_link [list $env(PAD_SS) $env(PAD_FF)]}
set_app_var link_library [concat [list * $env(STD_SS) $env(STD_FF) dw_foundation.sldb] $pad_link]
if {[info exists env(MEMORY_MAX_DB)] && $env(MEMORY_MAX_DB) ne ""} {
    read_db $env(MEMORY_MAX_DB)
    read_db $env(MEMORY_MIN_DB)
    set_app_var link_library [concat $link_library [list $env(MEMORY_MAX_DB) $env(MEMORY_MIN_DB)]]
    set_min_library $env(MEMORY_MAX_DB) -min_version $env(MEMORY_MIN_DB)
}
set_min_library $env(STD_SS) -min_version $env(STD_FF)
if {$env(LOCAL_PROBE) == 0} {set_min_library $env(PAD_SS) -min_version $env(PAD_FF)}

proc apply_corners {} {
    global env
    set_operating_conditions -analysis_type bc_wc -max $env(STD_SS_OC) -min $env(STD_FF_OC) \
        -max_library $env(STD_SS_LIB) -min_library $env(STD_FF_LIB)
    if {$env(LOCAL_PROBE) == 0} {
        set pads [get_cells -hier -filter {ref_name =~ PD* || ref_name =~ PV*}]
        if {[sizeof_collection $pads]} {
            set_operating_conditions -analysis_type bc_wc -max $env(PAD_SS_OC) -min $env(PAD_FF_OC) \
                -max_library $env(PAD_SS_LIB) -min_library $env(PAD_FF_LIB) -object_list $pads
        }
    }
}
