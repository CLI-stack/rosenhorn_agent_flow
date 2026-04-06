#!/usr/bin/tclsh
# Created on Fri May 25 13:30:23 2024
# @author: Zhang, Yinan; leon.zhang@amd.com
proc deduplicateList {inputList} {
    set uniqueList [list]

    foreach item $inputList {
        if {$item ni $uniqueList} {
            lappend uniqueList $item
        }
    }

    return $uniqueList
}


proc findLineRectangleIntersection {x1 y1 x2 y2 lineX1 lineY1 lineX2 lineY2 threshold} {
    set intersectionX ""
    set intersectionY ""
    set intersectionExists 0

    set rectLeft $x1
    set rectRight $x2
    set rectBottom $y1
    set rectTop $y2
    
    if {$lineX1 == $lineX2} {
        if {$lineX1 >= $rectLeft && $lineX1 <= $rectRight} {
            if {$lineY1 > $lineY2} {
                set lineYH $lineY1
                set lineYL $lineY2
            } else {
                set lineYH $lineY2
                set lineYL $lineY1
            }
            if {$lineYL <= [expr $rectBottom + $threshold] && $lineYH >= [expr $rectTop - $threshold]} {
                set intersectionPoint1 [list $lineX1 $rectBottom]
                set intersectionPoint2 [list $lineX1 $rectTop]
            } else {
                #puts "No Intersect Ver1"
                return
            }

        } else {
            #puts "No Intersect Ver2"
            return
        }

    } elseif {$lineY1 == $lineY2} {
        if {$lineY1 >= $rectBottom && $lineY1 <= $rectTop} {
            if {$lineX1 > $lineX2} {
                set lineXRight $lineX1
                set lineXLeft $lineX2
            } else {
                set lineXRight $lineX2
                set lineXLeft $lineX1
            }
            if {$lineXLeft <= [expr $rectLeft + $threshold] && $lineXRight >= [expr $rectRight - $threshold]} {
                set intersectionPoint1 [list $lineXLeft $lineY1]
                set intersectionPoint2 [list $lineXRight $lineY1]
            } else {
                #puts "No Intersect Hor1"
                return
            }
 

        } else {
            #puts "No Intersect Hor2"
            return
        }
    } else {
        #puts "No Intersect"
        return
    }
    return [list $intersectionPoint1 $intersectionPoint2]
}


