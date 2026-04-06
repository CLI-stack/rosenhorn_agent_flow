proc check_timing_margin {clk} {
if {[sizeof_collection [get_clock $clk]] == 0} {
    puts "# Error: $clk not exist"
    return 0
}
set n_path 2000
source /tools/aticad/1.0/src/zoo/PD_agent/tile/proc_pt.tcl
puts "# generate timing feature"

# redirect get_timing_feature.$clk.txt {get_path_stats [get_timing_paths -start_end_pair -max_paths 10000 -slack_lesser_than 0.000 -from $clk -to $clk -group $clk] -exact_path_mode}
redirect get_timing_feature.$clk.txt {get_path_stats [get_timing_paths -max_paths 10000 -slack_lesser_than 0.000 -group $clk] -exact_path_mode}

#sh grep "Path_ID      Path_Group" get_timing_feature.$clk.txt > rpts/get_timing_feature.$clk.txt
#sh sed -i "/Path ID:  0/,/Path_ID      Path_Group/d" get_timing_feature.$clk.txt
#sh cat get_timing_feature.$clk.txt >> rpts/get_timing_feature.$clk.txt
# wait for redirect finished
set f [open get_timing_feature.$clk.txt r]
set o [open rpts/check_timing_margin.$clk.rpt w]
puts "# generate timing margin info..."
set n 0
puts $o "Path_ID Path_Group -from_thr Start -to End  Slack Weighted_Slack Cycles Path_Delay Net_Delay Cell_Delay Buf/Inv_Delay  Wire%  Cell% Net+Buf% Comb_Levels Clock_Skew Clock_Start_Latency Clock_Start_Levels Clock_End_Latency Clock_End_Levels Start_Cell Start_CLKslew   Clk2Q Start_Tran Start_Qslew Start_Qcap End_Tran End_Dslew End_CLKslew   Setup End_Cell Uncertainty Path_Margin   CRPR Seq_Overhead  POCV_Total Sigma Slack_StdDev Data_StdDev Clk_StdDev Scenario  Tcycle  Slack_Tcycle% Weighted_Slack_Tcycle% Buf_Inv_Tcycle% Net_Delay_Tcycle% Cell_Delay_Tcycle% Skew_Tcycle%  Clk2Q_Tcycle% Setup_Tcycle% Uncertainty_Tcycle% Path_Margin_Tcycle%   CRPR_Tcycle% POCV_Total_Tcycle% Seq_Overhead_Tcycle% current_slack pre_slack post_slack margin post_post_slack pre_lol post_lol max1_trans max2_trans early_skew early_skew_post early_skew_post_post max_slack"
while {[gets $f line] >= 0} {
    if {$n == $n_path} {break}
    if {[regexp {Path_ID_\S+\s+\S+\s+-thr\s+(\S+)\s+-to\s+(\S+)} $line match startpoint endpoint]} {
        puts "+++++++++ $startpoint $endpoint"
        set s [get_object_name [get_cells -of_objects $startpoint]]
        set e [get_object_name [get_cells -of_objects $endpoint]]
        set post_post_slack 0
        if {$n < 500} {
            puts "=== $clk $e "
            redirect /dev/null {set es [get_attribute [get_timing_path -group $clk -from $e] startpoint]}
            if {$es == ""} {
                set post_post_slack 0
            } else {
                redirect /dev/null {set ee [get_attribute [get_timing_path -group $clk -from $es] endpoint]}
            }
            if {$es == ""} {
                set post_post_slack 0
            } else {
                puts "$es $ee"
                redirect /dev/null {set post_post_slack [get_attribute [get_timing_path -from [get_cells -of_objects $ee] -group $clk] slack]}
            }
        } else {
            set post_post_slack 0
        }
        set margin_info [check_neighbor_slack $clk $s $e]
        # $margin_info: $path_slack $start_slack $end_slack $margin
        set lol_info [check_neighbor_lol $clk $s $e]
        set trans_list ""
        puts "############ get_timing_paths -from $s -to $e"
        foreach_in_collection point [get_attribute [get_timing_paths -from $s -to $e] points] {
        #puts "[get_object_name [get_attribute $point object]] [get_attribute $point transition]"
            set trans_list "$trans_list [get_attribute $point transition]"
        }
        set trans_list [lsort -real -decreasing $trans_list]
        if {[llength $trans_list] > 1} {
            set max1_tran [lindex $trans_list 0]
            set max2_tran [lindex $trans_list 1]
        }
        if {[llength $trans_list] < 2} {
            set max1_tran [lindex $trans_list 0]
            set max2_tran 0
        }
        set current_slack [lindex $margin_info 0]
        set pre_slack [lindex $margin_info 1]
        set post_slack [lindex $margin_info 2]
        if {$pre_slack > 50} {
            set early_skew [expr $current_slack + 25]
        } else {
            set early_skew $current_slack
        }
        if {$post_slack > 0} {
            set early_skew_post [expr $early_skew + $post_slack]
        } else {
            set early_skew_post $early_skew
        }
        if {$post_post_slack > 0} {
            set early_skew_post_post [expr $early_skew_post + $post_post_slack]
        } else {
            set early_skew_post_post $early_skew_post
        }
        set max_slack [lindex [lsort -decreasing -real "$early_skew $early_skew_post $early_skew_post"] 0]
        puts $o "$line $margin_info $post_post_slack $lol_info $max1_tran $max2_tran $early_skew $early_skew_post $early_skew_post_post $max_slack"
        incr n
    }
}
close $f
close $o

}
