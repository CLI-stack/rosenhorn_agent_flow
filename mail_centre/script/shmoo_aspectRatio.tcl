# Created on Mon Feb 12 13:30:23 2024 @author: Simon Chen simon1.chen@amd.com
proc shmoo_aspectRatio {ar h_grid h_offset v_grid} {
# for N6, sd = TS06_DST, h_offset = 6.84,h_offset = 2.28,v_grid = 4.8
# shmoo_aspectRatio 1.0 6.84 2.28 0.48
foreach_in_collection track [get_tracks] {
    set layer [get_attribute $track layer_name]
    set pitch_h($layer) [get_attribute $track space]
    set direction_h($layer) [get_attribute $track direction]
    puts "$layer $pitch_h($layer) $direction_h($layer)"
}
# choose the most common pitch for layers
foreach layer [array names direction_h] {
    if {$direction_h($layer) == "horizontal"} {
        if {[info exists h_pin_pitch_h($pitch_h($layer))]} {
            set h_pin_pitch_h($pitch_h($layer)) [expr $h_pin_pitch_h($pitch_h($layer)) + 1]
        } else {
             set h_pin_pitch_h($pitch_h($layer)) 1
        }
    } else {
        if {[info exists v_pin_pitch_h($pitch_h($layer))]} {
            set v_pin_pitch_h($pitch_h($layer)) [expr $v_pin_pitch_h($pitch_h($layer)) + 1]
        } else {
             set v_pin_pitch_h($pitch_h($layer)) 1
        }
    }
}
set n_h_pitch 0
set n_v_pitch 0
set h_pitch_layer ""
set v_pitch_layer ""
foreach pitch [array names h_pin_pitch_h] {
    if {$h_pin_pitch_h($pitch) > $n_h_pitch} {
        set n_h_pitch $h_pin_pitch_h($pitch)
        set h_pin_pitch $pitch
        foreach layer [array names pitch_h] {
            if {$pitch_h($layer) == $pitch} {
                set h_pitch_layer $layer
            }
        }
    }
}

foreach pitch [array names v_pin_pitch_h] {
    if {$v_pin_pitch_h($pitch) > $n_v_pitch} {
        set n_v_pitch $v_pin_pitch_h($pitch)
        set v_pin_pitch $pitch
        foreach layer [array names pitch_h] {
            if {$pitch_h($layer) == $pitch} {
                set v_pitch_layer $layer
            }
        }
    }
}
puts "$h_pitch_layer:$h_pin_pitch $h_pitch_layer:$v_pin_pitch"
set site_name "TS06_DST"
foreach_in_collection site [get_site_rows] {
    set site_name [get_attribute $site site_name]
}

set od [open aspectratio_die.tcl w]
set o [open aspectratio_pin.tcl w]
set bbox [get_attribute [current_design ] boundary_bbox]
set llx [lindex $bbox 0 0]
set lly [lindex $bbox 0 1]
set urx [lindex $bbox 1 0]
set ury [lindex $bbox 1 1]
set w [expr $urx - $llx]
set h [expr $ury - $lly]
set area [expr $w * $h]
set new_h [expr sqrt($area/$ar)]
set new_w [expr $new_h * $ar]
set new_w [expr (round(round($new_w / $h_grid)/2)*2 + 1)*$h_grid + $h_offset]
set new_w [expr round(($new_w / $h_grid) )*$h_grid + $h_offset]
set new_h [expr round(($new_h / $v_grid))*$v_grid]
set p0  "[expr $new_w/2*(-1)] [expr $new_h/2*(-1)]"
set p1 "[expr $new_w/2*(-1)] [expr $new_h/2]"
set p2 "[expr $new_w/2] [expr $new_h/2]"
set p3 "[expr $new_w/2] [expr $new_h/2*(-1)]"
set new_llx [lindex $p0 0]
set new_lly [lindex $p0 1]
set new_urx [lindex $p2 0]
set new_ury [lindex $p2 1]



set pin_l_list  ""
set pin_r_list  ""
set pin_t_list  ""
set pin_b_list  ""
set pin_c_list  ""

# sort left/right/bottom/top side ports
foreach_in_collection port [get_ports *] {
    set pin_name [get_object_name $port]
    set pin_bbox [get_attribute $port bbox]
    if {[llength [get_attribute $port layer]] == 0} {
        continue
    }
    set pin_layer($pin_name) [get_attribute $port layer_name]
    set pin_llx [lindex $pin_bbox 0 0]
    set pin_lly [lindex $pin_bbox 0 1]
    set pin_urx [lindex $pin_bbox 1 0]
    set pin_ury [lindex $pin_bbox 1 1]
    set pin_width [expr $pin_urx - $pin_llx]
    set pin_height [expr $pin_ury - $pin_lly]
    if {$pin_width > $pin_height} {
        set pin_llx_test [expr $pin_llx - 10]
        if {[outofboundary $pin_llx_test $pin_lly] > 0} {
            set pin_l_list  "$pin_l_list $pin_name"
            #puts "$pin_llx_test $pin_lly $pin_name"
            continue
        }
        set pin_llx_test [expr $pin_llx + 10]
        if {[outofboundary $pin_llx_test $pin_lly] > 0} {
            set pin_r_list  "$pin_r_list $pin_name"
            #puts "$pin_llx_test $pin_lly $pin_name"
            continue
        }
        # pushdown clock pin
        set pin_c_list  "$pin_c_list $pin_name"
    } else {
        set pin_lly_test [expr $pin_lly - 10]
        if {[outofboundary $pin_llx $pin_lly_test] > 0} {
            set pin_b_list  "$pin_b_list $pin_name"
            continue
        }
        set pin_lly_test [expr $pin_lly + 10]
        if {[outofboundary $pin_llx $pin_lly_test] > 0} {
            set pin_t_list "$pin_t_list $pin_name"
            #puts "$pin_llx $pin_lly_test $pin_name"
            continue
        }
        # pushdown clock pin
        set pin_c_list "$pin_c_list $pin_name"
    }
}

# process center pin
puts "# process center pin"
foreach port $pin_c_list {
    set layer_name [get_attribute $port layer_name]
    set pin_llx [lindex $pin_bbox 0 0]
    set pin_lly [lindex $pin_bbox 0 1]
    set pin_urx [lindex $pin_bbox 1 0]
    set pin_ury [lindex $pin_bbox 1 1]
    set new_pin_llx $pin_llx
    set new_pin_lly $pin_lly
    set new_pin_urx $pin_urx
    set new_pin_ury $pin_ury
    if {$pin_llx < $new_llx} {
        set new_pin_llx [expr $new_llx + 10]
    }
    if {$pin_lly < $new_lly} {
        set new_pin_lly [expr $new_lly + 10]
    }
    if {$pin_llx > $new_urx} {
        set new_pin_llx [expr $new_urx - 10]
    }
    if {$pin_lly > $new_ury} {
        set new_pin_lly [expr $new_ury - 10]
    }

    set new_pin_urx [expr $new_pin_llx + $pin_urx - $pin_llx]
    set new_pin_ury [expr $new_pin_lly + $pin_ury - $pin_lly]
    puts $o "fastRePlacePin $port {{$new_pin_llx $new_pin_lly} {$new_pin_urx $new_pin_ury}} $layer_name"

}

# process left side
set x [lindex $p0 0]
puts "# process left side [llength $pin_l_list] ports."
if {[llength $pin_l_list] > 0} {
    lassign [resize_ports $pin_l_list $w $new_w $h_pin_pitch $v_pin_pitch] pin_loc_l new_pin_list
    set new_pin_list [lsort -increasing -real $new_pin_list]
    set min [lindex $new_pin_list 0]
    set max [lindex $new_pin_list end]
    set offset [expr ($max + $min) / 2 + $v_pin_pitch / 4]
    array set new_pin_loc_l $pin_loc_l
    foreach loc [array names new_pin_loc_l] {
        foreach port $new_pin_loc_l($loc) {
            set pin_bbox [get_attribute $port bbox]
            set pin_llx [lindex $pin_bbox 0 0]
            set pin_lly [lindex $pin_bbox 0 1]
            set pin_urx [lindex $pin_bbox 1 0]
            set pin_ury [lindex $pin_bbox 1 1]
            set layer_name [get_attribute $port layer_name]
            if {[get_attribute [get_layers $layer_name] routing_direction] == "horizontal"} {
                set llx $x
                set lly [expr $loc - $offset]
                set urx [expr $llx + $pin_urx - $pin_llx]
                set ury [expr $lly + $pin_ury - $pin_lly]
                puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} $layer_name"
            }

        }
    }
}

