source /tool/aticad/1.0/src/zoo/CenMeth/bin/tcl/get_path_stats.tcl
proc check_start_slack_lol {clk start_point} {
redirect /dev/null {set path_slack [get_attribute [get_timing_paths -from $start_point -group $clk] slack]}
redirect /dev/null {set start_slack [get_attribute [get_timing_paths -to $start_point -group $clk] slack]}
set start_lol [expr round([sizeof_collection [get_attribute [get_timing_paths -from $start_point -group $clk] points]] / 2)]
set margin [expr $path_slack + $start_slack]
#puts "# #  Slack: $start_point $path_slack $start_slack $margin $start_lol"
return "check_start_slack_lol: $start_point $path_slack $start_slack $margin"
}

proc check_start_neighbor_slack {clk start_point} {
redirect /dev/null {set path_slack [get_attribute [get_timing_paths -from $start_point -group $clk] slack]}
redirect /dev/null {set start_slack [get_attribute [get_timing_paths -to $start_point -group $clk] slack]}
set margin [expr $path_slack + $start_slack]
#puts "# #  Slack: $start_point $path_slack $start_slack $margin"
return "$start_point $path_slack $start_slack $margin"
}


proc check_end_neighbor_slack {clk end_point} {
redirect /dev/null {set path_slack [get_attribute [get_timing_paths -to $end_point -group $clk] slack]}
redirect /dev/null {set end_slack [get_attribute [get_timing_paths -from $end_point -group $clk] slack]}
set margin [expr $path_slack + $end_slack]
#puts "# #  Slack: $end_point $path_slack $end_slack $margin"
return "$end_point $path_slack $end_slack $margin"
}

proc check_neighbor_slack {clk start_point end_point} {
redirect /dev/null {set path_slack [get_attribute [get_timing_paths -from $start_point -to $end_point -group $clk] slack]}
redirect /dev/null {set start_slack [get_attribute [get_timing_paths -to $start_point -group $clk] slack]}
redirect /dev/null {set end_slack [get_attribute [get_timing_paths -from $end_point -group $clk] slack]}
if {$path_slack == ""} {set path_slack 0}
if {$start_slack == ""} {set start_slack 0}
if {$end_slack == ""} {set end_slack 0}
set margin [expr $path_slack + $start_slack + $end_slack]
#puts "# #  Slack: $start_point $end_point $path_slack $start_slack $end_slack $margin"
return "$path_slack $start_slack $end_slack $margin"
}

proc check_neighbor_lol {clk start_point end_point} {
set start_lol [expr round([sizeof_collection [get_attribute [get_timing_paths -to $start_point -group $clk] points]] / 2)]
set end_lol [expr round([sizeof_collection [get_attribute [get_timing_paths -from $end_point -group $clk] points]] / 2)]
#puts "# #  LOL: $start_point $end_point $start_lol $end_lol"
return "$start_lol $end_lol"
}


proc get_path_feature {clk start_point end_point} {
get_path_stats [get_timing_paths -from $start_point -to $end_point -max_paths 10000 -group $clk -slack_lesser_than 50] -exact_path_mode  -longlist

}

proc show_path {clk points} {
set path_list ""
set f [open show_path.tcl w]
puts $f "set pins {"
for {set i 0} {$i < [expr [llength $points] - 1]} {incr i} {
    set start_point [lindex $points $i]
    set end_point [lindex $points [expr $i + 1]]

    # Get the timing path from start_point to end_point
    set timing_path [get_timing_path -from $start_point -to $end_point -group $clk]

    # Print the pins in the timing path
    puts "Timing path from $start_point to $end_point:"
    foreach_in_collection point [get_attribute $timing_path points] {
        puts $f "[get_object_name [get_attribute $point object]]"
    }
}
puts $f "}"
puts $f "change_selection \[get_pins \$pins\]"
close $f
}

proc show_fanint_lol {pin} {
foreach_in_collection reg [all_fanin -to $pin -startpoints_only] {
    redirect /dev/null {set lol [expr round([sizeof_collection [get_attribute [get_timing_paths -from $reg -to $pin] points]] / 2)]}
    puts "[get_object_name $reg] $lol"
}

}

proc get_cell_area {cells} {
set area 0
foreach_in_collection inst [get_cells $cells] {
    set area [expr $area + [get_attribute $inst area]]
}
puts "$cells $area"
return $area
}
