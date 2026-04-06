proc genGraph {} {
set top [get_attribute [current_design] name]
set o [open $top.gh w]
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
sh gzip $top.gh
sh cp $top.gh.gz rpts/
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

proc allFaninGraph {pin} {
set o [open allFaninGraph.gh w]
foreach_in_collection inst [all_fanin -to $pin -only_cells] {
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

proc find_cell_net {inst1 inst2} {
# Define the instance names
set instance1 $inst1
set instance2 $inst2

# Get the nets connected to the first instance
set nets1 [get_flat_nets -of [get_cells $instance1]]

# Get the nets connected to the second instance
set nets2 [get_flat_nets -of [get_cells $instance2]]

set nets12 [remove_from_collection $nets1 $nets2]
set nets_common [remove_from_collection $nets1 $nets12]
puts "$inst1 $inst2 [get_object_name [get_nets $nets_common -filter "net_type == signal"]]"
return [get_object_name [get_nets $nets_common -filter "net_type == signal"]]
}

proc show_cell_path {cell_list} {
# source run_dir/start_nodes.tcl
#  show_cell_path $path(1782)
set nets ""
for {set i 0} {$i < [expr [llength $cell_list] - 1]} {incr i} {
    if {[sizeof_collection [get_cells [lindex $cell_list $i]]] == 0} {
        continue
    }
    set nets "$nets [get_object_name [get_nets [find_cell_net [lindex $cell_list $i] [lindex $cell_list [expr $i + 1]]]]]"
}
puts "$nets"
change_selection [get_nets $nets]
}

proc report_reg2port {path} {
# source *.node.tcl
# report_reg2port path > report_reg2port.log
# cat report_reg2port.log | sort -k 2 -g
upvar $path arr
foreach p [array names arr] {
    set port ""
    set n_reg  0
    for {set i 0} {$i < [llength $arr($p)]} {incr i} {
        if {[sizeof_collection [get_cells [lindex $arr($p) $i]]]} {
            if {[get_attribute [get_cells [lindex $arr($p) $i]] is_sequential] == "true"} {
                incr n_reg
            }
        }
        if {[sizeof_collection [get_ports [lindex $arr($p) $i]]]} {
            set port [lindex $arr($p) $i]
        }

    }
    puts "$port $n_reg"
}
}
