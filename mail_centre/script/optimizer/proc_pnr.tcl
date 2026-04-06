# Created on Fri May 25 13:30:23 2025
# @author: Simon Chen; simon1.chen@amd.com

# Copyright (c) 2024 Chen, Simon ; simon1.chen@amd.com;  Advanced Micro Devices, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

proc writePortDef {def} {
set ports [get_ports * -filter "physical_status != unplaced"]
set_attribute [get_ports $ports] physical_status fixed
write_def -objects [get_ports $ports] -fixed_vias_only -compress gzip -units 2000 -version 5.7 $def
}

proc writeSelectedPortDef {def} {
write_def -objects [get_selection] -fixed_vias_only -compress gzip -units 2000 -version 5.7 $def
}
proc get_macro_info {dir} {
set o [open $dir/get_macro_info.log w]
puts "instance name,bbox"
puts $o "instance name,bbox"
foreach_in_collection macro [get_flat_cells -all -filter "is_hard_macro"] {
    puts "[get_object_name $macro],[get_attribute $macro bbox]"
    puts $o "[get_object_name $macro],[get_attribute $macro bbox]"
}
puts "top,[get_attribute [current_design] boundary]"
puts $o "top,[get_attribute [current_design] boundary]"
close $o
}

proc placeSpecificPins {ports} {
set_individual_pin_constraints -ports * -length 0.4 -pin_spacing 2 -allowed_layers {M6 M7 M8 M9 M10 M11}
set_block_pin_constraints -allowed_layers {M6 M7 M8 M9 M10 M11} -self
if {[sizeof_collection $ports] > 0} {
    place_pins -ports [get_ports $ports]
}
}

proc placeUplacedPins {} {
set is_vdci [regexp "vdci" [get_attribute [current_design] name]]
if {$is_vdci == 1} {
    puts "# Vdci tile not place unplaced pins"
    return 0
}

set ports [get_ports * -filter "physical_status == unplaced"]
set_individual_pin_constraints -ports * -length 0.4 -pin_spacing 2 -allowed_layers {M6 M7 M8 M9 M10 M11}
set_block_pin_constraints -allowed_layers {M6 M7 M8 M9 M10 M11} -self

if {[sizeof_collection $ports] > 0} {
    puts "# ERROR: found unplaced ports [get_object_name $ports]"
    place_pins -ports [get_ports $ports]
}
}

proc so {obj} {
if {[sizeof_collection [get_cells -quiet $obj]]} {
    set obj_e [get_cells $obj]
} elseif {[sizeof_collection [get_pins -quiet $obj]]} {
    set obj_e [get_pins $obj]
} elseif {[sizeof_collection [get_ports -quiet $obj]]} {
    set obj_e [get_ports $obj]
} elseif {[sizeof_collection [get_nets -quiet $obj]]} {
    set obj_e [get_nets $obj]
} else {
    puts "# $obj not recognized."
}
change_selection $obj_e
}


proc checkDiesize {} {
set margin 0.2
set w_macro_max  0
set h_macro_max  0
set macro_area 0
set boundary_margin -0.1
set gm_core [create_geo_mask -objects [get_attribute [current_design] boundary_bbox]]
set gm_core_margin [resize_polygons -objects $gm_core -size $boundary_margin]
foreach_in_collection macro [get_cells -hierarchical * -filter "design_type == macro" ] {
    set macro_area [expr $macro_area+[get_attribute $macro area]]
    set macro_bbox [get_attribute $macro boundary_bbox]
    set gm_macro [create_geo_mask -objects $macro_bbox]
    set gm_macro_inside [compute_polygons -objects1 $gm_core -objects2 $gm_macro -operation AND]
    set area_and [compute_area [compute_polygons -objects1 $gm_core -objects2 $gm_macro -operation AND]]
    set gm_outside [compute_polygons -objects1 $gm_macro -objects2 $gm_macro_inside -operation NOT]
    set bbox [get_attribute $gm_outside bbox]
    if {$macro_area > $area_and} {
        if {$bbox != "**INVALID**"} {
            puts "ERROR: [get_object_name $macro] $bbox macro out of boundary. [get_attribute $gm_core bbox]"
        }
    }
    set area_and [compute_area [compute_polygons -objects1 $gm_core_margin -objects2 $gm_macro -operation AND]]
    set gm_macro_inside [compute_polygons -objects1 $gm_core_margin -objects2 $gm_macro -operation AND]
    set gm_outside [compute_polygons -objects1 $gm_macro -objects2 $gm_macro_inside -operation NOT]
    set bbox [get_attribute $gm_outside bbox]
    if {$macro_area > $area_and} {
        if {$bbox != "**INVALID**"} {
            puts "WARNING: [get_object_name $macro] $bbox  macro too close to boundary . [get_attribute $gm_core_margin bbox]"
        }
    }

}

set core_area [get_attribute [current_design] core_area_area]
set cell_area 0
foreach_in_collection cell [get_cells -hierarchical * -filter "design_type == lib_cell" ] {
    set cell_area [expr $cell_area+[get_attribute $cell area]]
}
set util [expr $cell_area / ($core_area - $macro_area)]
if {$util > 0.7} {
    puts "Error: utilization $util too high (>70%)."
}
puts "$util $w_macro_max $h_macro_max"
}

proc createEdgeBkg {margin} {
set o [open createEdgeBkg.tcl w]
set bbox [get_attribute [current_design] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]
set llx $llx_tile
set lly $lly_tile
set urx $urx_tile
set ury [expr $lly_tile + $margin]
puts $o "create_placement_blockage -type hard_macro -boundary {{$llx $lly} {$urx $ury}}"
set llx $llx_tile
set lly [expr $ury_tile - $margin]
set urx $urx_tile
set ury $ury_tile
puts $o "create_placement_blockage -type hard_macro -boundary {{$llx $lly} {$urx $ury}}"
set llx $llx_tile
set lly $lly_tile
set urx [expr $llx_tile + $margin]
set ury $ury_tile
puts $o "create_placement_blockage -type hard_macro -boundary {{$llx $lly} {$urx $ury}}"
set llx [expr $urx_tile - $margin]
set lly $lly_tile
set urx $urx_tile
set ury $ury_tile
puts $o "create_placement_blockage -type hard_macro -boundary {{$llx $lly} {$urx $ury}}"
close $o
source createEdgeBkg.tcl
}

proc checkMacroOob {} {
echo "# check if macro out of boundary!"
set tile_bbox [get_attribute [current_design] boundary_bbox]

foreach_in_collection macro [get_cells -hierarchical * -filter "design_type == macro" ] {
    set macro_bbox [get_attribute $macro boundary_bbox]

}


}

proc setCenterOrign {} {
set bbox [get_attribute [current_design] boundary_bbox]
set center_x [format "%0.4f" [expr 0.5 * ([lindex $bbox 0 0] + [lindex $bbox 1 0])]]
set center_y [format "%0.4f" [expr 0.5 * ([lindex $bbox 0 1] + [lindex $bbox 1 1])]]
move_block_origin -to "$center_x $center_y" [current_design]
puts "INFO: Moving tile origin to ($center_x,$center_y)"
}

proc genPinPairList {} {
set o [open data/genPinPairList.rpt w]
foreach_in_collection port [get_ports *] {
    foreach w [regsub -all {_} [get_object_name $port] { }] {
        if {[string length $w] < 3}  {
            continue
        }
        if {[info exists w_h($w)]} {
            continue
        } else {
            set w_h($w) 1
        }
        if {[sizeof_collection [get_ports *$w*]] == 2} {
            puts [get_object_name [get_ports *$w*]]
            set pin_list([get_object_name [get_ports *$w*]]) 1
        }
    }
}
foreach ports [array names pin_list] {
    set ports [regsub -all "{" $ports {}]
    set ports [regsub -all "}" $ports {}]
    puts $o $ports
}
close $o
}

proc unfixMem {} {
if {[sizeof_collection [get_flat_cells -all -filter "is_memory_cell == True"]]} {
    set_fixed_objects [get_flat_cells -all -filter "is_memory_cell == True"] -unfix
    remove_placement_blockages -all
    remove_routing_blockages -all
}
}

