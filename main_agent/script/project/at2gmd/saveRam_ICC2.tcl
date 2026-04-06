puts "method1: use proc placeram_icc2 halo outfile"

set tile_name [get_attribute  [get_designs] name ]
proc saveRam_ICC2 { outfile } {

    set f [open $outfile "w"]
    set all_macros [get_cells -hierarchical -quiet -filter "is_hard_macro == true || is_io == true"]
    set mem_macros [get_cells -hierarchical -quiet -filter "ref_name=~hd*x*m* || ref_name=~rf*x*m* || ref_name=~ckbw_npr* || ref_name=~ctrfps*|| ref_name=~thds* || ref_name=~trfps* && design_type==macro"]
    set DTCD_cells [get_cells -hierarchical -quiet -filter "ref_name =~ *DTCD*"]
    set temp_macros [remove_from_collection $all_macros $DTCD_cells]
    set o_macros [remove_from_collection $temp_macros $mem_macros]

    puts "write mem macros ..."
    if {[sizeof_collection $mem_macros] >=1} {
        foreach_in_collection  mem_macro $mem_macros {
        set ram_inst [get_object_name $mem_macro]
        puts "write $ram_inst ..."
        set ram_boundary [get_attribute [get_cells $mem_macro] boundary]
        set ram_x [lindex [lindex $ram_boundary 0] 0]
        set ram_y [lindex [lindex $ram_boundary 0] 1]
        set ram_orient [get_attribute [get_cells $mem_macro] orientation]
        puts $f "set_cell_location $ram_inst -coordinates \[list $ram_x $ram_y\] -orientation $ram_orient -fixed -ignore_fixed"
        puts $f "create_keepout_margin -type hard -outer {0.048 0.0845 0.048 0.0845} \[get_cell $ram_inst\]"
    }
    }
    
    if {[sizeof_collection $DTCD_cells] >=1} {
        puts "write DTCD cell ..."
        foreach_in_collection DTCD_cell $DTCD_cells {
            set DTCD_inst [get_object_name $DTCD_cell]
            puts "write $DTCD_inst ..."
            set ram_boundary [get_attribute [get_cells $DTCD_cell] boundary]
            set ram_x [lindex [lindex $ram_boundary 0] 0]
            set ram_y [lindex [lindex $ram_boundary 0] 1]
            set ram_orient [get_attribute [get_cells $DTCD_cell] orientation]
            puts $f "set_cell_location $DTCD_inst -coordinates \[list $ram_x $ram_y\] -orientation $ram_orient -fixed -ignore_fixed"
            puts $f "create_keepout_margin -type hard -outer {2.04 2.22 2.04 2.34} \[get_cell $DTCD_inst\]"
        }
    }

    puts "write other macros ..."
    if {[sizeof_collection $o_macros] >=1} {
    foreach_in_collection  o_macro $o_macros {
        set ram_inst [get_object_name $o_macro]
        puts "write $ram_inst ..."
        set ram_boundary [get_attribute [get_cells $o_macro] boundary]
        set ram_x [lindex [lindex $ram_boundary 0] 0]
        set ram_y [lindex [lindex $ram_boundary 0] 1]
        set ram_orient [get_attribute [get_cells $o_macro] orientation]
        puts $f "set_cell_location $ram_inst -coordinates \[list $ram_x $ram_y\] -orientation $ram_orient -fixed -ignore_fixed"
        puts $f "create_keepout_margin -type hard -outer {0.9 0.9 0.9 0.9} \[get_cell $ram_inst\]"
    }
    }
    close $f
}

if { [file exists ${tile_name}.tcl] } {
file delete ${tile_name}.tcl
}
saveRam_ICC2 ${tile_name}.tcl


echo "###################################################################################"
echo "All macros saved successfully"
echo "You could cp ${tile_name}.tcl to ../../../tune/FxFpPlaceMacros/FxFpPlaceMacros.placerams.tcl"
echo "Command as below:"
echo "sh cp ${tile_name}.tcl ../../../tune/FxFpPlaceMacros/FxFpPlaceMacros.placerams.tcl -f"
echo "###################################################################################"
