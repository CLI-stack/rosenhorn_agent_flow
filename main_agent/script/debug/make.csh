set dir = `pwd`
set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
echo "# Rerun $target at $curr_dir"
 if (-e logs/TileBuilderMake.log.gz) then
    rm logs/TileBuilderMake.log*
endif

TileBuilderTerm -x "TileBuilderMake"
echo "# Wait for TileBuilderMake finished."
set n_wait = 0
while(1)
    sleep 1
    if (-e logs/TileBuilderMake.log.gz) then
        break
    endif
    if ($n_wait > 3600) then
        break
    endif
    set n_wait = `expr $n_wait + 1`
end
TileBuilderTerm -x "serascmd -find_jobs "status==RUNNING dir=~$dir" --action stop;serascmd -find_jobs "name=~$target dir=~$dir" --action rerun"