proc dumpMacroLoc {} {
foreach_in_collection macro [get_cells -hierarchical * -filter "design_type == macro" ] {
    set bbox [get_attribute $macro boundary_bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set urx [lindex $bbox 1 0]
    set ury [lindex $bbox 1 1]
    puts "[get_object_name $macro] [get_attribute $macro ref_name] $llx $lly"

}
}

proc rotateMacro {} {
set y_grid 0.286
foreach_in_collection macro [get_cells -hierarchical * -filter "design_type == macro" ] {
    set bbox [get_attribute $macro boundary_bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set urx [lindex $bbox 1 0]
    set ury [lindex $bbox 1 1]
    set height_test [expr ($ury - $lly)/$y_grid]
    if {[regexp {\..*[1-9]} $height_test]} {
        puts "# Rotate [get_object_name $macro] due to height is not multiples of $y_grid"
        set_fixed_objects [get_cells $macro] -unfix
        rotate_objects [get_cells $macro] -orient R0
    }

}
}

proc snapMacro {x_grid x_offset  y_grid y_offset} {
set bbox [get_attribute [current_design ] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]

foreach_in_collection macro [get_cells -hierarchical * -filter "design_type == macro" ] {
    set bbox [get_attribute $macro boundary_bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set urx [lindex $bbox 1 0]
    set ury [lindex $bbox 1 1]
    set llx_test [expr ($llx - $llx_tile - $x_offset)/$x_grid]
    set lly_test [expr ($lly - $lly_tile - $y_offset)/$y_grid]
    if {[regexp {\..*[1-9]} $llx_test]} {
        puts "# snap x $llx for [get_object_name $macro]"
        set llx [expr round(($llx - $llx_tile - $x_offset)/$x_grid)*$x_grid + $llx_tile + $x_offset]
        #set llx [expr round($llx/$x_grid)*$x_grid]
    }
    if {[regexp {\..*[1-9]} $lly_test]} {
        puts "# snap y $lly for [get_object_name $macro]"
        set lly [expr round(($lly - $lly_tile - $y_offset)/$y_grid)*$y_grid + $lly_tile + $y_offset]
    }
    eval "set_cell_location -coordinates {$llx $lly} [get_object_name $macro] -ignore_fixed -fixed"

}
}

proc snapMacros {macros x_grid x_offset  y_grid y_offset} {
set bbox [get_attribute [current_design ] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]

foreach_in_collection macro [get_cells $macros] {
    set bbox [get_attribute $macro boundary_bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set urx [lindex $bbox 1 0]
    set ury [lindex $bbox 1 1]
    set llx_test [expr ($llx - $llx_tile - $x_offset)/$x_grid]
    set lly_test [expr ($lly - $lly_tile - $y_offset)/$y_grid]
    if {[regexp {\..*[1-9]} $llx_test]} {
        puts "# snap x $llx for [get_object_name $macro]"
        set llx [expr round(($llx - $llx_tile - $x_offset)/$x_grid)*$x_grid + $llx_tile + $x_offset]
        #set llx [expr round($llx/$x_grid)*$x_grid]
    }
    if {[regexp {\..*[1-9]} $lly_test]} {
        puts "# snap y $lly for [get_object_name $macro]"
        set lly [expr round(($lly - $lly_tile - $y_offset)/$y_grid)*$y_grid + $lly_tile + $y_offset]
    }
    eval "set_cell_location -coordinates {$llx $lly} [get_object_name $macro] -ignore_fixed -fixed"

}
}

proc addMacroBkg {macros x_keepout y_keepout x_grid x_offset y_grid y_offset} {
foreach_in_collection macro [get_cells $macros] {
    set bbox [get_attribute [current_design ] boundary_bbox]
    set llx_tile [lindex $bbox 0 0]
    set lly_tile [lindex $bbox 0 1]
    set urx_tile [lindex $bbox 1 0]
    set ury_tile [lindex $bbox 1 1]

    set bbox [get_attribute $macro boundary_bbox]
    set llx [expr [lindex $bbox 0 0] - $x_keepout]
    set lly [expr [lindex $bbox 0 1] - $y_keepout]
    set urx [expr [lindex $bbox 1 0] + $x_keepout]
    set ury [expr [lindex $bbox 1 1] + $y_keepout]
    set lly_test [expr ($lly - $lly_tile - $y_offset)/$y_grid]
    if {[regexp {\..*[1-9]} $lly_test]} {
        puts "# snap y $lly for [get_object_name $macro]"
        set lly [expr round(($lly - $lly_tile - $y_offset)/$y_grid)*$y_grid + $lly_tile + $y_offset]
        puts "# new snap lly llry"
    }
    set ury_test [expr ($ury_tile - $ury - $y_offset)/$y_grid]
    if {[regexp {\..*[1-9]} $ury_test]} {
        puts "# snap y $ury for [get_object_name $macro]"
        set ury [expr $ury_tile - round(($ury_tile - $ury - $y_offset)/$y_grid)*$y_grid - $y_offset]
        puts "# new snap ury $ury"
    }

    eval "create_placement_blockage -type hard -boundary {{$llx $lly} {$llx $ury} {$urx $ury} {$urx $lly}}"

}
}


proc unfixMacro {macros} {
set x_margin 7.0
set y_margin 2.0
foreach macro $macros {
    puts "# Unfix $macro"
    set macro_inst [get_flat_cells -quiet -all -filter "ref_name == $macro"]
    if {[sizeof_collection $macro_inst] > 0} {
        foreach_in_collection inst $macro_inst {
            set bbox [get_attribute $inst boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            set x [expr $llx - ($llx + $urx)/2] 
            set y [expr $lly - ($lly + $ury)/2]
            #set x 0.0
            #set y 0.0
            if {[get_attribute [get_cells $inst] physical_status] == "unplaced"} {
                set_fixed_objects $inst -unfix
                set_placement_status unplaced $inst
                eval "set_cell_location -coordinates {$x $y} $inst"
            } else {
                set_fixed_objects $inst -unfix
            }
        
            set bbox [get_attribute $inst boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            set bbox_margin "\{[expr $llx - $x_margin] [expr $lly - $y_margin]\} \{[expr $urx + $x_margin] [expr $ury + $y_margin]\}"
            set overlap_inst [get_cells -intersect $bbox_margin]
            set overlap_inst_itersect [get_cells -intersect $bbox_margin]
            set overlap_inst_within [get_cells -within $bbox_margin]
            if {[sizeof_collection $overlap_inst_itersect] > 0 || [sizeof_collection $overlap_inst_within] > 1} {
                #puts "[get_object_name $overlap_inst] overlap."
                set n_step 100
                set step  5
                set overlap 1
                for { set i 0 } { $i < $n_step } {incr i} {    
                    puts "# try move left:"
                    set new_x [expr $x - $step * $i]
                    eval "set_cell_location -coordinates {$new_x $y} $inst"
                    set bbox [get_attribute $inst boundary_bbox]
                    set llx [lindex $bbox 0 0]
                    set lly [lindex $bbox 0 1]
                    set urx [lindex $bbox 1 0]
                    set ury [lindex $bbox 1 1]
                    set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
                    set bbox_margin "\{[expr $llx - $x_margin] [expr $lly - $y_margin]\} \{[expr $urx + $x_margin] [expr $ury + $y_margin]\}"
                    set overlap_inst_itersect [get_cells -intersect $bbox_margin]
                    set overlap_inst_within [get_cells -within $bbox_margin]
                    if {[outofboundary $llx $lly]} {
                        break
                    }
                    if {[sizeof_collection $overlap_inst_itersect] > 0 || [sizeof_collection $overlap_inst_within] > 1} {
                        puts "[get_object_name $overlap_inst] overlap. $bbox_margin"
                    } else {
                        puts "# Found available location: $new_x $y | $bbox_margin"
                        set overlap 0
                        break
                    }
                }
                if {$overlap == 0} {
                    continue
                }
                for { set i 0 } { $i < $n_step } {incr i} {
                    puts "# try move right:"
                    set new_x [expr $x + $step * $i]
                    eval "set_cell_location -coordinates {$new_x $y} $inst"
                    set bbox [get_attribute $inst boundary_bbox]
                    set llx [lindex $bbox 0 0]
                    set lly [lindex $bbox 0 1]
                    set urx [lindex $bbox 1 0]
                    set ury [lindex $bbox 1 1]
                    set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
                    set bbox_margin "\{[expr $llx - $x_margin] [expr $lly - $y_margin]\} \{[expr $urx + $x_margin] [expr $ury + $y_margin]\}"
                    set overlap_inst_itersect [get_cells -intersect $bbox_margin]
                    set overlap_inst_within [get_cells -within $bbox_margin]
                    if {[outofboundary $urx $ury]} {
                        break
                    }

                    if {[sizeof_collection $overlap_inst_itersect] > 0 || [sizeof_collection $overlap_inst_within] > 1} {
                        #puts "[get_object_name $overlap_inst] overlap."
                    } else {
                        puts "# Found available location: $new_x $y"
                        set overlap 0
                        break
                    }
                }
                if {$overlap == 0} {
                    continue
                }
                for { set i 0 } { $i < $n_step } {incr i} {
                    puts "# try move up:"
                    set new_y [expr $y + $step * $i]
                    eval "set_cell_location -coordinates {$x $new_y} $inst"
                    set bbox [get_attribute $inst boundary_bbox]
                    set llx [lindex $bbox 0 0]
                    set lly [lindex $bbox 0 1]
                    set urx [lindex $bbox 1 0]
                    set ury [lindex $bbox 1 1]
                    set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
                    set bbox_margin "\{[expr $llx - $x_margin] [expr $lly - $y_margin]\} \{[expr $urx + $x_margin] [expr $ury + $y_margin]\}"
                    set overlap_inst_itersect [get_cells -intersect $bbox_margin]
                    set overlap_inst_within [get_cells -within $bbox_margin]
                    if {[outofboundary $urx $ury]} {
                        break
                    }

                    if {[sizeof_collection $overlap_inst_itersect] > 0 || [sizeof_collection $overlap_inst_within] > 1} {
                        #puts "[get_object_name $overlap_inst] overlap."
                    } else {
                        puts "# Found available location: $x $new_y"
                        set overlap 0
                        break
                    }
                }
                if {$overlap == 0} {
                    continue
                }
                for { set i 0 } { $i < $n_step } {incr i} {
                    puts "# try move down:"
                    set new_y [expr $y - $step * $i]
                    eval "set_cell_location -coordinates {$x $new_y} $inst"
                    set bbox [get_attribute $inst boundary_bbox]
                    set llx [lindex $bbox 0 0]
                    set lly [lindex $bbox 0 1]
                    set urx [lindex $bbox 1 0]
                    set ury [lindex $bbox 1 1]
                    set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
                    set bbox_margin "\{[expr $llx - $x_margin] [expr $lly - $y_margin]\} \{[expr $urx + $x_margin] [expr $ury + $y_margin]\}"
                    set overlap_inst_itersect [get_cells -intersect $bbox_margin]
                    set overlap_inst_within [get_cells -within $bbox_margin]
                    if {[outofboundary $llx $lly]} {
                        break
                    }

                    if {[sizeof_collection $overlap_inst_itersect] > 0 || [sizeof_collection $overlap_inst_within] > 1} {
                        #puts "[get_object_name $overlap_inst] overlap."
                    } else {
                        puts "# Found available location: $x $new_y"
                        set overlap 0
                        break
                    }
                }
                if {$overlap == 0} {
                    continue
                }


            }

        }
    }
}
}

proc placeMacro {inst x y} {
eval "set_cell_location -coordinates {$x $y} $inst"
set bbox [get_attribute $inst boundary_bbox]
set region_margin 0
set llx [expr [lindex $bbox 0 0] - $region_margin]
set lly [expr [lindex $bbox 0 1] - $region_margin]
set urx [expr [lindex $bbox 1 0] + $region_margin]
set ury [expr [lindex $bbox 1 1] + $region_margin]
set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
set overlap_inst [get_cells -intersect $bbox_margin]
if {[sizeof_collection $overlap_inst] > 1} {
    #puts "[get_object_name $overlap_inst] overlap."
    set n_step 100
    set step  20
    set overlap 1
    for { set i 0 } { $i < $n_step } {incr i} {    
        puts "# try move left:"
        set new_x [expr $x - $step * $i]
        eval "set_cell_location -coordinates {$new_x $y} $inst"
        set bbox [get_attribute $inst boundary_bbox]
        set llx [lindex $bbox 0 0]
        set lly [lindex $bbox 0 1]
        set urx [lindex $bbox 1 0]
        set ury [lindex $bbox 1 1]
        set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
        set overlap_inst [get_cells -intersect $bbox_margin]
        if {[outofboundary $llx $lly]} {
             break
        }
        if {[sizeof_collection $overlap_inst] > 1} {
            #puts "[get_object_name $overlap_inst] overlap."
        } else {
             puts "# Found available location: $new_x $y"
             set overlap 0
             break
        }
    }
    if {$overlap == 0} {
        return 1
    }
    for { set i 0 } { $i < $n_step } {incr i} {
        puts "# try move right:"
        set new_x [expr $x + $step * $i]
        eval "set_cell_location -coordinates {$new_x $y} $inst"
        set bbox [get_attribute $inst boundary_bbox]
        set llx [lindex $bbox 0 0]
        set lly [lindex $bbox 0 1]
        set urx [lindex $bbox 1 0]
        set ury [lindex $bbox 1 1]
        set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
        set overlap_inst [get_cells -intersect $bbox_margin]
        if {[outofboundary $urx $ury]} {
             break
        }

        if {[sizeof_collection $overlap_inst] > 1} {
            #puts "[get_object_name $overlap_inst] overlap."
        } else {
             puts "# Found available location: $new_x $y"
             set overlap 0
             break
        }
    }
    if {$overlap == 0} {
        return 1
    }
    for { set i 0 } { $i < $n_step } {incr i} {
        puts "# try move up:"
        set new_y [expr $y + $step * $i]
        eval "set_cell_location -coordinates {$x $new_y} $inst"
        set bbox [get_attribute $inst boundary_bbox]
        set llx [lindex $bbox 0 0]
        set lly [lindex $bbox 0 1]
        set urx [lindex $bbox 1 0]
        set ury [lindex $bbox 1 1]
        set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
        set overlap_inst [get_cells -intersect $bbox_margin]
        if {[outofboundary $urx $ury]} {
             break
        }

        if {[sizeof_collection $overlap_inst] > 1} {
            #puts "[get_object_name $overlap_inst] overlap."
        } else {
            puts "# Found available location: $x $new_y"
            set overlap 0
            break
        }
    }
    if {$overlap == 0} {
        return 1
    }
    for { set i 0 } { $i < $n_step } {incr i} {
        puts "# try move down:"
        set new_y [expr $y - $step * $i]
        eval "set_cell_location -coordinates {$x $new_y} $inst"
        set bbox [get_attribute $inst boundary_bbox]
        set llx [lindex $bbox 0 0]
        set lly [lindex $bbox 0 1]
        set urx [lindex $bbox 1 0]
        set ury [lindex $bbox 1 1]
        set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
        set overlap_inst [get_cells -intersect $bbox_margin]
        if {[outofboundary $llx $lly]} {
            break
        }

        if {[sizeof_collection $overlap_inst] > 1} {
             #puts "[get_object_name $overlap_inst] overlap."
        } else {
            puts "# Found available location: $x $new_y"
            set overlap 0
            break
        }
    }
    if {$overlap == 0} {
        return 1
    }
}
}
proc checkVdciPin {vdd_main} {
global P
set region_margin 0.0
set w_lvl 25.0
set l_iso_lvl 5.0
# sort left/right/bottom/top side ports
set pin_l_list  ""
set pin_r_list  ""
set pin_t_list  ""
set pin_b_list  ""
set pin_c_list  ""

set pin_l_pg  ""
set pin_r_pg  ""
set pin_t_pg  ""
set pin_b_pg  ""
set pin_c_pg  ""



set is_vdci [regexp "vdci" [get_attribute [current_design] name]]
if {$is_vdci == 1} {
    if {[file exists  data/upf/GetUpf.upf]} {
        load_upf data/upf/GetUpf.upf
    } else {
        puts "ERROR: upf is missing for vdci tiles."
    }
}
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
            set pin_l_pg [get_attribute [get_attribute $port UPF_related_supply_set] name]
            set vdd_h($pin_l_pg) 1
            set current_power [get_attribute [get_attribute $port UPF_related_supply_set] name]
            # port vote the power edage
            if [info exists n_pin_l_pg($current_power)] {
                incr n_pin_l_pg($current_power)
            } else {
                set n_pin_l_pg($current_power) 1
            }
            set pg_max 0
            foreach cpg [array names n_pin_l_pg] {
                if {$n_pin_l_pg($cpg) > $pg_max} {
                    set pg_max $n_pin_l_pg($cpg)
                    set pin_l_pg $cpg
                }
            }
            #set pin_l_pg [get_attribute [get_attribute $port UPF_related_supply_set] name]
            continue
        }
        set pin_llx_test [expr $pin_llx + 10]
        if {[outofboundary $pin_llx_test $pin_lly] > 0} {
            set pin_r_list  "$pin_r_list $pin_name"
            set pin_r_pg [get_attribute [get_attribute $port UPF_related_supply_set] name]
            set vdd_h($pin_r_pg) 1
            set current_power [get_attribute [get_attribute $port UPF_related_supply_set] name]
            # port vote the power edage
            if [info exists n_pin_r_pg($current_power)] {
                incr n_pin_r_pg($current_power)
            } else {
                set n_pin_r_pg($current_power) 1
            }
            set pg_max 0
            foreach cpg [array names n_pin_r_pg] {
                if {$n_pin_r_pg($cpg) > $pg_max} {
                    set pg_max $n_pin_r_pg($cpg)
                    set pin_r_pg $cpg
                }
            }

            #puts "$pin_llx_test $pin_lly $pin_name"
            continue
        }
        # pushdown clock pin
        set pin_c_list  "$pin_c_list $pin_name"
    } else {
        set pin_lly_test [expr $pin_lly - 10]
        if {[outofboundary $pin_llx $pin_lly_test] > 0} {
            set pin_b_list  "$pin_b_list $pin_name"
            set pin_b_pg [get_attribute [get_attribute $port UPF_related_supply_set] name]
            #puts "pin_b_pg $pin_b_pg [get_object_name $port]"
            set vdd_h($pin_b_pg) 1
            set current_power [get_attribute [get_attribute $port UPF_related_supply_set] name]
            # port vote the power edage
            if [info exists n_pin_b_pg($current_power)] {
                incr n_pin_b_pg($current_power)
            } else {
                set n_pin_b_pg($current_power) 1
            }
            set pg_max 0
            foreach cpg [array names n_pin_b_pg] {
                if {$n_pin_b_pg($cpg) > $pg_max} {
                    set pg_max $n_pin_b_pg($cpg)
                    set pin_b_pg $cpg
                }
            }
 
            continue
        }
        set pin_lly_test [expr $pin_lly + 10]
        if {[outofboundary $pin_llx $pin_lly_test] > 0} {
            set pin_t_list "$pin_t_list $pin_name"
            set pin_t_pg [get_attribute [get_attribute $port UPF_related_supply_set] name]
            set vdd_h($pin_t_pg) 1
            set current_power [get_attribute [get_attribute $port UPF_related_supply_set] name]
            # port vote the power edage
            if [info exists n_pin_t_pg($current_power)] {
                incr n_pin_t_pg($current_power)
            } else {
                set n_pin_t_pg($current_power) 1
            }
            set pg_max 0
            foreach cpg [array names n_pin_t_pg] {
                if {$n_pin_t_pg($cpg) > $pg_max} {
                    set pg_max $n_pin_t_pg($cpg)
                    set pin_t_pg $cpg
                }
            }

            #puts "$pin_llx $pin_lly_test $pin_name"
            continue
        }
        # pushdown clock pin
        set pin_c_list "$pin_c_list $pin_name"
    }
}
set n_l [llength $pin_l_list]
set n_r [llength $pin_r_list]
set n_t [llength $pin_t_list]
set n_b [llength $pin_b_list]


if {($n_l > 100 || $n_r > 100) && ($n_t > 100 || $n_b > 100) } {
    puts "ERROR: vdci pin not at two side : top: $n_t bottom: $n_b left: $n_l right: $n_r"
}
set bbox [get_attribute [current_design ] boundary_bbox]
set llx_tile [expr [lindex $bbox 0 0] + $region_margin]
set lly_tile [expr [lindex $bbox 0 1] + $region_margin]
set urx_tile [expr [lindex $bbox 1 0] - $region_margin]
set ury_tile [expr [lindex $bbox 1 1] - $region_margin]
set w [expr $urx_tile - $llx_tile]
set h [expr $ury_tile - $lly_tile]
# Here is the major power order
set vdd_main_list "VDDCR_SOC VDDCR_SOCIO VDDCR_GFX"
set vdd_main_found 0
#set vdd_main "VDDCR_SOC"

foreach vdd_main_tmp $vdd_main_list {
    puts "# Check power name $vdd_main_tmp"
    foreach vdd [array names vdd_h] {
        if {[regexp "${vdd_main_tmp}$" $vdd]} {
            set vdd_main_found 1
            #set vdd_main $vdd
            #set vdd_main [regsub -all "SS_" $vdd_main {}]
            puts "# Found main power $vdd"
        }
    }
    if {$vdd_main_found == 1} {
        break
    }
    
}
set vdd_other "NA"
foreach vdd [array names vdd_h] {
    puts "# check other power: $vdd_main $vdd"
    if {[regexp "\S" $vdd]} {
    } else {
        continue
    }
    if {[regexp "${vdd_main}$" $vdd]} {
    } else {
        set vdd_other $vdd
        set vdd_other [regsub -all "SS_" $vdd_other {}] 
        break
    }
}
if {$n_l > $n_t} {
    # The pins are left/right placed
    puts "$pin_l_pg $pin_r_pg | $pin_b_pg $pin_t_pg"
    if {[llength $pin_l_pg] == 0 && [llength $pin_r_pg] == 0} {
        puts "ERROR: No power info on port on left or right side."
    }
    set llx_lvl [expr $llx_tile + ($w - $w_lvl)/2]
    set lly_lvl $lly_tile
    set urx_lvl [expr $llx_lvl + $w_lvl]
    set ury_lvl $ury_tile 
    if {[regexp "${vdd_main}$" $pin_l_pg]} {
        # main power on left
        set llx_other [expr $urx_tile - ($w - $w_lvl)/2]
        set lly_other $lly_tile
        set urx_other $urx_tile
        set ury_other $ury_tile
        puts "WARNING: vdci power region info lvl: $llx_lvl $lly_lvl $urx_lvl $ury_lvl VDD_OTHER: $vdd_other $llx_other $lly_other $urx_other $ury_other $vdd_main end"
        set pg_region($vdd_other) "$llx_other $lly_other $urx_other $ury_other"
        set pg_region($vdd_main) "$llx_tile $lly_tile $llx_lvl $ury_lvl"
        set iso_loc($vdd_other) "[expr $urx_lvl + $l_iso_lvl]  [expr ($lly_lvl + $ury_lvl)/2]"
        set iso_loc($vdd_main) "[expr $llx_lvl - $l_iso_lvl]  [expr ($lly_lvl + $ury_lvl)/2]"
        set width_other [expr $urx_other - $llx_other]
        if {$width_other < $w_lvl} {
            puts "ERROR: other power region $width_other um too small which is less than lvl $w_lvl um"
        }
        puts "WARNING: vdci iso location: $vdd_main $iso_loc($vdd_main) $vdd_other $iso_loc($vdd_other)"

    } else {
        # main power on right
        set llx_other $llx_tile
        set lly_other $lly_tile
        set urx_other [expr $llx_tile + ($w - $w_lvl)/2]
        set ury_other $ury_tile
        set width_other [expr $urx_other - $llx_other]
        if {$width_other < $w_lvl} {
            puts "ERROR: other power region $width_other um too small which is less than lvl $w_lvl um"
        }
        puts "WARNING: vdci power region info lvl: $llx_lvl $lly_lvl $urx_lvl $ury_lvl VDD_OTHER: $vdd_other $llx_other $lly_other $urx_other $ury_other $vdd_main end"
        set pg_region($vdd_other) "$llx_other $lly_other $urx_other $ury_other"
        set pg_region($vdd_main) "$urx_lvl $lly_lvl $urx_tile $ury_tile"
        set iso_loc($vdd_other) "[expr $llx_lvl - $l_iso_lvl]  [expr ($lly_lvl + $ury_lvl)/2]"
        set iso_loc($vdd_main) "[expr $urx_lvl + $l_iso_lvl]  [expr ($lly_lvl + $ury_lvl)/2]"
        puts "WARNING: vdci iso location: $vdd_main $iso_loc($vdd_main) $vdd_other $iso_loc($vdd_other)"
    }
} else {
    # The pins are top/bottom placed
    puts "$pin_l_pg $pin_r_pg | $pin_b_pg $pin_t_pg"
    if {[llength $pin_b_pg] == 0 && [llength $pin_t_pg] == 0} {
        puts "ERROR: No power info on port on bottom or top side."
    }
    set llx_lvl $llx_tile 
    set lly_lvl [expr $lly_tile + ($h - $w_lvl)/2]
    set urx_lvl $urx_tile 
    set ury_lvl [expr $lly_lvl + $w_lvl] 
    if {[regexp "${vdd_main}$" $pin_b_pg]} {
        # main power on bottom
        set llx_other $llx_tile 
        set lly_other [expr $ury_tile - ($h - $w_lvl)/2]
        set urx_other $urx_tile
        set ury_other $ury_tile
        puts "WARNING: vdci power region info lvl: $llx_lvl $lly_lvl $urx_lvl $ury_lvl VDD_OTHER: $vdd_other $llx_other $lly_other $urx_other $ury_other $vdd_main end"
        set width_other [expr $ury_other - $lly_other]
        if {$width_other < $w_lvl} {
            puts "ERROR: other power region $width_other um too small which is less than lvl $w_lvl um"
        }
        set pg_region($vdd_other) "$llx_other $lly_other $urx_other $ury_other"
        set pg_region($vdd_main) "$llx_tile $lly_tile $urx_tile $lly_lvl"
        set iso_loc($vdd_other) "[expr ($llx_lvl + $urx_lvl)/2] [expr $ury_lvl + $l_iso_lvl]"
        set iso_loc($vdd_main) "[expr ($llx_lvl + $urx_lvl)/2 ] [expr $lly_lvl - $l_iso_lvl]"
        puts "WARNING: vdci iso location: $vdd_main $iso_loc($vdd_main) $vdd_other $iso_loc($vdd_other)"

    } else {
        # main power on top
        set llx_other $llx_tile
        set lly_other $lly_tile
        set urx_other $urx_tile 
        set ury_other [expr $lly_tile + ($h - $w_lvl)/2]
        puts "WARNING: vdci power region info lvl: $llx_lvl $lly_lvl $urx_lvl $ury_lvl VDD_OTHER: $vdd_other $llx_other $lly_other $urx_other $ury_other $vdd_main end"
        set width_other [expr $ury_other - $lly_other]
        if {$width_other < $w_lvl} {
            puts "ERROR: other power region $width_other um too small which is less than lvl $w_lvl um"
        }
        set pg_region($vdd_other) "$llx_other $lly_other $urx_other $ury_other"
        set pg_region($vdd_main) "$llx_tile $lly_lvl $urx_tile $ury_tile"
        set iso_loc($vdd_other) "[expr ($llx_lvl + $urx_lvl)/2] [expr $lly_lvl - $l_iso_lvl]"
        set iso_loc($vdd_main) "[expr ($llx_lvl + $urx_lvl)/2 ] [expr $ury_lvl + $l_iso_lvl]"
        puts "WARNING: vdci iso location: $vdd_main $iso_loc($vdd_main) $vdd_other $iso_loc($vdd_other)"

    }

}
# generate ISO location
set place_eco_list ""
foreach_in_collection inst [get_flat_cells -filter "ref_name =~ *PSLVL*"] {
    set n_pin_conn  0
    set power ""
    foreach_in_collection pin [get_pins [get_object_name $inst]/* -filter "port_type == signal"] {
        if {[get_attribute [get_pins $pin] direction] == "in"} {
            if {[sizeof_collection [all_fanin -to $pin -flat]] > $n_pin_conn} {
                set n_pin_conn [sizeof_collection [all_fanin -to $pin -flat]]
                set power [get_attribute [get_attribute $pin UPF_related_supply_set] name]
                set power [regsub -all "SS_" $power {}]
            }
        } else {
            if {[sizeof_collection [all_fanout -from $pin -flat]] > $n_pin_conn} {
                set n_pin_conn [sizeof_collection [all_fanout -from $pin -flat]]
                set power [get_attribute [get_attribute $pin UPF_related_supply_set] name]
                set power [regsub -all "SS_" $power {}]
            }
        }
    }
    if {[get_attribute $inst physical_status] == "unplaced"} {
        puts "ARNING: place unplaced [get_object_name $inst] $power $iso_loc($power)"
        eval "set_cell_location -coordinates { $iso_loc($power)} ${inst}"
        set place_eco_list "$place_eco_list [get_object_name $inst]"
    }
}
if {[llength $place_eco_list] > 0} {
    eval "place_eco_cells -legalize_only -cells {$place_eco_list}"
    eval "set_attribute [get_cells ${place_eco_list}] physical_status fixed" 
}
reset_upf
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

proc fixMemOrientation {} {
# R0/MX, the pins face to right
# MY/R180, the pins face to left
set bbox [get_attribute [current_design] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]
foreach_in_collection mem [get_flat_cells -all -filter "is_memory_cell == True"] {
    set bbox [get_attribute $mem boundary_bbox]
    set llx_mem [lindex $bbox 0 0]
    set lly_mem [lindex $bbox 0 1]
    set urx_mem [lindex $bbox 1 0]
    set ury_mem [lindex $bbox 1 1]
    if {[expr $urx_mem - $llx_mem] > [expr ($llx_tile - $llx_tile)/2]} {
        puts "# check large mem  width > wdith_tile / 2 [get_object_name $mem]"
        puts "# [expr $urx_tile - $urx_mem] > [expr $llx_mem - $llx_tile] "
        if {[expr $urx_tile - $urx_mem] > [expr $llx_mem - $llx_tile]} {
            puts "# fixMemOrientation [get_object_name $mem] R0"
            eval "set_cell_location $mem -ignore_fixed -orientation R0 -coordinates {$llx_mem $lly_mem}"
        } else {
            puts "# fixMemOrientation [get_object_name $mem] MY"
            eval "set_cell_location $mem -ignore_fixed -orientation MY -coordinates {$llx_mem $lly_mem}"
            continue
        }
    }
    if {$urx_mem < [expr ($llx_tile + $urx_tile)/2]} {
        puts "# fixMemOrientation [get_object_name $mem] R0"
        eval "set_cell_location $mem -ignore_fixed -orientation R0 -coordinates {$llx_mem $lly_mem}"
        continue
    }
    if {$llx_mem > [expr ($llx_tile + $urx_tile)/2]} {
        puts "# fixMemOrientation [get_object_name $mem] MY"
        eval "set_cell_location $mem -ignore_fixed -orientation MY -coordinates {$llx_mem $lly_mem}"
        continue
    }
    
}
}

proc unplacePort {ports} {
foreach_in_collection port [get_ports $ports] {
    if {[sizeof_collection [get_shapes -quiet -of_objects [get_terminals -quiet -of_objects [get_ports $port]]]] != 0} {
        remove_shapes [get_shapes -of_objects [get_terminals -of_objects [get_ports $port]]]
        set_attribute [get_ports $port] physical_status unplaced
    }
}
}

proc fixOffTrackPins {ports} {
foreach_in_collection port [get_ports $ports] {
    set bbox [get_attribute $port bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {M6 M7 M8 M9 M10 M11} -location {$llx $lly}"
    unplacePort $port

}
place_pins -ports [get_ports $ports]
}

proc checkNfixOffTrackPins {} {
check_pin_placement -self -wire_track true > check_pin_placement.rpt
set f [open check_pin_placement.rpt r ]
set ports  ""
while {[gets $f line] >= 0} {
    if {[regexp {Pin\s+(\S+)\s+is\s+not\s+centered\s+on\s+wire\s+track\s+of\s+layer} $line match port]} {
        set ports "$ports $port"
    }
}
if {[llength $ports] > 0} {
    puts "# ERROR: offtrack is found for $ports , will fix them on-track"
    fixOffTrackPins $ports
}
close $f
}

proc placeVdciPins {} {
set top [get_attribute [current_design] name]
set o [open data/placeVdciPins.list w]
set c [open data/placeVdciPins.tcl w]

if {[file exists  data/upf/GetUpf.upf]} {
    load_upf data/upf/GetUpf.upf
} else {
    puts "ERROR: upf is missing for vdci tiles."
}
puts "# Find pair by iterating word from end"
foreach_in_collection port [get_ports *] {
    set pin_name [get_object_name $port]
    #puts "$pin_name $pin_pg"
    set pattern ""
    set word_list [regsub -all {_} [get_object_name $port] { }]
    set found 0
    set pg [get_attribute [get_attribute [get_port $port] UPF_related_supply_set] name]
    set pg [regsub -all "SS_" $pg {}]
    set pin_pg_h($port) $pg
    for { set i [expr [llength $word_list] - 1] } { $i >= 0} {incr i -1} {
        set pattern "[lindex $word_list $i]*$pattern"
        #puts "$word_list $pattern $i"
        if {[sizeof_collection [get_ports *$pattern*]] == 2} {
            set pair [get_object_name [get_ports *$pattern*]]
            set pair [regsub -all "{" $pair {}]
            set pair [regsub -all "}" $pair {}]
            set port0 [lindex $pair 0]
            set port1 [lindex $pair 1]
            set pg0 [get_attribute [get_attribute [get_port $port0] UPF_related_supply_set] name]
            set pg1 [get_attribute [get_attribute [get_port $port1] UPF_related_supply_set] name]
            set pg0 [regsub -all "SS_" $pg0 {}]
            set pg1 [regsub -all "SS_" $pg1 {}]
            set pin_pg_h($port0) $pg0
            set pin_pg_h($port1) $pg1

            if {$pg0 != $pg1} {
                if {[info exists pg_h($pg0)] && $pg0 != "" } {
                    set pg_h($pg0) "$pg_h($pg0) $port0"
                } else {
                    set pg_h($pg0) "$port0"
                }
                if {[info exists pg_h($pg1)] && $pg1 != ""} {
                    set pg_h($pg1) "$pg_h($pg1) $port1"
                } else {
                    set pg_h($pg1) "$port1"
                }
                #puts $pair
                set pin_pair_h($port0) $port1
                set pin_pair_h($port1) $port0
                set is_pair_h($port0) 1
                set is_pair_h($port1) 1
                set pin_pg_h([get_object_name $port]) $pin_pg
                set found 1
            }
        } 
    }
    if {$found == 0} {
        set pin_pg [get_attribute [get_attribute $port UPF_related_supply_set] name]
        set non_pair_h([get_object_name $port]) 1
    }
}    
set bbox [get_attribute [current_design] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]
set w [expr $urx_tile - $llx_tile]
set h [expr $ury_tile - $lly_tile]
puts "# Find pair by replacing keyword with *"
set pair_key "Slave Master in out"
set found 0
foreach port [array names non_pair_h] {
    set pattern $port
    foreach key $pair_key {
        set pattern [regsub -all "$key" $pattern {*}]
        if {[sizeof_collection [get_ports $pattern]] == 2} {
            set pair [get_object_name [get_ports $pattern]]
            set pair [regsub -all "{" $pair {}]
            set pair [regsub -all "}" $pair {}]
            set port0 [lindex $pair 0]
            set port1 [lindex $pair 1]
            set pg0 [get_attribute [get_attribute [get_port $port0] UPF_related_supply_set] name]
            set pg1 [get_attribute [get_attribute [get_port $port1] UPF_related_supply_set] name]
            set pg0 [regsub -all "SS_" $pg0 {}]
            set pg1 [regsub -all "SS_" $pg1 {}]
            if {$pg0 != $pg1} {
                if {[info exists pg_h($pg0)]} {
                    set pg_h($pg0) "$pg_h($pg0) $port0"
                } else {
                    set pg_h($pg0) "$port0"
                }
                if {[info exists pg_h($pg1)]} {
                    set pg_h($pg1) "$pg_h($pg1) $port1"
                } else {
                    set pg_h($pg1) "$port1"
                }
                set pin_pair_h($port0) $port1
                set pin_pair_h($port1) $port0
                set is_pair_h($port0) 1
                set is_pair_h($port1) 1
                set non_pair_h($port) 0
                set found 1
            } else {
                puts "# Error: same power info on pair $port0:$pg0 $port1:$pg1"
            }
        }
    }
    if {$found == 0} {
        set non_pair_h([get_object_name $port]) 1
    }
}
set vdd_main_list "VDDCR_SOC VDDCR_SOCIO"
foreach pg [array names pg_h] {
    set pg_h($pg) [lsort -u $pg_h($pg)]
    foreach port $pg_h($pg) {
       puts $o "$pg $port $pin_pair_h($port)"
    }
}

puts "# chose width as pin side"
set pin_spec [getMajorPinWidth]
if {[regexp {(.*):(\S+),(.*):(\S+)} $pin_spec match h_spec h_pitch v_spec v_pitch]} {
    puts "$h_spec $h_pitch $v_spec $v_pitch"
}
set n_h_spec [llength $h_spec]
set n_v_spec [llength $v_spec]
set n_ports [sizeof_collection [get_ports *]]
if {$w > $h} {
    puts "# choose width as pin side"
    set offset [expr ($w - $n_ports / 2 * $v_pitch * 2 / $n_v_spec) / 2 ]
    if {$offset < 0} {
        puts "# Error: vdci width $w is less then needed : [expr $n_ports / 2 * $v_pitch * 2 / $n_v_spec]"
    }
    puts "# offset $offset,$v_spec, total width need [expr $n_ports / 2 * $v_pitch * 2 / $n_v_spec] $n_v_spec"
    set n_step 0
    foreach pg $vdd_main_list {
        if {[info exists pg_h($pg)]} {
            puts "# Start place pins for [llength $pg_h($pg)] $pg"
            puts "# Select edge based on 100 pins initial side."
            set top_side 0
            set bottom_side 0
            foreach port $pg_h($pg) {
                set bbox_pin [get_attribute [get_port $port] bbox] 
                set llx_pin [lindex $bbox_pin 0] 
                set lly_pin [lindex $bbox_pin 1]
                set urx_pin [lindex $bbox_pin 2]
                set ury_pin [lindex $bbox_pin 3]
                if {$lly_pin  > 0 & $llx_pin > [expr $llx_tile + 10] && $llx_pin < [expr $urx_tile - 10] } {
                    incr top_side 
                    if {$top_side > 100} {
                        break
                    }
                }
                if {$lly_pin  < 0 & $llx_pin > [expr $llx_tile + 10] && $llx_pin < [expr $urx_tile - 10] } {
                    incr bottom_side
                    if {$bottom_side > 100} {
                        break
                    }
                }

            }
            puts "# top_side $top_side bottom_side $bottom_side $pg" 
            set step [expr $v_pitch * 2]
            set n_layer 0
            foreach port $pg_h($pg) {
                set x [expr $llx_tile + $offset + $step * $n_step]
                if {$top_side > $bottom_side} {
                    set y $ury_tile
                } else {
                    set y $lly_tile
                }
                puts "# $x $llx_tile $urx_tile $port $n_layer"
                if {$n_layer == [expr [llength $v_spec] - 1]} {
                    incr n_step
                    set n_layer 0
                    set layer [lindex $v_spec $n_layer]
                } else {
                    incr n_layer
                    set layer [lindex $v_spec $n_layer]
                }

                if {$x < $llx_tile || $x > $urx_tile} {
                    puts "# $port $x out of boundary $llx_tile $urx_tile"
                    continue
                }
                puts $c "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
                eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
                if {$top_side > $bottom_side} {
                    set y $lly_tile
                } else {
                    set y $ury_tile
                }
                puts $c "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
                eval "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
                
                # write opposite pin loc
               unplacePort $port
               unplacePort $pin_pair_h($port)
            }
            set ports [get_ports * -filter "physical_status == unplaced"]
            place_pins -ports [get_ports $ports]
            break
        }
    }

} else {
    puts "# choose height as pin side"
    set offset [expr ($h - $n_ports / 2 * $h_pitch * 2 / $n_h_spec) / 2 ]
    if {$offset < 0} {
        puts "# Error: vdci width $w is less then needed : [expr $n_ports / 2 * $h_pitch * 2 / $n_h_spec]"
    }
    puts "# offset $offset,$h_spec, total width need [expr $n_ports / 2 * $h_pitch * 2 / $n_h_spec] $n_h_spec"
    set n_step 0
    foreach pg $vdd_main_list {
        if {[info exists pg_h($pg)]} {
            puts "# Start place pins for [llength $pg_h($pg)] $pg"
            puts "# Select edge based on 100 pins initial side."
            set left_side 0
            set right_side 0
            foreach port $pg_h($pg) {
                set bbox_pin [get_attribute [get_port $port] bbox]
                set llx_pin [lindex $bbox_pin 0]
                set lly_pin [lindex $bbox_pin 1]
                set urx_pin [lindex $bbox_pin 2]
                set ury_pin [lindex $bbox_pin 3]
                if {$llx_pin  > 0 & $lly_pin > [expr $lly_tile + 10] && $lly_pin < [expr $ury_tile - 10] } {
                    incr right_side
                    if {$right_side > 100} {
                        break
                    }
                }
                if {$llx_pin  < 0 & $lly_pin > [expr $lly_tile + 10] && $lly_pin < [expr $ury_tile - 10] } {
                    incr left_side
                    if {$left_side > 100} {
                        break
                    }
                }

            }
            puts "# right_side $right_side left_side $left_side $pg"
            set step [expr $h_pitch * 2]
            set n_layer 0
            foreach port $pg_h($pg) {
                if {$right_side > $left_side} {
                    set x $urx_tile
                } else {
                    set x $llx_tile
                }
                set y [expr $lly_tile + $offset + $step * $n_step]
                puts "# $y $lly_tile $ury_tile $port $n_layer"
                if {$n_layer == [expr [llength $h_spec] - 1]} {
                    incr n_step
                    set n_layer 0
                    set layer [lindex $h_spec $n_layer]
                } else {
                    incr n_layer
                    set layer [lindex $h_spec $n_layer]
                }

                if {$y < $lly_tile || $y > $ury_tile} {
                    continue
                }
                puts $c "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
                eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
                if {$right_side > $left_side} {
                    set x $llx_tile
                } else {
                    set x $urx_tile
                }
                puts $c "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
                eval "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"

                # write opposite pin loc
                unplacePort $port
                unplacePort $pin_pair_h($port)
            }
            set ports [get_ports * -filter "physical_status == unplaced"]
            place_pins -ports [get_ports $ports]
            break
        }
    }

}
close $c
source data/placeVdciPins.tcl
close $o
writePortDef data/$top.pin.def.gz
}

proc getMajorPinWidth {} {
foreach_in_collection track [get_tracks] {
    set layer [get_attribute $track layer_name]
    set pitch_h($layer) [get_attribute $track space]
    set direction_h($layer) [get_attribute $track direction]
    puts "$layer $pitch_h($layer) $direction_h($layer)"
}

puts "# calculate the pitch count"
foreach layer [array names direction_h] {
    puts "$layer $direction_h($layer)"
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
puts "# Choose the most common pitch for layers"
foreach pitch [array names h_pin_pitch_h] {
    puts "$pitch $h_pin_pitch_h($pitch) $n_h_pitch"
    if {$h_pin_pitch_h($pitch) > $n_h_pitch} {
        set n_h_pitch $h_pin_pitch_h($pitch)
        set h_pin_pitch $pitch
    }
}

foreach pitch [array names v_pin_pitch_h] {
    if {$v_pin_pitch_h($pitch) > $n_v_pitch} {
        set n_v_pitch $v_pin_pitch_h($pitch)
        set v_pin_pitch $pitch
    }
}
puts "# Choose the major pitch"
foreach layer [array names pitch_h] {
    if {$pitch_h($layer) == $h_pin_pitch && $direction_h($layer) == "horizontal"} {
        set h_pitch_layer "$h_pitch_layer $layer"
    }
    if {$pitch_h($layer) == $h_pin_pitch && $direction_h($layer) != "horizontal"} {
        set v_pitch_layer "$v_pitch_layer $layer"
    }
}
puts "$h_pitch_layer:$h_pin_pitch $v_pitch_layer:$v_pin_pitch"
return "$h_pitch_layer:$h_pin_pitch,$v_pitch_layer:$v_pin_pitch"
}

proc checkHalo {guidelines} {
# checkHalo /tool/aticad/1.0/src/zoo/mi400/aid/floorplan/swatchrange.macro_halo_guidelines.txt
# macro left bottom right top
set f [open $guidelines r]
while {[gets $f line] >= 0} {
    set line [regsub -all "um" $line {}]
    set macro [lindex $line 0]
    set space_l [lindex $line 1]
    set space_b [lindex $line 2]
    set space_r [lindex $line 3]
    set space_t [lindex $line 4]
    set space_h($macro) "$space_l $space_b $space_r $space_t"
}
close $f
foreach macro [array names space_h] {
    set macro_inst [get_flat_cells -quiet -all -filter "ref_name == $macro"]
    if {[sizeof_collection $macro_inst] > 0} {
        foreach_in_collection inst $macro_inst {
            set bbox [get_attribute $inst boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            set bbox "\{$llx $lly\} \{$urx $ury\}"
            #puts "# [get_object_name $inst] $bbox"
            set llx [expr $llx - [lindex $space_h($macro) 0]]
            set lly [expr $lly - [lindex $space_h($macro) 1]]
            set urx [expr $urx + [lindex $space_h($macro) 2]]
            set ury [expr $ury + [lindex $space_h($macro) 3]]
            set bbox_margin "\{$llx $lly\} \{$urx $ury\}"
            #puts "# [get_object_name $inst] $macro $bbox_margin"
            # check macro and macro spacing
            set overlap_inst [get_cells -intersect $bbox_margin]
            if {[sizeof_collection $overlap_inst] > 0} {
                puts "# ERROR: halo check fail for rule : left/bottom/right/top, $space_h($macro) , in region: $bbox_margin [get_object_name $inst] too close to [get_object_name $overlap_inst]"
            }
            # check macro and tile boundary spacing
            if {[outofboundary $llx $lly] > 0 || [outofboundary $urx $ury] > 0 || [outofboundary $llx $ury] > 0 || [outofboundary $urx $lly] > 0} {
                puts "# ERROR halo check fail for rule : left/bottom/right/top, $space_h($macro) , in region: $bbox_margin [get_object_name $inst] too close to boundary "
            }
        }
    }
}
}

proc isOverlap {boundary_box0 boundary_box1} {
set geo0 [create_geo_mask -objects $boundary_box0]
set geo1 [create_geo_mask -objects $boundary_box1]
set area_and [compute_area [compute_polygons -objects1 $geo0 -objects2 $geo1 -operation AND]]
puts "# if return value > 0, means overlap."
return "$area_and "
}

proc checkClkPortDistance {} {
set distance_th 600
set x_sum 0
set y_sum 0
foreach_in_collection reg [get_flat_cells * -filter "is_sequential == true"] {
    set bbox [get_attribute $reg bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set x_sum [expr $x_sum + $llx]
    set y_sum [expr $y_sum + $lly]
    #puts "[get_object_name $reg] $llx $lly"
}
set n [sizeof_collection [get_flat_cells * -filter "is_sequential == true"]]
set x_avg [expr $x_sum / $n]
set y_avg [expr $y_sum / $n]
foreach_in_collection port [get_ports [get_attribute -quiet [get_clocks] sources]] {
    #puts "[get_object_name $port]"
    set bbox [get_attribute $port bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set distance [expr abs($llx - $x_avg) + abs($lly - $y_avg)]
    #puts " [get_object_name $port] $llx $lly distance $distance too far from center of gravity of regs $x_avg $y_avg"
    if {$distance > $distance_th} {
        puts "# ERROR: clock port [get_object_name $port] $llx $lly distance $distance too far from center of gravity of regs $x_avg $y_avg"
    }

}
}

proc checkPortEdge {} {
set pin_macro(t) 0
set pin_macro(b) 0
set pin_macro(l) 0
set pin_macro(r) 0
set bbox [get_attribute [current_design] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]

foreach_in_collection macro [get_flat_cells -all -filter "is_hard_macro"] {
    set llx_macro [lindex [get_attribute $macro boundary_bbox] 0 0]
    set lly_macro [lindex [get_attribute $macro boundary_bbox] 0 1]
    set urx_macro [lindex [get_attribute $macro boundary_bbox] 1 0]
    set ury_macro [lindex [get_attribute $macro boundary_bbox] 1 1]
    foreach_in_collection pin [get_pins -of_object $macro] {
        set llx_pin [lindex [get_attribute $pin bbox] 0 0]
        set lly_pin [lindex [get_attribute $pin bbox] 0 1]
        if {$llx_pin > [expr $llx_macro + 1.0] && $llx_pin < [expr $urx_macro - 1.0] } {
            if {$lly_pin > [expr $ury_macro - 1.0] } {
                set pin_macro(t) [expr $pin_macro(t) + 1]
            } else {
                set pin_macro(b) [expr $pin_macro(b) + 1]
            }
        } else {
            if {$llx_pin < [expr $llx_macro + 1.0] } {
                set pin_macro(l) [expr $pin_macro(l) + 1]
            } else {
                set pin_macro(r) [expr $pin_macro(r) + 1]
            } 
        }
    }
}
set pin_max 0
set pin_edge ""
foreach edge [array names pin_macro] {
    puts "$edge $pin_macro($edge)"
    if {$pin_macro($edge) > $pin_max} {
        puts "# Macro pin face $edge $pin_macro($edge)"
        set pin_edge $edge
    }
}
if {[llength $pin_edge] == 0} {
    puts "# No macro pins check."
    return 0
}
puts "# Macro pins face $pin_edge"
foreach_in_collection port [get_ports *] {
    set llx_port [lindex [get_attribute $port bbox] 0 0]
    set lly_port [lindex [get_attribute $port bbox] 0 1]
    if {$pin_edge == "t"} {
        if {$llx_port > [expr $llx_tile + 1.0] && $llx_port < [expr $urx_tile - 1.0]} {
            if {$lly_port < [expr $lly_tile + 1.0] } {
                puts "ERROR: check port at wrong edge : [get_object_name $port] at bottom but macro pin face top. Tile with large macro(gpio/pcie/clk) close to edge need to check this."
            }
        }
    }
    if {$pin_edge == "b"} {
        #puts "# check port [get_object_name $port] $llx_port $lly_port"
        if {$llx_port > [expr $llx_tile + 1.0] && $llx_port < [expr $urx_tile - 1.0]} {
            if {$lly_port > [expr $ury_tile - 1.0] } {
                puts "ERROR: check port at wrong edge : [get_object_name $port] at top but macro pin face bottom. Tile with large macro(gpio/pcie/clk) close to edge need to check this."
            }
        }
    }
    if {$pin_edge == "l"} {
        if {$lly_port > [expr $lly_tile + 1.0] && $lly_port < [expr $ury_tile - 1.0]} {
            if {$llx_port > [expr $urx_tile - 1.0] } {
                puts "ERROR: check port at wrong edge : [get_object_name $port] at right but macro pin face left. Tile with large macro(gpio/pcie/clk) close to edge need to check this."
            }
        }
    }
    if {$pin_edge == "r"} {
        if {$lly_port > [expr $lly_tile + 1.0] && $lly_port < [expr $ury_tile - 1.0]} {
            if {$llx_port < [expr $llx_tile + 1.0] } {
                puts "ERROR: check port at wrong edge : [get_object_name $port] at left but macro pin face right. Tile with large macro(gpio/pcie/clk) close to edge need to check this."
            }
        }
    }
}
}

proc fixGroupMacroBoundarySpacing {group} { 
set x_margin 13.0
set y_margin 6.0
foreach_in_collectio macro [get_cells $group]  {
    set bbox [get_attribute $macro boundary_bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set urx [lindex $bbox 1 0]
    set ury [lindex $bbox 1 1]
    set llx_margin [expr $llx - $x_margin]
    set x_delta 0
    # assume all the macros are inside core
    if {[outofboundary $llx_margin $lly]} {
        puts "Error: [get_object_name $macro] too close to boundary "
        for { set i 0 } { $i < $x_margin } {incr i} {
            set llx [expr $llx + 1.0]
            set x_delta [expr $i*1.0] 
            set llx_margin [expr $llx - $x_margin]
            if [outofboundary $llx_margin $lly] {
            } else {
                break
            }
        }
        foreach_in_collectio mo [get_cells $group]  {
            set bbox [get_attribute $mo boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            set llx [expr $llx + $x_delta]
            eval "set_cell_location -coordinates {$llx $lly} $mo  -ignore_fixed"
        }
    }
    set y_delta 0
    set lly_margin [expr $lly - $y_margin]
    if {[outofboundary $llx $lly_margin]} {
        puts "Error: [get_object_name $macro] too close to boundary "
        for { set i 0 } { $i < $y_margin } {incr i} {
            set lly [expr $lly + 1.0]
            set lly_margin [expr $lly - $y_margin]
            set y_delta [expr $i*1.0]
            if [outofboundary $llx $lly_margin] {
            } else {
                break
            }
        }
        foreach_in_collectio mo [get_cells $group]  {
            set bbox [get_attribute $mo boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            set lly [expr $lly + $y_delta]

            eval "set_cell_location -coordinates {$llx $lly} $mo  -ignore_fixed"
        }
    }

    set urx_margin [expr $urx + $x_margin]
    if {[outofboundary $urx_margin $ury]} {
        puts "Error: [get_object_name $macro] too close to boundary "
        for { set i 0 } { $i < $x_margin } {incr i} {
            set llx [expr $llx - 1.0]
            set urx [expr $urx - 1.0]
            set urx_margin [expr $urx + $x_margin]
            set x_delta [expr $i*(-1.0)]
            puts "# new urx_margin $urx_margin $x_delta"
            if [outofboundary $urx_margin $ury] {
            } else {
                break
            }
        }
        foreach_in_collectio mo [get_cells $group]  {
            set bbox [get_attribute $mo boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            set llx [expr $llx + $x_delta]
            eval "set_cell_location -coordinates {$llx $lly} $mo  -ignore_fixed"
        }
    }
    
    set ury_margin [expr $ury + $y_margin]
    if {[outofboundary $urx $ury_margin]} {
        puts "Error: [get_object_name $macro] too close to boundary "
        for { set i 0 } { $i < $y_margin } {incr i} {
            set ury [expr $ury - 1.0]
            set lly [expr $lly - 1.0]
            set y_delta [expr $i*(-1.0)]
            set ury_margin [expr $ury + $y_margin]
            if [outofboundary $urx $ury_margin] {
            } else {
                break
            }
        }
        foreach_in_collectio mo [get_cells $group]  {
            set bbox [get_attribute $mo boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            set lly [expr $lly + $y_delta]
            eval "set_cell_location -coordinates {$llx $lly} $mo  -ignore_fixed"
        }
    }

}
}

proc fixAllMacroBoundarySpacing {} { 
set macros [get_flat_cells -all -filter "is_hard_macro"]
set x_margin 13.0
set y_margin 6.0
foreach_in_collectio macro [get_cells $macros]  {
    set bbox [get_attribute $macro boundary_bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set urx [lindex $bbox 1 0]
    set ury [lindex $bbox 1 1]
    set llx_margin [expr $llx - $x_margin]
    # assume all the macros are inside core
    if {[outofboundary $llx_margin $lly]} {
        puts "Error: [get_object_name $macro] too close to boundary "
        foreach_in_collectio mo [get_cells $macro]  {
            set bbox [get_attribute $mo boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            for { set i 0 } { $i < $x_margin } {incr i} {
                set llx [expr $llx + 1.0]
                set llx_margin [expr $llx - $x_margin]
                if [outofboundary $llx_margin $lly] {
                } else {
                    break
                }
            }
            eval "set_cell_location -coordinates {$llx $lly} $mo  -ignore_fixed"
        }
    }

    set lly_margin [expr $lly - $y_margin]
    if {[outofboundary $llx $lly_margin]} {
        puts "Error: [get_object_name $macro] too close to boundary "
        foreach_in_collectio mo [get_cells $macro]  {
            set bbox [get_attribute $mo boundary_bbox] 
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            for { set i 0 } { $i < $y_margin } {incr i} {
                set lly [expr $lly + 1.0]
                set lly_margin [expr $lly - $y_margin]
                if [outofboundary $llx $lly_margin] {
                } else {
                    break
                }
            }

            eval "set_cell_location -coordinates {$llx $lly} $mo  -ignore_fixed"
        }
    }

    set urx_margin [expr $urx + $x_margin]
    if {[outofboundary $urx_margin $ury]} {
        puts "Error: [get_object_name $macro] too close to boundary "
        foreach_in_collectio mo [get_cells $macro]  {
            set bbox [get_attribute $mo boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            for { set i 0 } { $i < $x_margin } {incr i} {
                set llx [expr $llx - 1.0]
                set urx [expr $urx - 1.0]
                set urx_margin [expr $urx + $x_margin]
                if [outofboundary $urx_margin $ury] {
                } else {
                    break
                }
            }
            eval "set_cell_location -coordinates {$llx $lly} $mo  -ignore_fixed"
        }
    }
    
    set ury_margin [expr $ury + $y_margin]
    if {[outofboundary $urx $ury_margin]} {
        puts "Error: [get_object_name $macro] too close to boundary "
        foreach_in_collectio mo [get_cells $macro]  {
            set bbox [get_attribute $mo boundary_bbox]
            set llx [lindex $bbox 0 0]
            set lly [lindex $bbox 0 1]
            set urx [lindex $bbox 1 0]
            set ury [lindex $bbox 1 1]
            for { set i 0 } { $i < $y_margin } {incr i} {
                set ury [expr $ury - 1.0]
                set lly [expr $lly - 1.0]
                puts "# new ury $ury"
                set ury_margin [expr $ury + $y_margin]
                if [outofboundary $urx $ury_margin] {
                } else {
                    break
                }
            }

            eval "set_cell_location -coordinates {$llx $lly} $mo  -ignore_fixed"
        }
    }

}
}

proc placeISO {} {
foreach_in_collection inst [get_flat_cells -filter "ref_name =~ *PSLVL*"] {
    set n_pin_conn  0
    set power ""
    foreach_in_collection pin [get_pins [get_object_name $inst]/* -filter "port_type == signal"] {
        if {[get_attribute [get_pins $pin] direction] == "in"} {
            if {[sizeof_collection [all_fanin -to $pin -flat]] > $n_pin_conn} {
                set n_pin_conn [sizeof_collection [all_fanin -to $pin -flat]]
                set power [get_attribute [get_attribute $pin UPF_related_supply_set] name]
                set power [regsub -all "SS_" $power {}]
            }
        } else {
            if {[sizeof_collection [all_fanout -from $pin -flat]] > $n_pin_conn} {
                set n_pin_conn [sizeof_collection [all_fanout -from $pin -flat]]
                set power [get_attribute [get_attribute $pin UPF_related_supply_set] name]
                set power [regsub -all "SS_" $power {}]
            }
        }
    }
    puts "# [get_object_name $inst] $power"
}
}

proc checkDefSize {h_grid h_offset v_grid v_offset} {
set bbox [get_attribute [current_design] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]
set w_test [expr ($urx_tile - $llx_tile - $h_offset)/$h_grid]
set h_test [expr ($ury_tile - $lly_tile - $v_offset)/$v_grid]
if {[regexp {\..*[1-9]} $w_test]} {
    puts "# ERROR: tile width is not the multiples of $w_test $h_grid with $h_offset"
}
if {[regexp {\..*[1-9]} $h_test]} {
    puts "# ERROR: tile height is not the multiples $h_test of $v_grid with $v_offset"
}

}

proc checkPushDownMacros {x_grid x_offset  y_grid y_offset} {
set bbox [get_attribute [current_design ] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]

foreach_in_collection macro [get_cells -hierarchical * -filter "design_type == macro" ] {
    set bbox [get_attribute $macro boundary_bbox]
    set llx [lindex $bbox 0 0]
    set lly [lindex $bbox 0 1]
    set urx [lindex $bbox 1 0]
    set ury [lindex $bbox 1 1]
    set llx_test [expr ($llx - $llx_tile - $x_offset)/$x_grid]
    set lly_test [expr ($lly - $lly_tile - $y_offset)/$y_grid]
    if {[regexp {\..*[1-9]} $llx_test]} {
        puts "# ERROR: [get_object_name $macro] not on x grid"
    }
    if {[regexp {\..*[1-9]} $lly_test]} {
        puts "# ERROR: [get_object_name $macro] not on half row"
    }
}

}


proc alignVdciPins {align_side} {
set top [get_attribute [current_design] name]
set o [open data/alignVdciPins.list w]
set c [open data/alignVdciPins.tcl w]

if {[file exists  data/upf/GetUpf.upf]} {
    load_upf data/upf/GetUpf.upf
} else {
    puts "ERROR: upf is missing for vdci tiles."
}
puts "# Find pair by iterating word from end"
foreach_in_collection port [get_ports *] {
    set pin_name [get_object_name $port]
    #puts "$pin_name $pin_pg"
    set pattern ""
    set word_list [regsub -all {_} [get_object_name $port] { }]
    set found 0
    set pg [get_attribute [get_attribute [get_port $port] UPF_related_supply_set] name]
    set pg [regsub -all "SS_" $pg {}]
    set pin_pg_h($port) $pg
    for { set i [expr [llength $word_list] - 1] } { $i >= 0} {incr i -1} {
        set pattern "[lindex $word_list $i]*$pattern"
        #puts "$word_list $pattern $i"
        if {[sizeof_collection [get_ports *$pattern*]] == 2} {
            set pair [get_object_name [get_ports *$pattern*]]
            set pair [regsub -all "{" $pair {}]
            set pair [regsub -all "}" $pair {}]
            set port0 [lindex $pair 0]
            set port1 [lindex $pair 1]
            set pg0 [get_attribute [get_attribute [get_port $port0] UPF_related_supply_set] name]
            set pg1 [get_attribute [get_attribute [get_port $port1] UPF_related_supply_set] name]
            set pg0 [regsub -all "SS_" $pg0 {}]
            set pg1 [regsub -all "SS_" $pg1 {}]
            set pin_pg_h($port0) $pg0
            set pin_pg_h($port1) $pg1

            if {$pg0 != $pg1} {
                if {[info exists pg_h($pg0)] && $pg0 != "" } {
                    set pg_h($pg0) "$pg_h($pg0) $port0"
                } else {
                    set pg_h($pg0) "$port0"
                }
                if {[info exists pg_h($pg1)] && $pg1 != ""} {
                    set pg_h($pg1) "$pg_h($pg1) $port1"
                } else {
                    set pg_h($pg1) "$port1"
                }
                #puts $pair
                set pin_pair_h($port0) $port1
                set pin_pair_h($port1) $port0
                set is_pair_h($port0) 1
                set is_pair_h($port1) 1
                set pin_pg_h([get_object_name $port]) $pin_pg
                set found 1
            }
        } 
    }
    if {$found == 0} {
        set pin_pg [get_attribute [get_attribute $port UPF_related_supply_set] name]
        set non_pair_h([get_object_name $port]) 1
    }
}    
set bbox [get_attribute [current_design] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]
set w [expr $urx_tile - $llx_tile]
set h [expr $ury_tile - $lly_tile]
puts "# Find pair by replacing keyword with *"
set pair_key "Slave Master in out"
set found 0
set port_h(t) ""
set port_h(b) ""
set port_h(r) ""
set port_h(l) ""


foreach_in_collection port [get_ports *] {
    set bbox_pin [get_attribute [get_port $port] bbox]
    set llx_pin [lindex $bbox_pin 0 0]
    set lly_pin [lindex $bbox_pin 0 1]
    set urx_pin [lindex $bbox_pin 1 0]
    set ury_pin [lindex $bbox_pin 1 1]
    set port_name [get_object_name $port]
    if {$lly_pin  > 0 & $llx_pin > [expr $llx_tile + 10] && $llx_pin < [expr $urx_tile - 10] } {
        set port_h(t) "$port_h(t) $port_name" 
    }
    if {$lly_pin  < 0 & $llx_pin > [expr $llx_tile + 10] && $llx_pin < [expr $urx_tile - 10] } {
        set port_h(b) "$port_h(b) $port_name"
        puts "# $port_name add to bottom"
    }
    if {$llx_pin  > 0 & $lly_pin > [expr $lly_tile + 10] && $lly_pin < [expr $ury_tile - 10] } {
        set port_h(r) "$port_h(r) $port_name"
    }
    if {$llx_pin  < 0 & $lly_pin > [expr $lly_tile + 10] && $lly_pin < [expr $ury_tile - 10] } {
        set port_h(l) "$port_h(l) $port_name"

    }

}
set vdd_main_list "VDDCR_SOC VDDCR_SOCIO"
foreach pg [array names pg_h] {
    set pg_h($pg) [lsort -u $pg_h($pg)]
    foreach port $pg_h($pg) {
       puts $o "$pg $port $pin_pair_h($port)"
    }
}

puts "# chose width as pin side"
set pin_spec [getMajorPinWidth]
if {[regexp {(.*):(\S+),(.*):(\S+)} $pin_spec match h_spec h_pitch v_spec v_pitch]} {
    puts "$h_spec $h_pitch $v_spec $v_pitch"
}
set n_h_spec [llength $h_spec]
set n_v_spec [llength $v_spec]
set n_ports [sizeof_collection [get_ports *]]
if {$align_side == "b"} {
    foreach port $port_h(b) {
        set bbox_pin [get_attribute [get_port $port] bbox] 
        if {[info exist pin_pair_h($port)]} {
        } else {
            continue
        }
        puts "bbox_pin $bbox_pin"
        set llx_pin [lindex $bbox_pin 0 0] 
        set lly_pin [lindex $bbox_pin 0 1]
        set urx_pin [lindex $bbox_pin 1 0]
        set ury_pin [lindex $bbox_pin 1 1]
        set x $llx_pin
        set y $ury_tile
        set layer [get_attribute [get_ports $port] layer_name]
        puts "# align pins $port $pin_pair_h($port) $x $y"
        #puts $c "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        #eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        puts $c "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        eval "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        # write opposite pin loc
        #unplacePort $port
        unplacePort $pin_pair_h($port)
    }
    set ports [get_ports * -filter "physical_status == unplaced"]
    place_pins -ports [get_ports $ports]


} 
if {$align_side == "t"} {
    foreach port $port_h(t) {
        set bbox_pin [get_attribute [get_port $port] bbox]
        if {[info exist pin_pair_h($port)]} {
        } else {
            continue
        }
        puts "bbox_pin $bbox_pin"
        set llx_pin [lindex $bbox_pin 0 0]
        set lly_pin [lindex $bbox_pin 0 1]
        set urx_pin [lindex $bbox_pin 1 0]
        set ury_pin [lindex $bbox_pin 1 1]
        set x $llx_pin
        set y $lly_tile
        set layer [get_attribute [get_ports $port] layer_name]
        puts "# align pins $port $pin_pair_h($port) $x $y"
        #puts $c "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        #eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        puts $c "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        eval "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        # write opposite pin loc
        #unplacePort $port
        unplacePort $pin_pair_h($port)
    }
    set ports [get_ports * -filter "physical_status == unplaced"]
    place_pins -ports [get_ports $ports]


}
if {$align_side == "l"} {
    foreach port $port_h(l) {
        set bbox_pin [get_attribute [get_port $port] bbox]
        if {[info exist pin_pair_h($port)]} {
        } else {
            continue
        }
        puts "bbox_pin $bbox_pin"
        set llx_pin [lindex $bbox_pin 0 0]
        set lly_pin [lindex $bbox_pin 0 1]
        set urx_pin [lindex $bbox_pin 1 0]
        set ury_pin [lindex $bbox_pin 1 1]
        set x $urx_tile
        set y $lly_pin
        set layer [get_attribute [get_ports $port] layer_name]
        puts "# align pins $port $pin_pair_h($port) $x $y"
        #puts $c "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        #eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        puts $c "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        eval "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        # write opposite pin loc
        #unplacePort $port
        unplacePort $pin_pair_h($port)
    }
    set ports [get_ports * -filter "physical_status == unplaced"]
    place_pins -ports [get_ports $ports]


}
if {$align_side == "r"} {
    foreach port $port_h(r) {
        set bbox_pin [get_attribute [get_port $port] bbox]
        if {[info exist pin_pair_h($port)]} {
        } else {
            continue
        }
        puts "bbox_pin $bbox_pin"
        set llx_pin [lindex $bbox_pin 0 0]
        set lly_pin [lindex $bbox_pin 0 1]
        set urx_pin [lindex $bbox_pin 1 0]
        set ury_pin [lindex $bbox_pin 1 1]
        set x $llx_tile
        set y $lly_pin
        set layer [get_attribute [get_ports $port] layer_name]
        puts "# align pins $port $pin_pair_h($port) $x $y"
        #puts $c "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        #eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        puts $c "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        eval "set_individual_pin_constraints -ports $pin_pair_h($port) -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        # write opposite pin loc
        #unplacePort $port
        unplacePort $pin_pair_h($port)
    }
    set ports [get_ports * -filter "physical_status == unplaced"]
    place_pins -ports [get_ports $ports]


}

close $c
source data/alignVdciPins.tcl
close $o
writePortDef data/$top.pin.def.gz
}

proc placePinByOrder {pin_list dir x_s y_s} {
puts "# usage: h means horizontal"
puts "placePinByOrder pin_list.txt h -40.2 -30.3"
set n 3
set depth 0.4
set f [open $pin_list r]
set o [open placePinByOrder.tcl w]
set ports ""
puts "# chose width as pin side"
set pin_spec [getMajorPinWidth]
if {[regexp {(.*):(\S+),(.*):(\S+)} $pin_spec match h_spec h_pitch v_spec v_pitch]} {
    puts "$h_spec $h_pitch $v_spec $v_pitch"
}
set n_h_spec [llength $h_spec]
set n_v_spec [llength $v_spec]
set bbox [get_attribute [current_design] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]
set n_step 0
set n_layer 0
while {[gets $f line] >= 0} {
    set port [lindex $line 0]
    set layer [lindex $line 3]
    if {[sizeof_collection [get_port -quiet $port]] == 0} {
        puts "$port does not exist"
        continue
    }
    if {$dir == "h"} {
        set step [expr $v_pitch * 2]
        set x [expr $x_s + $step * $n_step]
        if {$y_s > 0} {
            set y $ury_tile
        } else {
            set y $lly_tile
        }
        if {$n_layer == [expr [llength $v_spec] - 1]} {
            incr n_step
            set n_layer 0
            set layer [lindex $v_spec $n_layer]
        } else {
            incr n_layer
            set layer [lindex $v_spec $n_layer]
        }

        if {$x < $llx_tile || $x > $urx_tile} {
            puts "# $port $x out of boundary $llx_tile $urx_tile"
            continue
        }
        puts $o "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        unplacePort $port

    } else {
        set step [expr $h_pitch * 2]
        set y [expr $y_s + $step * $n_step]
        if {$x_s > 0} {
            set x $urx_tile
        } else {
            set x $llx_tile
        }
        if {$n_layer == [expr [llength $h_spec] - 1]} {
            incr n_step
            set n_layer 0
            set layer [lindex $h_spec $n_layer]
        } else {
            incr n_layer
            set layer [lindex $h_spec $n_layer]
        }

        if {$y < $lly_tile || $y > $ury_tile} {
            puts "# $port $y out of boundary $lly_tile $ury_tile"
            continue
        }
        puts $o "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        eval "set_individual_pin_constraints -ports $port -length 0.4 -pin_spacing 2 -allowed_layers {$layer} -location {$x $y}"
        unplacePort $port

    }
}
set ports [get_ports * -filter "physical_status == unplaced"]
place_pins -ports [get_ports $ports]
close $o
close $f

}

proc placePinsFromPoint {pin_list x_s y_s} {
set pre_p  ""
set dir h
foreach p [get_attribute [current_design] boundary] {
    if {[llength $pre_p] == 0} {
        set pre_p $p
        continue
    }
    set cur_x [lindex $p 0]
    set cur_y [lindex $p 1]
    set pre_x [lindex $pre_p 0]
    set pre_y [lindex $pre_p 1]
    if {[expr $pre_x - $cur_x] == 0} {
        set dir v 
    } else {
        set dir h
    }
}
}

proc checkMacroPGFloating {} {
check_pg_connectivity -check_macro_pins all -write_connectivity_file pg.rpt
set f [open pg.rpt r]
set float_flag 0
while {[gets $f line] >= 0} {
    if {[regexp {Number\s+of\s+floating\s+hard\s+macros:\s(\S+)} $line match n_float]} {
        if {$n_float > 0} {
            set float_flag 1
            continue
        }
    }
    if {$float_flag > 0} {
        puts "ERROR: Found Macro PG Floating $line"
        set float_flag 0
    }
}

}

proc checkSpareCell {th prefix size} {
# check list TILE_PnR-T03-003 @Reroute or Place
# checkSpareCell 0.3 SPARE_lo 70
set bbox [get_attribute [current_design] boundary_bbox]
set llx_tile [lindex $bbox 0 0]
set lly_tile [lindex $bbox 0 1]
set urx_tile [lindex $bbox 1 0]
set ury_tile [lindex $bbox 1 1]

set block_ll_x $llx_tile
set block_ll_y $lly_tile
set block_ur_x $urx_tile
set block_ur_y $ury_tile
set win_size_x $size
set win_size_y $size
# Calculate number of windows in x and y direction
set num_win_x [expr {int(ceil(double($block_ur_x - $block_ll_x) / $win_size_x))}]
set num_win_y [expr {int(ceil(double($block_ur_y - $block_ll_y) / $win_size_y))}]
set n_ideal [expr $num_win_x*$num_win_y]

set found_any 0
set n_actual 0
for {set ix 0} {$ix < $num_win_x} {incr ix} {
    for {set iy 0} {$iy < $num_win_y} {incr iy} {
        set win_ll_x [expr {$block_ll_x + $ix * $win_size_x}]
        set win_ll_y [expr {$block_ll_y + $iy * $win_size_y}]
        set win_ur_x [expr {min($win_ll_x + $win_size_x, $block_ur_x)}]
        set win_ur_y [expr {min($win_ll_y + $win_size_y, $block_ur_y)}]
        set window_ll [list $win_ll_x $win_ll_y]
        set window_ur [list $win_ur_x $win_ur_y]
        set spare_lo_cells [get_objects_by_location -quiet -within [list $window_ll $window_ur] -classes cell -filter full_name=~"$prefix*"]
        if {[sizeof_collection $spare_lo_cells] > 0} {
            set found_any 1
            set n_actual [expr $n_actual + 1]
            puts "Window [list $window_ll $window_ur]: Found [sizeof_collection $spare_lo_cells] cells named $prefix"
            foreach_in_collection cell $spare_lo_cells {
                puts "    Cell: [get_attribute -quiet $cell full_name]"
            }
        }
    }
}

if {!$found_any} {
    puts "No cells named SPARE_lo found in any $size um x $size um window of block."
} 
puts "# $prefix ratio is $n_ideal $n_actual  [expr $n_actual*1.0 / $n_ideal ]"

}

proc checkMemChannelReg {th} {
# checklist TILE_PnR-T01-016 @Reroute or Place
# checkMemChannelReg 10
# Identify channels between memory blocks with width 10um
set mem_cells [get_cells -quiet -filter {design_type=="memory" || design_type=="macro"} -hierarchical ]
set channels [identify_channels $mem_cells -horizontal_threshold $th -vertical_threshold $th]

# Get all registers in the design
set regs [get_cells -quiet -hierarchical -filter is_sequential]

# For each channel, check if any register is inside the channel boundary
foreach chans $channels {
    set chan_boundary [get_attribute -quiet $chans boundary]
    set regs_in_chan [get_cells [get_cells -quiet -within "$chans"] -filter is_sequential]
    #set regs_in_chan [get_cells -quiet -filter [subst {is_sequential && boundary=~"$chan_boundary"}]]
    #set regs_in_chan [get_cells -quiet -filter [subst {is_sequential && boundary=~"$chans"}]]
    if {[sizeof_collection $regs_in_chan] > 0} {
        #puts "Registers found in channel with width $th um between memory blocks:"
        foreach_in_collection reg $regs_in_chan {
            puts "ERROR: TILE_PnR-T01-016 $chans [get_attribute -quiet $reg full_name]"
        }
    }
}
}

proc checkFeedAlignment {ports port_th detour_th} {
# checklist TILE_PnR-T04-002 @Reoute
# checkFeedAlignment FE_FEED* 50 50
foreach_in_collection track [get_tracks] {
    set layer [get_attribute $track layer_name]
    set pitch_h($layer) [get_attribute $track space]
    set direction_h($layer) [get_attribute $track direction]
    puts "$layer $pitch_h($layer) $direction_h($layer)"
}

foreach_in_collection port [get_ports $ports] {
    if {[sizeof_collection [get_shapes -of_objects [get_ports $port]]] > 1} {
        continue
    }
    set layer [get_attribute [get_ports $port] layer_name]
    set llx [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 0]
    set lly [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 1]
    set urx [lindex [lindex [get_attribute [get_ports $port] bbox] 1 ] 0]
    set ury [lindex [lindex [get_attribute [get_ports $port] bbox] 1 ] 1]

    set port_name [get_object_name $port]
    set aligned_port_pattern [regsub {__} $port_name { }]
    set aligned_port_pattern [regsub {__} $aligned_port_pattern { }]
    set aligned_port_pattern [regsub {__} $aligned_port_pattern { }]
    set aligned_port_pattern [regsub {__} $aligned_port_pattern { }]
    set aligned_port_pattern [lindex $aligned_port_pattern 4]
    #set aligned_port_pattern [regsub {FE_FEEDX_MFT_[0-9]__\S+__\S+__} $aligned_port_pattern {}]
    set aligned_port [get_ports FE_FEED*${aligned_port_pattern}*] 
    #set aligned_port [remove_from_collection [get_ports *${aligned_port}*] [get_ports $port]]
    #puts "[get_object_name  $aligned_port]"
    if {[sizeof_collection $aligned_port]!=2} { continue}
    #puts "$aligned_port_pattern [get_object_name  $aligned_port]" 
    set port0 [lindex [get_object_name  $aligned_port] 0]
    set port1 [lindex [get_object_name  $aligned_port] 1]
    set pin_layer($port0) [get_attribute $port0 layer_name]
    set pin_layer($port1) [get_attribute $port1 layer_name]
    
    if {$direction_h($pin_layer($port0)) == $direction_h($pin_layer($port1))} {
    } else {
        puts "$port0 $port1 are not same direction."
        continue
    }
    set llx0 [lindex [lindex [get_attribute [get_ports $port0] bbox] 0 ] 0]
    set lly0 [lindex [lindex [get_attribute [get_ports $port0] bbox] 0 ] 1]
    set llx1 [lindex [lindex [get_attribute [get_ports $port1] bbox] 0 ] 0]
    set lly1 [lindex [lindex [get_attribute [get_ports $port1] bbox] 0 ] 1]

    if {[expr abs($llx0 - $llx1)] > $port_th && $direction_h($pin_layer($port0)) == "vertical"} {
        puts "# ERROR: $port0 $port1 not aligned. [expr abs($llx0 - $llx1)]"
    }
    if {[expr abs($lly0 - $lly1)] > $port_th && $direction_h($pin_layer($port0)) == "horizontal"} {
        puts "# ERROR: $port0 $port1 not aligned. [expr abs($lly0 - $lly1)]"
    }
    foreach p [get_object_name $aligned_port] {
        if {[get_attribute [get_port $p] direction] == "in"}  {
            set llxp [lindex [lindex [get_attribute [get_ports $p] bbox] 0 ] 0]
            set llyp [lindex [lindex [get_attribute [get_ports $p] bbox] 0 ] 1]

            foreach_in_collection inst [all_fanout -from [get_port $p] -only_cells -flat] {
                set llx [lindex [lindex [get_attribute [get_cells $inst] bbox] 0 ] 0]
                set lly [lindex [lindex [get_attribute [get_cells $inst] bbox] 0 ] 1]
                if {[expr abs($llx - $llxp)] > $detour_th && $direction_h($pin_layer($p)) == "vertical"} {

                    puts "# ERROR: TILE_PnR-T04-002 $p [get_object_name $inst] detour. [expr abs($llx - $llxp)]"
                }
                if {[expr abs($lly - $llyp)] > $detour_th && $direction_h($pin_layer($p)) == "horizontal"} {

                    puts "# ERROR: TILE_PnR-T04-002 $p [get_object_name $inst] detour. [expr abs($lly - $llyp)]"
                }
            }
        } else {
            foreach_in_collection inst [all_fanin -to [get_port $p] -only_cells -flat] {
                set llx [lindex [lindex [get_attribute [get_cells $inst] bbox] 0 ] 0]
                set lly [lindex [lindex [get_attribute [get_cells $inst] bbox] 0 ] 1]
                if {[expr abs($llx - $llxp)] > $detour_th && $direction_h($pin_layer($p)) == "vertical"} {
                    
                    puts "# ERROR: TILE_PnR-T04-002 $p [get_object_name $inst] detour. [expr abs($llx - $llxp)]"
                }
                if {[expr abs($lly - $llyp)] > $detour_th && $direction_h($pin_layer($p)) == "horizontal"} {
                    
                    puts "# ERROR: TILE_PnR-T04-002 $p [get_object_name $inst] detour. [expr abs($lly - $llyp)]"
                }
            }
        }

    }

}
}

proc checkIOBuf {th} {
# checklist TILE_FCT-T01-002 @ReRoute
# checkIOBuf 20
foreach_in_collection port [get_ports *] {
    if {[regexp {FEED} [get_object_name $port]]} {
        continue
    }
    if {[regexp {cloc} [get_object_name $port]]} {
        continue
    }
    if {[regexp {Wrck} [get_object_name $port]]} {
        continue
    }
    if {[regexp {CLK} [get_object_name $port]]} {
        continue
    }

    if {[get_attribute [get_port $port] direction] == "in"}  {
        set llxp [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 0]
        set llyp [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 1]

        foreach_in_collection inst [all_fanout -from [get_port $port] -only_cells -flat -levels 1] {
            if {[regexp {BUF} [get_object_name $inst]]} {
            } else {
                puts "# ERROR: TILE_FCT-T01-002 No BUF for [get_object_name $port]"
            }
            set llx [lindex [lindex [get_attribute [get_cells $inst] bbox] 0 ] 0]
            set lly [lindex [lindex [get_attribute [get_cells $inst] bbox] 0 ] 1]
            if {[expr abs($llx - $llxp) + abs($lly - $llyp)] > $th} {
                puts "# ERROR: TILE_FCT-T01-002 distance from [get_object_name $inst] to [get_object_name $port] exceed $th"
            }
        }
    }

}

}

proc checkLocalDensity {size th} {
# checklist TILE_FCT-T01-003 
# checkLocalDensity 10 0.9
set llx_core [lindex [get_attribute [current_design] core_area_boundary] 0 0]
set lly_core [lindex [get_attribute [current_design] core_area_boundary] 0 1]
set urx_core [lindex [get_attribute [current_design] core_area_boundary] 2 0]
set ury_core [lindex [get_attribute [current_design] core_area_boundary] 2 1]
set geo_core [create_geo_mask -objects "{$llx_core $lly_core} {$urx_core $ury_core}"]
set x_step [expr ($urx_core - $llx_core)/$size]
set y_step [expr ($ury_core - $lly_core)/$size]
for { set i 0 } { $i < $x_step } {incr i} {
    set x_bin [expr $llx_core + $i*$size]
    for { set j 0 } { $j < $y_step } {incr j} {
        set y_bin [expr $lly_core + $j*$size]
        set cells_bin [filter_collection [get_cells -within "{$x_bin $y_bin} {[expr $x_bin + $size] [expr $y_bin + $size]}"] "name !~ *ENDCAP* && name !~ *GADCAP* && name !~ *filler* && name !~ *FILL*"]
        
        set geo_cell [create_geo_mask -objects [get_attribute [get_cells $cells_bin] bbox]]
        set geo_bin [create_geo_mask -objects "{[expr $x_bin- 0.0]  [expr $y_bin - 0.0]} {[expr $x_bin + $size + 0.0] [expr $y_bin + $size + 0.0]}"] 
        set geo_bin_core [compute_polygons -objects1 $geo_bin -objects2 $geo_core -operation AND]
        set area_not [compute_area [compute_polygons -objects1 $geo_bin_core -objects2 $geo_cell -operation NOT]]
        set area_geo_bin_core [compute_area $geo_bin_core]
        set density [expr 1 - $area_not / $area_geo_bin_core]
        if {$density > $th} {
            puts "# ERROR: TILE_FCT-T01-003  Local density higher than $th: $x_bin $y_bin [expr $x_bin + $size] [expr $y_bin + $size] [expr 1 - $area_not / $area_geo_bin_core]"
            puts "[get_attribute $geo_bin_core bbox] # [get_attribute $geo_cell bbox] # [get_attribute [compute_polygons -objects1 $geo_bin_core -objects2 $geo_cell -operation NOT] bbox]"
        } else {
            #puts "# ERROR: Local density higher than $th: $x_bin $y_bin [expr $x_bin + $size] [expr $y_bin + $size] [expr 1 - $area_not / $area_geo_bin_core]"
            #puts "[get_attribute $geo_bin_core bbox] # [get_attribute $geo_cell bbox] # [get_attribute [compute_polygons -objects1 $geo_bin_core -objects2 $geo_cell -operation NOT] bbox]"
        }
    }
}
}

proc checkPGPitch {m_top offset_top m_mid pitch_mid width_mid m_bot pitch_bot width_bot} {
# checklist TILE_POWER-T03-003 
# checkPGPitch M15 1.117 M1 0.384 0.028 M4 0.105 0.018
set llx_core [lindex [get_attribute [current_design] core_area_boundary] 0 0]
set lly_core [lindex [get_attribute [current_design] core_area_boundary] 0 1]
set urx_core [lindex [get_attribute [current_design] core_area_boundary] 2 0]
set ury_core [lindex [get_attribute [current_design] core_area_boundary] 2 1]
set geo_core [create_geo_mask -objects "{$llx_core $lly_core} {$urx_core $ury_core}"]
set geo_m_top [create_geo_mask -objects [get_attribute  [filter_collection [get_shapes -of_objects [get_nets VDD*]] "layer_name == $m_top"] bbox]]
set geo_m_top [resize_polygons $geo_m_top -size {5}]
set geo_m_top [resize_polygons $geo_m_top -size {-5}]
set and_core_m_top [compute_polygons -objects1 $geo_core -objects2 $geo_m_top -operation NOT]
set pith_top_flag 0
foreach_in_collection bbox  [get_attribute $and_core_m_top poly_rects] {
    set llx [lindex [get_attribute $bbox bbox] 0 0]
    set urx [lindex [get_attribute $bbox bbox] 1 0]
    #puts [lindex [get_attribute $bbox bbox] 0]
    #puts [lindex [get_attribute $bbox bbox] 1]
    #puts "$llx $urx"
    puts "# $m_top offset is [expr $urx - $llx] vs  $offset_top"
}
set geo_m_mid [create_geo_mask -objects [get_attribute  [filter_collection [get_shapes -of_objects [get_nets VDD*]] "layer_name == $m_mid && shape_use == stripe && width == $width_mid"] bbox]]
set m_mid_count [sizeof_collection [filter_collection [get_shapes -of_objects [get_nets VDD*]] "layer_name == $m_mid && shape_use == stripe && width == $width_mid"]]
puts "# $m_mid shape with width $width_mid $m_mid_count"
set llx_pre 0
set urx_pre 0
set n 0
foreach_in_collection bbox  [get_attribute $geo_m_mid poly_rects] {
    set llx [lindex [get_attribute $bbox bbox] 0 0]
    set lly [lindex [get_attribute $bbox bbox] 0 1]
    if {[info exists m_mid_x_h($lly)]} {
        set m_mid_x_h($lly) "$m_mid_x_h($lly) $llx"
    } else {
        set m_mid_x_h($lly) $llx
    }
    if {$n > 100000} {break}
    incr n
}
set m_mid_pitch_correct 0
foreach lly [array names m_mid_x_h] {
    set m_mid_pitch_y 0
    set m_mid_x_h($lly) [lsort -increasing -real $m_mid_x_h($lly)]
    #puts "$lly $m_mid_x_h($lly)"
    if {[llength $m_mid_x_h($lly)] > 10} {
        for { set i 0 } { $i < [llength $m_mid_x_h($lly)] } {incr i} {
            set pitch [expr [lindex $m_mid_x_h($lly) [expr $i + 1]] - [lindex $m_mid_x_h($lly) $i]]
            #puts "$lly $pitch $pitch_mid [expr $pitch - $pitch_mid] $m_mid_pitch_y"
            if {[expr $pitch - $pitch_mid] == 0} {
                incr m_mid_pitch_correct
                incr m_mid_pitch_y
            }
        }
    }
    #puts "# $m_mid shape with pitch $pitch_mid $m_mid_pitch_y [llength $m_mid_x_h($lly)]"

}
puts "# $m_mid shape with pitch $pitch_mid $m_mid_pitch_correct"

set geo_m_bot [create_geo_mask -objects [get_attribute  [filter_collection [get_shapes -of_objects [get_nets VDD*]] "layer_name == $m_bot && shape_use == stripe && width == $width_bot"] bbox]]
set m_bot_count [sizeof_collection [filter_collection [get_shapes -of_objects [get_nets VDD*]] "layer_name == $m_bot && shape_use == stripe && width == $width_bot"]]
puts "# $m_bot shape with width $width_bot $m_bot_count"
set llx_pre 0
set urx_pre 0
set n 0
foreach_in_collection bbox  [get_attribute $geo_m_bot poly_rects] {
    set llx [lindex [get_attribute $bbox bbox] 0 0]
    set lly [lindex [get_attribute $bbox bbox] 0 1]
    #puts "$llx $lly"
    if {[info exists m_bot_y_h($llx)]} {
        set m_bot_y_h($llx) "$m_bot_y_h($llx) $lly"
    } else {
        set m_bot_y_h($llx) $lly
    }
    if {$n > 100000} {break}
    incr n
}
set m_bot_pitch_correct 0
foreach llx [array names m_bot_y_h] {
    set m_bot_pitch_x 0
    set m_bot_y_h($llx) [lsort -increasing -real $m_bot_y_h($llx)]
    #puts "$lly $m_mid_x_h($lly)"
    if {[llength $m_bot_y_h($llx)] > 10} {
        for { set i 0 } { $i < [llength $m_bot_y_h($llx)] } {incr i} {
            set pitch [expr [lindex $m_bot_y_h($llx) [expr $i + 1]] - [lindex $m_bot_y_h($llx) $i]]
            #puts "$lly $pitch $pitch_bot [expr $pitch - $pith_bot] $m_bot_pitch_y"
            if {[expr $pitch - $pitch_bot] == 0} {
                incr m_bot_pitch_correct
                incr m_bot_pitch_x
            }
        }
    }
    #puts "# $m_mid shape with pitch $pitch_bot $m_mid_pitch_y [llength $m_mid_x_h($lly)]"

}
puts "# $m_bot shape with pitch $pitch_bot $m_bot_pitch_correct"
}

proc checkSRAMPG {m_h pitch_m_h m_v pitch_m_v} {
# checklist TILE_POWER-T03-004 
# checkSRAMPG M6 1.064 M7 0.76
set mem_cells [get_cells -quiet -filter {design_type=="memory" || design_type=="macro"} -hierarchical ]
foreach_in_collection mem $mem_cells {
    #puts "[get_object_name $mem]"
    if {[regexp {PUSHDOWN} [get_object_name $mem]]} {continue}
    set geo_mem [create_geo_mask -objects [get_attribute $mem bbox]]
    set geo_m_h [create_geo_mask -objects [get_attribute  [filter_collection [get_shapes -of_objects [get_nets VDD*]] "layer_name == $m_h && shape_use == stripe"] bbox]]
    set geo_m_h_mem [compute_polygons -objects1 $geo_mem -objects2 $geo_m_h -operation AND]
    array unset m_h_y_h
    foreach_in_collection bbox  [get_attribute $geo_m_h_mem poly_rects] {
        set llx [lindex [get_attribute $bbox bbox] 0 0]
        set lly [lindex [get_attribute $bbox bbox] 0 1]
        # puts "$llx $lly"
        if {[info exists m_h_y_h($llx)]} {
            set m_h_y_h($llx) "$m_h_y_h($llx) $lly"
        } else {
            set m_h_y_h($llx) $lly
        }
    }
    set m_h_pitch_correct 0
    # puts "$m_h_pitch_correct "
    foreach llx [array names m_h_y_h] {
        set m_h_pitch_x 0
        set m_h_y_h($llx) [lsort -increasing -real $m_h_y_h($llx)]
        #puts "$llx $m_h_y_h($llx)"
        if {[llength $m_h_y_h($llx)] > 10} {
            for { set i 0 } { $i < [llength $m_h_y_h($llx)] } {incr i} {
                set pitch [expr [lindex $m_h_y_h($llx) [expr $i + 1]] - [lindex $m_h_y_h($llx) $i]]
                # puts "$llx $pitch $pitch_m_h [expr $pitch - $pitch_m_h] $m_h_pitch_x"
                if {[expr $pitch - $pitch_m_h] == 0} {
                    incr m_h_pitch_correct
                    incr m_h_pitch_x
                }
            }
        }
        #puts "# $m_mid shape with pitch $pitch_bot $m_mid_pitch_y [llength $m_mid_x_h($lly)]"

    }
    puts "# [get_object_name $mem] $m_h VDD shape with pitch $pitch_m_h [get_attribute $geo_m_h_mem shape_count] $m_h_pitch_correct"

    set geo_m_h [create_geo_mask -objects [get_attribute  [filter_collection [get_shapes -of_objects [get_nets VSS*]] "layer_name == $m_h && shape_use == stripe"] bbox]]
    set geo_m_h_mem [compute_polygons -objects1 $geo_mem -objects2 $geo_m_h -operation AND]
    array unset m_h_y_h
    foreach_in_collection bbox  [get_attribute $geo_m_h_mem poly_rects] {
        set llx [lindex [get_attribute $bbox bbox] 0 0]
        set lly [lindex [get_attribute $bbox bbox] 0 1]
        # puts "$llx $lly"
        if {[info exists m_h_y_h($llx)]} {
            set m_h_y_h($llx) "$m_h_y_h($llx) $lly"
        } else {
            set m_h_y_h($llx) $lly
        }
    }
    set m_h_pitch_correct 0
    # puts "$m_h_pitch_correct "
    foreach llx [array names m_h_y_h] {
        set m_h_pitch_x 0
        set m_h_y_h($llx) [lsort -increasing -real $m_h_y_h($llx)]
        #puts "$llx $m_h_y_h($llx)"
        if {[llength $m_h_y_h($llx)] > 10} {
            for { set i 0 } { $i < [llength $m_h_y_h($llx)] } {incr i} {
                set pitch [expr [lindex $m_h_y_h($llx) [expr $i + 1]] - [lindex $m_h_y_h($llx) $i]]
                # puts "$llx $pitch $pitch_m_h [expr $pitch - $pitch_m_h] $m_h_pitch_x"
                if {[expr $pitch - $pitch_m_h] == 0} {
                    incr m_h_pitch_correct
                    incr m_h_pitch_x
                }
            }
        }
        #puts "# $m_mid shape with pitch $pitch_bot $m_mid_pitch_y [llength $m_mid_x_h($lly)]"

    }
    puts "# [get_object_name $mem] $m_h VSS shape with pitch $pitch_m_h [get_attribute $geo_m_h_mem shape_count] $m_h_pitch_correct"

    set geo_m_v [create_geo_mask -objects [get_attribute  [filter_collection [get_shapes -of_objects [get_nets VDD*]] "layer_name == $m_v && shape_use == stripe"] bbox]]
    set geo_m_v_mem [compute_polygons -objects1 $geo_mem -objects2 $geo_m_v -operation AND]
    array unset m_v_x_h
    foreach_in_collection bbox  [get_attribute $geo_m_v_mem poly_rects] {
        set llx [lindex [get_attribute $bbox bbox] 0 0]
        set lly [lindex [get_attribute $bbox bbox] 0 1]
        # puts "$llx $lly"
        if {[info exists m_v_x_h($lly)]} {
            set m_v_x_h($lly) "$m_v_x_h($lly) $llx"
        } else {
            set m_v_x_h($lly) $llx
        }
    }
    set m_v_pitch_correct 0
    # puts "$m_v_pitch_correct "
    foreach llx [array names m_v_x_h] {
        set m_v_pitch_y 0
        set m_v_x_h($lly) [lsort -increasing -real $m_v_x_h($lly)]
        # puts "$llx $m_v_x_h($lly)"
        if {[llength $m_v_x_h($lly)] > 10} {
            for { set i 0 } { $i < [llength $m_v_x_h($lly)] } {incr i} {
                set pitch [expr [lindex $m_v_x_h($lly) [expr $i + 1]] - [lindex $m_v_x_h($lly) $i]]
                # puts "$llx $pitch $pitch_m_v [expr $pitch - $pitch_m_v] $m_v_pitch_y"
                if {[expr $pitch - $pitch_m_v] == 0} {
                    incr m_v_pitch_correct
                    incr m_v_pitch_y
                }
            }
        }
        #puts "# $m_mid shape with pitch $pitch_bot $m_mid_pitch_y [llength $m_mid_x_h($lly)]"

    }
    puts "# [get_object_name $mem] $m_v VDD shape with pitch $pitch_m_v [get_attribute $geo_m_v_mem shape_count] $m_v_pitch_correct"

    set geo_m_v [create_geo_mask -objects [get_attribute  [filter_collection [get_shapes -of_objects [get_nets VSS*]] "layer_name == $m_v && shape_use == stripe"] bbox]]
    set geo_m_v_mem [compute_polygons -objects1 $geo_mem -objects2 $geo_m_v -operation AND]
    array unset m_v_x_h
    foreach_in_collection bbox  [get_attribute $geo_m_v_mem poly_rects] {
        set llx [lindex [get_attribute $bbox bbox] 0 0]
        set lly [lindex [get_attribute $bbox bbox] 0 1]
        # puts "$llx $lly"
        if {[info exists m_v_x_h($lly)]} {
            set m_v_x_h($lly) "$m_v_x_h($lly) $llx"
        } else {
            set m_v_x_h($lly) $llx
        }
    }
    set m_v_pitch_correct 0
    # puts "$m_v_pitch_correct "
    foreach llx [array names m_v_x_h] {
        set m_v_pitch_y 0
        set m_v_x_h($lly) [lsort -increasing -real $m_v_x_h($lly)]
        # puts "$llx $m_v_x_h($lly)"
        if {[llength $m_v_x_h($lly)] > 10} {
            for { set i 0 } { $i < [llength $m_v_x_h($lly)] } {incr i} {
                set pitch [expr [lindex $m_v_x_h($lly) [expr $i + 1]] - [lindex $m_v_x_h($lly) $i]]
                # puts "$llx $pitch $pitch_m_v [expr $pitch - $pitch_m_v] $m_v_pitch_y"
                if {[expr $pitch - $pitch_m_v] == 0} {
                    incr m_v_pitch_correct
                    incr m_v_pitch_y
                }
            }
        }
        #puts "# $m_mid shape with pitch $pitch_bot $m_mid_pitch_y [llength $m_mid_x_h($lly)]"

    }
    puts "# [get_object_name $mem] $m_v VSS shape with pitch $pitch_m_v [get_attribute $geo_m_v_mem shape_count] $m_v_pitch_correct"

}

}

proc checkRouteOfBoundary {} {
# checklist TILE_PV-T01-006 
# checkRouteOfBoundary
set boundary [get_attribute [current_design] boundary]
set internal_shapes [get_shapes -within "$boundary"]
set external_shapes [remove_from_collection [get_shapes *] $internal_shapes]

set boundary_net [remove_from_collection [get_nets -hierarchical] $internal_net]
set geo_core [create_geo_mask -objects "$boundary"]
set geo_net [create_geo_mask -objects [get_attribute $external_shapes bbox]]
set geo_out_of_boundary [compute_polygons -objects1 $geo_net -objects2 $geo_core -operation NOT]
if {[get_attribute $geo_out_of_boundary shape_count] > 0} {
    puts "# ERROR: TILE_PV-T01-006 shapes out of boundary"
}
}

proc checkClkAnt {} {
# checklist TILE_CLOCK-T01-001 
# checkClkAnt
source /tool/aticad/1.0/src/zoo/TileFlowScripts/checklist/verify_clock_mesh_connection.tcl
}

proc checkSyspll {} {
# checklist TILE_CLOCK-T03-001
# checklist TILE_CLOCK-T03-002 
# checklist TILE_CLOCK-T03-003
# checkClkAnt
puts "# This is for systempll"
}

proc checkPushdownCkBuff {port_layer ckbuf_ref th} {
# checklist TILE_CLOCK-T03-004 
# checklist TILE_CLOCK-T03-009 
# checkPushdownCkBuff M16 CKBUFFMPCTS 4
# change_selection [get_cells -filter "ref_name =~ CKBUFFMPCTS*"]
# change_selection [get_cells -filter "ref_name =~ DCCKBD16*"]
foreach_in_collection port [get_ports *] {
    if {[get_attribute $port layer_name] == $port_layer} {
        puts "# check [get_object_name $port] [get_attribute $port layer_name]"
        set ckbuf [get_cells -of_objects [get_nets -of $port]]
        if {[regexp "$ckbuf_ref" [get_attribute $ckbuf ref_name]]} {
            set llxp [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 0]
            set llyp [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 1]
            set urxp [lindex [lindex [get_attribute [get_ports $port] bbox] 1 ] 0]
            set uryp [lindex [lindex [get_attribute [get_ports $port] bbox] 1 ] 1]

            set llx [lindex [lindex [get_attribute [get_cells $ckbuf] bbox] 0 ] 0]
            set lly [lindex [lindex [get_attribute [get_cells $ckbuf] bbox] 0 ] 1]
            puts "# [get_object_name $port] [get_attribute $ckbuf ref_name] [expr abs($llx - ($llxp + $urxp)/2) + abs($lly - ($llyp + $uryp)/2)]"
            if {[expr abs($llx - ($llxp + $urxp)/2) + abs($lly - ($llyp + $uryp)/2)] > $th} {
                puts "# ERROR: TILE_CLOCK-T03-009 distance from [get_object_name $ckbuf] to [get_object_name $port] exceed $th"
            }

        } else {
            puts "# ERROR: TILE_CLOCK-T03-004  pushdown port [get_object_name $port] doesn't has buffer $ckbuf_ref [get_attribute $ckbuf ref_name]"
        }
    }
}
}
