proc show_timing_lol_wall {clk} {
if {[sizeof_collection [get_clock $clk]] == 0} {
    puts "# Error: $clk not exist"
    return 0
}
set n_path 1000
source /tools/aticad/1.0/src/zoo/PD_agent/tile/proc_pt.tcl
set o [open rpts/show_timing_lol_wall.$clk.rpt w]
puts "startpoint endpoint lol max_tran slack pre_margin post_margin pre_lol post_lol"
foreach_in_collection path [get_timing_paths -max_paths 100 -slack_lesser_than 0.000 -from $clk -to $clk -group $clk] {
    set startpoint [get_object_name [get_attribute $path startpoint]]
    set endpoint [get_object_name [get_attribute $path endpoint]]
    set trans_list ""
    foreach_in_collection point [get_attribute [get_timing_paths -from $startpoint -to $endpoint] points] {
        #puts "[get_object_name [get_attribute $point object]] [get_attribute $point transition]"
        set trans_list "$trans_list [get_attribute $point transition]"
    }
    set trans_list [lsort -real -decreasing $trans_list]
    set max_tran [lindex $trans_list 0]
    set lol [expr round([sizeof_collection [get_attribute $path points]] / 2)]
    set slack [get_attribute $path slack]
    set margin_info [check_neighbor_slack $clk $startpoint $endpoint]
    set lol_info [check_neighbor_lol $clk $startpoint $endpoint]

    puts $o "$startpoint $endpoint $lol $max_tran $slack $margin_info $lol_info"
}
close $o
}