proc get_macros_to_boundary_channel_area {macros channel_threshold} {
    set design_boundary [get_attribute -objects [current_design ] -name boundary]
    set design_boundary [string map {"\{" ""} $design_boundary]
    set design_boundary [string map {"\}" ""} $design_boundary]
    set design_boundary_list [split $design_boundary " "]
    
    
    set design_boundary_verline_list {}
    set design_boundary_horline_list {}
    set i 0
    while {$i < [expr [llength $design_boundary_list] - 2]} {
        set line [list [lindex $design_boundary_list $i] [lindex $design_boundary_list [expr $i + 1]] [lindex $design_boundary_list [expr $i + 2]] [lindex $design_boundary_list [expr $i + 3]]]
        if {[lindex $design_boundary_list $i] == [lindex $design_boundary_list [expr $i + 2]]} {
            lappend design_boundary_verline_list $line
        } elseif {[lindex $design_boundary_list [expr $i + 1]] == [lindex $design_boundary_list [expr $i + 3]]} {
            lappend design_boundary_horline_list $line        
        }
        if {[expr $i + 4] == [llength $design_boundary_list]} {
            set line [list [lindex $design_boundary_list 0] [lindex $design_boundary_list 1] [lindex $design_boundary_list [expr [llength $design_boundary_list] - 2]] [lindex $design_boundary_list [expr [llength $design_boundary_list] - 1]]]
            if {[lindex $design_boundary_list 0] == [lindex $design_boundary_list [expr [llength $design_boundary_list] - 2]]} {
                lappend design_boundary_verline_list $line
            } elseif {[lindex $design_boundary_list 1] == [lindex $design_boundary_list [expr [llength $design_boundary_list] - 1]]} {
                lappend design_boundary_horline_list $line        
            }
        }
    
        set i [expr $i + 2]
    }
    
    
    set macro_conges_dict [dict create]
    foreach_in_collection macro $macros {
        #set macro [get_cells uvdj/ujpeg_dec_wrapper/uvd_jpeg0/uvd_jpeg_fc/fc_mem/align_sram0/umemory/mem_0_0/SRAM/U_thdsd1pslvtll8192x22m8k4s128l_xid_0/SRAM]
        #puts [get_object_name $macro]
        set boundary [get_attribute -objects $macro -name boundary]
        set boundary [string map {"\{" ""} $boundary]
        set boundary [string map {"\}" ""} $boundary]
        set boundary_list [split $boundary " "]
        
        set enlarge_bbox_bl_x [expr [lindex $boundary_list 0] - $channel_threshold]
        set enlarge_bbox_bl_y [expr [lindex $boundary_list 1] - $channel_threshold]
        set enlarge_bbox_tr_x [expr [lindex $boundary_list 4] + $channel_threshold]
        set enlarge_bbox_tr_y [expr [lindex $boundary_list 5] + $channel_threshold]
        set enlarge_boundary [list $enlarge_bbox_bl_x $enlarge_bbox_bl_y $enlarge_bbox_bl_x $enlarge_bbox_tr_y $enlarge_bbox_tr_x $enlarge_bbox_tr_y $enlarge_bbox_tr_x $enlarge_bbox_bl_y]
        set enlarge_bbox [list $enlarge_bbox_bl_x $enlarge_bbox_bl_y $enlarge_bbox_tr_x $enlarge_bbox_tr_y]
       
        set conges_bboxs {}
        set VerintersectionPoints {}
        set HorintersectionPoints {}
    
        foreach design_boundary_verline $design_boundary_verline_list {
            set line_list [split $design_boundary_verline " "]
            set intersectionPoint [findLineRectangleIntersection $enlarge_bbox_bl_x $enlarge_bbox_bl_y $enlarge_bbox_tr_x $enlarge_bbox_tr_y [lindex $line_list 0] [lindex $line_list 1] [lindex $line_list 2] [lindex $line_list 3] $channel_threshold]
            if {$intersectionPoint != ""} {
                lappend VerintersectionPoints $intersectionPoint
            }
        }
    
        foreach VerintersectionPoint $VerintersectionPoints {
            set lineX [lindex [split [lindex $VerintersectionPoint 0] " "] 0]
            if {[expr abs([expr $lineX - [lindex $boundary_list 0]])] < [expr abs([expr $lineX - [lindex $boundary_list 4]])]} {
                set conges_bbox [list $lineX [lindex $boundary_list 1] [lindex $boundary_list 0] [lindex $boundary_list 5]]
            } else {
                set conges_bbox [list [lindex $boundary_list 4] [lindex $boundary_list 1] $lineX [lindex $boundary_list 5]]
            }
            lappend conges_bboxs $conges_bbox
        }
        
        foreach design_boundary_horline $design_boundary_horline_list {
            set line_list [split $design_boundary_horline " "]
            set intersectionPoint [findLineRectangleIntersection $enlarge_bbox_bl_x $enlarge_bbox_bl_y $enlarge_bbox_tr_x $enlarge_bbox_tr_y [lindex $line_list 0] [lindex $line_list 1] [lindex $line_list 2] [lindex $line_list 3]  $channel_threshold]
            if {$intersectionPoint != ""} {
                lappend HorintersectionPoints $intersectionPoint
            }
        }
        
        foreach horintersectionPoint $HorintersectionPoints {
            set lineY [lindex [split [lindex $horintersectionPoint 0] " "] 1]
            if {[expr abs([expr $lineY - [lindex $boundary_list 1]])] < [expr abs([expr $lineY - [lindex $boundary_list 5]])]} {
                set conges_bbox [list [lindex $boundary_list 0] $lineY [lindex $boundary_list 4] [lindex $boundary_list 1]]
            } else {
                set conges_bbox [list [lindex $boundary_list 0] [lindex $boundary_list 5] [lindex $boundary_list 4] $lineY]
            }
            lappend conges_bboxs $conges_bbox
        }
    
        if {$conges_bboxs != ""} {
            dict set macro_conges_dict $macro $conges_bboxs
        }
    
    }
    return $macro_conges_dict
}



