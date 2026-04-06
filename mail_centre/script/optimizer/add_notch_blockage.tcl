proc  add_notch_blockage {} {
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/uday_partial_blockage.tcl 
set range 50
set f [open add_notch_blockage.tcl w]
set all_point [get_attribute [current_design] boundary]
if {[llength $all_point] == 4 } {
    puts "# No need add notch blockage"
} else {
    foreach point $all_point {
        puts "$point"
        set llx [expr [lindex $point 0] - $range] 
        set lly [expr [lindex $point 1] - $range]
        set urx [expr [lindex $point 0] + $range]
        set ury [expr [lindex $point 1] + $range]
        puts $f "create_partial_blockage -location {{$llx $lly} {$urx $ury}} -bin_height 3.99032  -bin_width 2.61375  -density 50"
    } 
}
close $f
source  add_notch_blockage.tcl 
}
add_notch_blockage
