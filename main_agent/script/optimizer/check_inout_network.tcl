proc genGraph {} {
set top [get_attribute [current_design] name]
set o [open /proj/cmb_pnr_vol21/simchen/vto9/$top.gh w]
foreach_in_collection inport [filter_collection [get_ports *] "direction == in"] {
    foreach_in_collection inpin [filter_collection [get_pins [all_fanout -from $inport -level 1 -flat]] "direction == in"] {
        puts $o "[get_object_name $inport]_inport [get_object_name [get_cells -of_objects $inpin]]"
    }
}
foreach_in_collection outport [filter_collection [get_ports *] "direction == out"] {
    foreach_in_collection outpin [filter_collection [get_pins [all_fanin -to $outport -level 1 -flat]] "direction == out"] {
        puts $o "[get_object_name [get_cells -of_objects $outpin]] [get_object_name $outport]_outport"
    }
}

foreach_in_collection inst [get_flat_cells *] {
    foreach_in_collection pin_out [filter_collection [get_pins -of_objects $inst] "direction == out"] {
        foreach_in_collection pin_d [filter_collection [all_fanout -flat -from $pin_out -levels 1] "direction == in"] {
            if {[regexp {/CP$|/SE$|/SI$} [get_object_name $pin_d]]} {
                puts "# skip [get_object_name $pin_d]"
            } else {
               puts $o "[get_object_name [get_cells -of_objects $pin_out]] [get_object_name [get_cells -of_objects $pin_d]]"
            }
        }
    }
}
close $o
}
proc check_inout_network {} {
set port "Dat0Src5_Pkt[191] "
foreach_in_collection cell0 [all_fanin -to [get_port $port] -flat -only_cells -startpoints_only] {
    set inpins [filter_collection [get_pins [get_object_name $cell0]/*] "direction == in && is_data_pin == True"]
    #puts "[get_object_name $inpins]"
    set n 0
    while {$n < 5} {
        incr n
        set inpins [trace_fanin $inpins]
        puts "$n $inpins"
    }
}

}

proc trace_fanin {pins} {
set inpins ""
foreach_in_collection cell0 [all_fanin -to [get_pins $pins] -flat -only_cells -startpoints_only] {
    foreach_in_collection inpin [filter_collection [get_pins [get_object_name $cell0]/*] "direction == in && is_data_pin == True"] {
        #puts [get_object_name $inpin]
        set inpins "$inpins [get_object_name $inpin]"
    }
}
return $inpins
}