# process right side
set x [lindex $p2 0]
puts "# process right side [llength $pin_r_list] ports."
if {[llength $pin_r_list] > 0} {
    lassign [resize_ports $pin_r_list $w $new_w $h_pin_pitch $v_pin_pitch] pin_loc_r new_pin_list
    set new_pin_list [lsort -increasing -real $new_pin_list]
    set min [lindex $new_pin_list 0]
    set max [lindex $new_pin_list end]
    set offset [expr ($max + $min) / 2 + $v_pin_pitch / 4]
    array set new_pin_loc_r $pin_loc_r
    foreach loc [array names new_pin_loc_r] {
        foreach port $new_pin_loc_r($loc) {
            set pin_bbox [get_attribute $port bbox]
            set pin_llx [lindex $pin_bbox 0 0]
            set pin_lly [lindex $pin_bbox 0 1]
            set pin_urx [lindex $pin_bbox 1 0]
            set pin_ury [lindex $pin_bbox 1 1]
            set layer_name [get_attribute $port layer_name]
            if {[get_attribute [get_layers $layer_name] routing_direction] == "horizontal"} {
                set llx $x
                set lly [expr $loc - $offset]
                set urx [expr $llx + $pin_urx - $pin_llx]
                set ury [expr $lly + $pin_ury - $pin_lly]
                puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} $layer_name"
            }
        }

    }
}

