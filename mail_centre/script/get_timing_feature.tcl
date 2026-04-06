source /tool/aticad/1.0/src/zoo/CenMeth/bin/tcl/get_path_stats.tcl
redirect get_timing_feature.txt {get_path_stats [get_timing_paths -max_paths 10000 -slack_lesser_than 0.000 -group UMC_UCLK] -exact_path_mode}
sh grep "Path_ID      Path_Group" get_timing_feature.txt > rpts/get_timing_feature.txt
sh sed -i "/Path ID:  0/,/Path_ID      Path_Group/d" get_timing_feature.txt
sh cat get_timing_feature.txt >> rpts/get_timing_feature.txt
exit