proc get_macros_to_macros_channel_area {macros channel_threshold} {
    set conges_bboxs {}
    foreach_in_collection macro $macros {
        #set macro [get_cells uvdj/ujpeg_dec_wrapper/uvd_jpeg0/uvd_jpeg_fc/fc_mem/align_sram0/umemory/mem_0_0/SRAM/U_thdsd1pslvtll8192x22m8k4s128l_xid_0/SRAM]
        #puts [get_object_name $macro]
        set boundary [get_attribute -objects $macro -name boundary]
        set boundary [string map {"\{" ""} $boundary]
        set boundary [string map {"\}" ""} $boundary]
        set boundary_list [split $boundary " "]
        set bbox [list [lindex $boundary_list 0] [lindex $boundary_list 1] [lindex $boundary_list 4] [lindex $boundary_list 5]]
        
        set enlarge_bbox_bl_x [expr [lindex $boundary_list 0] - $channel_threshold]
        set enlarge_bbox_bl_y [expr [lindex $boundary_list 1] - $channel_threshold]
        set enlarge_bbox_tr_x [expr [lindex $boundary_list 4] + $channel_threshold]
        set enlarge_bbox_tr_y [expr [lindex $boundary_list 5] + $channel_threshold]
        set enlarge_boundary [list $enlarge_bbox_bl_x $enlarge_bbox_bl_y $enlarge_bbox_bl_x $enlarge_bbox_tr_y $enlarge_bbox_tr_x $enlarge_bbox_tr_y $enlarge_bbox_tr_x $enlarge_bbox_bl_y]
        set enlarge_bbox [list $enlarge_bbox_bl_x $enlarge_bbox_bl_y $enlarge_bbox_tr_x $enlarge_bbox_tr_y]
        set enlarge_bbox_str [string cat  "\{\{" [lindex $enlarge_bbox 0] " " [lindex $enlarge_bbox 1] "\} \{" [lindex $enlarge_bbox 2] " " [lindex $enlarge_bbox 3] "\}\}"]
        set touch_enlarge_bbox_macros [get_cells -intersect $enlarge_bbox_str -filter "design_type == macro" -hier -quiet]

        foreach_in_collection touch_macro $touch_enlarge_bbox_macros {
            #puts [get_object_name $touch_macro]
            #set touch_macro [get_cells uvdj/ujpeg_dec_wrapper/uvd_jpeg0/jpg_dec_outbuf/utc__6/umemory/mem_0_0/RF/U_trfsd2plvtll120x104m1k2bn_xid_0/RF]
            set touch_macro_boundary [get_attribute -objects $touch_macro -name boundary]
            set touch_macro_boundary [string map {"\{" ""} $touch_macro_boundary]
            set touch_macro_boundary [string map {"\}" ""} $touch_macro_boundary]
            set touch_macro_boundary_list [split $touch_macro_boundary " "]
            set touch_bbox [list [lindex $touch_macro_boundary_list 0] [lindex $touch_macro_boundary_list 1] [lindex $touch_macro_boundary_list 4] [lindex $touch_macro_boundary_list 5]]

            set x_coors [lsort -increasing -real [list [lindex $bbox 0] [lindex $bbox 2] [lindex $touch_bbox 0] [lindex $touch_bbox 2]]]
            set y_coors [lsort -increasing -real [list [lindex $bbox 1] [lindex $bbox 3] [lindex $touch_bbox 1] [lindex $touch_bbox 3]]]

            if {[lindex $x_coors 1] !=  [lindex $x_coors 2] && [lindex $y_coors 1] != [lindex $y_coors 2]} {
                set conges_bbox [list [lindex $x_coors 1] [lindex $y_coors 1] [lindex $x_coors 2] [lindex $y_coors 2]]
                lappend conges_bboxs $conges_bbox
            }
        }
    }

    set conges_bboxs_sort [lsort -unique $conges_bboxs] 
    return $conges_bboxs_sort
}



remove_placement_blockages check_channel_congestion_*
set macros [get_cells -filter "design_type == macro" -hier]
set channel_threshold 10