## process bottom side
puts "# process bottom side [llength $pin_b_list] ports."
set y [lindex $p3 1]
if {[llength $pin_b_list] > 0} {
    lassign [resize_ports $pin_b_list $w $new_w $h_pin_pitch $v_pin_pitch] pin_loc_b new_pin_list
    set new_pin_list [lsort -increasing -real $new_pin_list]
    set min [lindex $new_pin_list 0]
    set max [lindex $new_pin_list end]
    set offset [expr ($max + $min) / 2 + $h_pin_pitch / 4]
    array set new_pin_loc_b $pin_loc_b
    foreach loc [array names new_pin_loc_b] {
        foreach port $new_pin_loc_b($loc) {
            set pin_bbox [get_attribute $port bbox]
            set pin_llx [lindex $pin_bbox 0 0]
            set pin_lly [lindex $pin_bbox 0 1]
            set pin_urx [lindex $pin_bbox 1 0]
            set pin_ury [lindex $pin_bbox 1 1]
            set layer_name [get_attribute $port layer_name]
            if {[get_attribute [get_layers $layer_name] routing_direction] == "vertical"} {
                set llx [expr $loc - $offset]
                set lly $y
                set urx [expr $llx + $pin_urx - $pin_llx]
                set ury [expr $lly + $pin_ury - $pin_lly]
                puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} $layer_name"
            }

        }
    }
}
## process top side
puts "# process top side [llength $pin_t_list] ports."
if {[llength $pin_t_list] > 0} {
    set y [lindex $p1 1]
    lassign [resize_ports $pin_t_list $w $new_w $h_pin_pitch $v_pin_pitch] pin_loc_t new_pin_list
    set new_pin_list [lsort -increasing -real $new_pin_list]
    set min [lindex $new_pin_list 0]
    set max [lindex $new_pin_list end]
    set offset [expr ($max + $min) / 2 + $h_pin_pitch / 4]
    array set new_pin_loc_t $pin_loc_t
    foreach loc [array names new_pin_loc_t] {
        foreach port $new_pin_loc_t($loc) {
            set pin_bbox [get_attribute $port bbox]
            set pin_llx [lindex $pin_bbox 0 0]
            set pin_lly [lindex $pin_bbox 0 1]
            set pin_urx [lindex $pin_bbox 1 0]
            set pin_ury [lindex $pin_bbox 1 1]
            set layer_name [get_attribute $port layer_name]
            if {[get_attribute [get_layers $layer_name] routing_direction] == "vertical"} {
                set llx [expr $loc - $offset]
                set lly $y
                set urx [expr $llx + $pin_urx - $pin_llx]
                set ury [expr $lly + $pin_ury - $pin_lly]
                puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} $layer_name"
            }
         
        } 
    }
}
puts $od "initialize_floorplan -boundary \{\{$p0\} \{$p1\} \{$p2\} \{$p3\}\} -site_def $site_name -pin_snap wire_track"
close $od
close $o
source aspectratio_die.tcl  
### process pins
source aspectratio_pin.tcl 

}

