#####
#Created on Fri May 25 2023
#@author: Xuanhao Zhang, xuazhang@amd.com
#####

set curr_dir = `pwd`
set target = "FxFpPlaceMacros"
    
set incr_param = `zegrep "^MLPLACE_FIXED_MACRO_LIST" logs/$target.log.gz`
echo "\n### Add DTCD MOVEMENT PARAMS TO RETRACE ###\n"
echo $incr_param >> $curr_dir/override.params
echo "MLPLACE_INCREMENTAL = 1" >> $curr_dir/override.params
echo "# Rerun $target at $curr_dir"
TileBuilderTerm -x "TileBuilderGenParams;TileBuilderOverwriteCommand $target;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action stop;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action unskip;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action reset;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action rerun;"