foreach area [get_macros_to_macros_channel_area $macros $channel_threshold] {
    set area [split $area " "]
    #set area_bbox [string cat  "\{\{" [lindex $area 0] " " [lindex $area 1] "\} \{" [lindex $area 2] " " [lindex $area 3] "\}\}"]
    
    set area_bbox [string cat  "\{\{" [expr [lindex $area 0] -$channel_threshold] " " [expr [lindex $area 1] -$channel_threshold] "\} \{" [expr [lindex $area 2] +$channel_threshold] " " [expr [lindex $area 3] +$channel_threshold] "\}\}"]
    create_placement_blockage -boundary $area_bbox -name check_channel_congestion_$area_bbox
    #create_placement_blockage -type partial -blocked_percentage 50 -boundary $area_bbox -name check_channel_congestion_$area_bbox

}


set macro_to_boundry_conges_dict [get_macros_to_boundary_channel_area $macros $channel_threshold]


foreach macro [dict keys $macro_to_boundry_conges_dict] {
    set value [dict get $macro_to_boundry_conges_dict $macro]
    set macro_name [get_object_name $macro]    
    foreach area $value {
        set area [split $area " "]
        #set area_bbox [string cat  "\{\{" [lindex $area 0] " " [lindex $area 1] "\} \{" [lindex $area 2] " " [lindex $area 3] "\}\}"]
        set area_bbox [string cat  "\{\{" [expr [lindex $area 0] -$channel_threshold] " " [expr [lindex $area 1] -$channel_threshold] "\} \{" [expr [lindex $area 2] +$channel_threshold] " " [expr [lindex $area 3] +$channel_threshold] "\}\}"]

        create_placement_blockage -boundary $area_bbox -name check_channel_congestion_$area_bbox
        #create_placement_blockage -type partial -blocked_percentage 50 -boundary $area_bbox -name check_channel_congestion_$area_bbox

    }
}

set_host_options -max_cores 32
set all_unplaced_cells [get_cells -filter "physical_status == unplaced" -hier]



magnet_placement [get_ports *] -enable_runtime
magnet_placement [get_cells -filter "design_type == macro" -hier] -enable_runtime
route_global -floorplan true -congestion_map_only true


foreach macro [dict keys $macro_to_boundry_conges_dict] {
    set macro_name [get_object_name $macro]
    set value [dict get $macro_to_boundry_conges_dict $macro]
    #puts "Macro: $macro_name, areas: $value"
    foreach area $value {
        set area [split $area " "]
        set area_bbox [string cat  "\{\{" [lindex $area 0] " " [lindex $area 1] "\} \{" [lindex $area 2] " " [lindex $area 3] "\}\}"]
        report_congestion -boundary $area_bbox > temp
        if { [catch {open "temp" r} tempId] } {
            puts "Error opening file temp: $tempId"
            exit 1
        }
        while {[gets $tempId line] >= 0} {
            if { [regexp "Both Dirs" $line] } {
                set line_list [split $line " "]
                set results {}
                foreach ele $line_list {
                    if {[scan $ele "%d" num] == 1} {
                        lappend results $ele
                    }
                }
                if {[lindex $ele 0] > 0} {
                    puts "ERROR channel $area_bbox may have congestion issue" 
                }
            }
        }
    }
}

set macros_to_macros_channel_areas [get_macros_to_macros_channel_area $macros $channel_threshold]
foreach area $macros_to_macros_channel_areas {
    set area [split $area " "]
    set area_bbox [string cat  "\{\{" [lindex $area 0] " " [lindex $area 1] "\} \{" [lindex $area 2] " " [lindex $area 3] "\}\}"]
    report_congestion -boundary $area_bbox > temp
    if { [catch {open "temp" r} tempId] } {
        puts "Error opening file temp: $tempId"
        exit 1
    }
    while {[gets $tempId line] >= 0} {
        if { [regexp "Both Dirs" $line] } {
            set line_list [split $line " "]
            set results {}
            foreach ele $line_list {
                if {[scan $ele "%d" num] == 1} {
                    lappend results $ele
                }
            }
            if {[lindex $ele 0] > 0} {
                puts "ERROR channel $area_bbox may have congestion issue" 
            }
        }
    }
}

set_attribute -objects $all_unplaced_cells -name physical_status -value unplaced -quiet
remove_placement_blockages check_channel_congestion_*
