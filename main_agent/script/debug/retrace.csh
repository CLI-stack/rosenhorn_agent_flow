set curr_dir = `pwd`
echo "# Rerun $target at $curr_dir"
#TileBuilderTerm -x "serascmd -find_jobs "status==RUNNING dir=~$curr_dir" --action stop;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action unskip;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action reset;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action rerun;"
set monitorAction = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "monitorAction,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_monitorAction = `echo $monitorAction | wc -w`
if ($n_monitorAction == 0) then
    set monitorAction = 1
endif
if ($monitorAction == 1) then
    touch TileBuilderOverwriteCommand_${target}_retrace.started
    rm TileBuilderOverwriteCommand_${target}_retrace.started
    TileBuilderTerm -x "TileBuilderOverwriteCommand cmds/$target.cmd ;touch TileBuilderOverwriteCommand_${target}_retrace.started"
    source $source_dir/script/wait_file_finish.csh TileBuilderOverwriteCommand_${target}_retrace.started

    TileBuilderTerm -x "serascmd -find_jobs "name=~$target dir=~$curr_dir" --action stop;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action unskip;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action reset;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action rerun;"
endif