proc resize_ports {ports orig_length new_length h_pin_pitch v_pin_pitch} {
# pin_dir = "h" means pin dirction is horizontal.
# bloat = new length / original length
set pin_dir  ""
set bloat [expr $new_length / $orig_length]
#puts "orig_length new_length bloat"
#puts "$orig_length $new_length $bloat"
#puts "# resize ports: [llength $ports]"

set new_pin_list ""
foreach_in_collection port [get_ports $ports] {
    set pin_name [get_object_name $port]
    set pin_bbox [get_attribute $port bbox]
    if {[llength [get_attribute $port layer]] == 0} {
        continue
    }
    set pin_layer($pin_name) [get_attribute $port layer_name]
    set pin_llx [lindex $pin_bbox 0 0]
    set pin_lly [lindex $pin_bbox 0 1]
    set pin_urx [lindex $pin_bbox 1 0]
    set pin_ury [lindex $pin_bbox 1 1]
    set pin_width [expr $pin_urx - $pin_llx]
    set pin_height [expr $pin_ury - $pin_lly]
    set pin_width_h($pin_name) $pin_width
    set pin_height_h($pin_name) $pin_height

    if {$pin_width > $pin_height} {
        set pin_dir "h"
        set pin($pin_name) $pin_lly
        if {[info exists pin_loc($pin_lly)]} {
            set pin_loc($pin_lly) "$pin_loc($pin_lly) $pin_name"
        } else {
            set pin_loc($pin_lly) $pin_name
        }
    } else {
        set pin_dir "v"
        set pin($pin_name) $pin_llx
        if {[info exists pin_loc($pin_llx)]} {
            set pin_loc($pin_llx) "$pin_loc($pin_llx) $pin_name"
        } else {
            set pin_loc($pin_llx) "$pin_name"
        }
    }
}
# check available pin spacing
set pin_list ""
foreach loc [array names pin_loc] {
    set pin_list "$pin_list $loc"
}
set pin_list [lsort -increasing -real $pin_list]
if {$pin_dir == "h"} {
    set pin_slot [expr [llength $pin_list] * $h_pin_pitch * 2 ]
    puts "$new_length $pin_slot"
} else {
    set pin_slot [expr [llength $pin_list] * $v_pin_pitch * 2]
    puts "$new_length $pin_slot"
}
if {$new_length < [expr $pin_slot + 10] } {
    puts "ERROR: No enough space for pins!"
    exit
}
set margin_bloat [expr ($orig_length - $new_length) / ($orig_length - $pin_slot - 10) ]
if {$bloat < 1} {
    for { set i 0 } { $i < [llength $pin_list] } {incr i} {
        if {$i == 0} {
            set cur_loc [lindex $pin_list $i]
            set new_pin_list $cur_loc
            set new_pin_loc($cur_loc) "$pin_loc($cur_loc)"
            continue
        }
        set cur_loc [lindex $pin_list $i]
        set pre_loc [lindex $pin_list [expr $i - 1]]
        set spacing [expr $cur_loc - $pre_loc]
            
        set spacing [expr $spacing * $margin_bloat]
        if {$pin_dir == "h"} {
            if {$spacing <= [expr $h_pin_pitch * 2] } {
                set spacing [expr $h_pin_pitch * 2]
            }
            set spacing [expr round($spacing / $h_pin_pitch) * $h_pin_pitch]
        } else {
            if {$spacing <= [expr $v_pin_pitch * 2] } {
                set spacing [expr $v_pin_pitch * 2]
            }
            set spacing [expr round($spacing / $v_pin_pitch) * $v_pin_pitch]
        }
        set pre_loc [lindex $new_pin_list [expr $i - 1]]
        set new_loc [expr $pre_loc + $spacing]
        set new_pin_list "$new_pin_list $new_loc"
        set new_pin_loc($new_loc) "$pin_loc($cur_loc)"
    }
    return [list [array get new_pin_loc] $new_pin_list]
} else {
    return [list [array get pin_loc] $pin_list]

}

}


proc outofboundary {x y} {
    create_pin_blockage -boundary [get_attribute [current_design ] boundary]
    if {[sizeof_collection [get_pin_blockages -quiet -at "$x $y"]] > 0} {
        remove_pin_blockages -all 
        return 0
    } else {
        remove_pin_blockages -all 
        return 1
    }
}

proc fastRePlacePin {pin_name bbox layer} {
unplacePort $pin_name
set shape [create_shape -shape_type rect -boundary $bbox -layer $layer]
set terminal [create_terminal -port $pin_name -object $shape -direction all]
set_attribute [get_ports $pin_name] physical_status fixed
}

proc unplacePort {ports} {
foreach_in_collection port [get_ports $ports] {
    if {[regexp VSS [get_attribute $port full_name]] && [regexp FE_FEED [get_attribute $port full_name]] == 0 && [get_attribute [get_ports $port] layer_name] == "M11"} {
        continue
    }
    if {[regexp VDD [get_attribute $port full_name]] && [regexp FE_FEED [get_attribute $port full_name]] == 0 && [get_attribute [get_ports $port] layer_name] == "M11"} {
        continue
    }
    if {[sizeof_collection [get_shapes -quiet -of_objects [get_terminals -quiet -of_objects [get_ports $port]]]] != 0} {
        remove_shapes [get_shapes -of_objects [get_terminals -of_objects [get_ports $port]]]
        set_attribute [get_ports $port] physical_status unplaced
    }
}
}

