#####
#Created on Fri May 25 2023
#@author: Xuanhao Zhang, xuazhang@amd.com
#####

global P

if {[info exists P(TUNE_DTCD_MOVEMENT_SWITCH_ON)] && $P(TUNE_DTCD_MOVEMENT_SWITCH_ON) == 1} {

    set sram_filter $P(TUNE_DTCD_MOVEMENT_SRAM_REGEXP)
    set tmac_filter $P(TUNE_DTCD_MOVEMENT_TMAC_REGEXP)
    set dtcd_filter $P(TUNE_DTCD_MOVEMENT_DTCD_REGEXP)
    set dtcd_clearance $P(TUNE_DTCD_MOVEMENT_CLEARENCE)
    
    set fh_out [open "rpts/$TARGET_NAME/DTCD_Placement.rpt" w]
    set tc_out [open "rpts/DTCD_Blockage.tcl" w]
    
    set all_mac [get_object_name [get_cells -hier -filter "is_hard_macro==true"]]
    set dtcd_cells [get_object_name [get_cells -filter "ref_name=~$dtcd_filter"]]
    set fix_mac []
    set need_fix_flag 0
    
    if {[llength $dtcd_cells] > 0} {
        foreach dtcd_cell $dtcd_cells {
        
            set distance_list {}
        
            set dtcd_llx [get_attr [get_cells $dtcd_cell] bbox_llx]
            set dtcd_lly [get_attr [get_cells $dtcd_cell] bbox_lly]
            set dtcd_urx [get_attr [get_cells $dtcd_cell] bbox_urx]
            set dtcd_ury [get_attr [get_cells $dtcd_cell] bbox_ury]
            
            set dtcd_origin [list [expr ($dtcd_llx+$dtcd_urx)/2] [expr ($dtcd_lly+$dtcd_ury)/2]]
            set dtcd_size_x [::tcl::mathfunc::abs [expr $dtcd_llx - $dtcd_urx]]
            set dtcd_size_y [::tcl::mathfunc::abs [expr $dtcd_lly - $dtcd_ury]]
        
            foreach macro $all_mac {
                
                if {$macro in $dtcd_cells} {
                    lappend fix_mac $macro
                    continue
                }
        
                set macro_llx [get_attr [get_cells $macro] bbox_llx]
                set macro_lly [get_attr [get_cells $macro] bbox_lly]
                set macro_urx [get_attr [get_cells $macro] bbox_urx]
                set macro_ury [get_attr [get_cells $macro] bbox_ury]
                
                set macro_origin [list [expr ($macro_llx+$macro_urx)/2] [expr ($macro_lly+$macro_ury)/2]]
                set macro_size_x [::tcl::mathfunc::abs [expr $macro_llx - $macro_urx]]
                set macro_size_y [::tcl::mathfunc::abs [expr $macro_lly - $macro_ury]]
                
                if {[::tcl::mathfunc::abs [expr [lindex $dtcd_origin 0] - [lindex $macro_origin 0]]] < [expr ($dtcd_size_x + $macro_size_x) / 2]} {
                    set manhattan_distance [expr [::tcl::mathfunc::abs [expr [lindex $dtcd_origin 1] - [lindex $macro_origin 1]]] - ($dtcd_size_y + $macro_size_y)/2] 
                } elseif {[::tcl::mathfunc::abs [expr [lindex $dtcd_origin 1] - [lindex $macro_origin 1]]] < [expr ($dtcd_size_y + $macro_size_y) / 2]} {
                    set manhattan_distance [expr [::tcl::mathfunc::abs [expr [lindex $dtcd_origin 0] - [lindex $macro_origin 0]]] - ($dtcd_size_x + $macro_size_x)/2]
                } else {
                    set manhattan_distance [expr [::tcl::mathfunc::abs [expr [lindex $dtcd_origin 0] - [lindex $macro_origin 0]]] + [::tcl::mathfunc::abs [expr [lindex $dtcd_origin 1] - [lindex $macro_origin 1]]] - ($dtcd_size_x + $dtcd_size_y + $macro_size_x + $macro_size_y)/2]
                }
                
                if {$manhattan_distance < $dtcd_clearance} {
                    if {[regexp $tmac_filter [get_attr [get_cell $macro] ref_name]]} {
                        puts $fh_out "ERROR TMAC: $macro distance is $manhattan_distance to $dtcd_cell, DTCD need to report to FCFP."
                        puts "Error: TMAC $macro distance is $manhattan_distance to $dtcd_cell, DTCD need to report to FCFP."
                    } elseif {[regexp $sram_filter [get_attr [get_cell $macro] ref_name]]} {
                        puts $fh_out "ERROR SRAM: $macro distance is $manhattan_distance to $dtcd_cell, DTCD need to fix."
                        puts $tc_out "create_placement_blockage -type hard_macro -name PB_DTCD_$dtcd_cell -boundary {{[expr $dtcd_llx-$dtcd_clearance] [expr $dtcd_lly-$dtcd_clearance]} {[expr $dtcd_urx+$dtcd_clearance] [expr $dtcd_ury+$dtcd_clearance]}}"
                        puts "Error: SRAM $macro distance is $manhattan_distance to $dtcd_cell, DTCD need to fix."
                        set need_fix_flag 1
                    } else {
                        puts $fh_out "WARN OTHER MACRO: $macro distance is $manhattan_distance to $dtcd_cell, DTCD need to fix."
                        puts $tc_out "create_placement_blockage -type hard_macro -name PB_DTCD_$dtcd_cell -boundary {{[expr $dtcd_llx-$dtcd_clearance] [expr $dtcd_lly-$dtcd_clearance]} {[expr $dtcd_urx+$dtcd_clearance] [expr $dtcd_ury+$dtcd_clearance]}}"
                        puts "Error: OTHER MACRO $macro distance is $manhattan_distance to $dtcd_cell, DTCD need to fix."
                        set need_fix_flag 1
                    }
                } else {
                    puts $fh_out "Macro: $macro distance is $manhattan_distance, safe."
                    lappend fix_mac $macro
                }
            }
        }
    } else {
        puts $fh_out "No DTCD cells found in this tile."
    }
    if {$need_fix_flag} {
        source -e -v $P(ALLTILES_DIR)/scripts/tile_flow/saveRam_ICC2.tcl
        set fix_param "MLPLACE_FIXED_MACRO_LIST = [join $fix_mac]"
    }
    if {[sizeof_collection [get_placement_blockages PB_DTCD_*]] >= 1} {
        remove_placement_blockages PB_DTCD_*
    }
    close $fh_out
    close $tc_out
}
