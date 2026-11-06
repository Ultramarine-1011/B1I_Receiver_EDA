# Compare small non-zero ROM codings and one PAD link against TSMC28 TT.
# Run from the directory that contains tiny.mem and rom_styles.sv.
set_app_var sh_enable_page_mode false
set std_db /home/share/libs/tsmc28/logic/selected_db/tcbn28hpcplusbwp40p140tt0p9v25c.db
set pad_db /home/share/libs/tsmc28/pad/timing_nldm/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn28hpcpgv18_170a/tphn28hpcpgv18tt0p9v1p8v25c.db
set_app_var target_library [list $std_db]
set_app_var link_library [list * $std_db $pad_db]
set report_dir reports
file mkdir $report_dir

proc dump_port_bits {name width} {
    for {set i [expr {$width - 1}]} {$i >= 0} {incr i -1} {
        set ports [get_ports -quiet "${name}\[${i}\]"]
        if {[sizeof_collection $ports] == 0} {
            puts "BIT $name $i NO_PORT"
            continue
        }
        set refs {}
        foreach_in_collection n [get_nets -quiet -of_objects $ports] {
            foreach_in_collection c [get_cells -quiet -of_objects $n] {
                lappend refs [get_attribute $c ref_name]
            }
        }
        puts "BIT $name $i $refs"
    }
}

proc compile_rom {top} {
    global report_dir
    remove_design -all
    if {[analyze -format sverilog rom_styles.sv] == 0} {
        puts "ROM_ANALYZE_FAIL $top"
        return
    }
    if {[elaborate $top] == 0} {
        puts "ROM_ELABORATE_FAIL $top"
        return
    }
    current_design $top
    if {[link] == 0} {
        puts "ROM_LINK_FAIL $top"
        return
    }
    create_clock -name clk -period 10
    if {[compile] == 0} {
        puts "ROM_COMPILE_FAIL $top"
        return
    }
    set area_file $report_dir/${top}_area.rpt
    redirect $area_file { report_area }
    redirect $report_dir/${top}_cells.rpt { report_reference }
    write -format verilog -hierarchy -output $report_dir/${top}_mapped.v
    puts "ROM_CONST_BEGIN $top"
    dump_port_bits y1 32
    dump_port_bits y15 32
    puts "ROM_CONST_END $top"
    set ncells [sizeof_collection [get_cells -quiet -hier *]]
    puts "ROM_COMPILE_DONE $top cells=$ncells"
}

foreach top {rom_readmem rom_case rom_func rom_param} {
    puts "ROM_STYLE_BEGIN $top"
    compile_rom $top
    puts "ROM_STYLE_END $top"
}

puts "PAD_LINK_BEGIN"
remove_design -all
if {[analyze -format sverilog rom_styles.sv] == 0} {
    puts "PAD_ANALYZE_FAIL"
    exit 1
}
foreach top {pad_logic_probe pad_pg_probe} {
    set elab_ok [elaborate $top]
    puts "PAD_ELABORATE $top $elab_ok"
    if {$elab_ok != 0} {
        current_design $top
        set link_ok [link]
        puts "PAD_LINK $top $link_ok"
        redirect $report_dir/${top}_ref.rpt { report_reference }
        redirect $report_dir/${top}_pins.rpt {
            foreach_in_collection c [get_cells -quiet *] {
                puts "CELL [get_attribute $c full_name] ref=[get_attribute $c ref_name]"
                foreach_in_collection p [get_pins -quiet -of_objects $c] {
                    puts "  PIN [get_attribute $p lib_pin_name] dir=[get_attribute $p direction]"
                }
            }
        }
    }
    remove_design -all
}
puts "PAD_LINK_END"
puts "M2_ROM_PROBE_DONE"
exit 0
