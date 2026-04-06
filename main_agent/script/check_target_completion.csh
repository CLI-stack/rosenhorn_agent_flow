foreach run_dir (`cat all_run`)
    cd $run_dir
    set n = 0
    set rd_tile = `grep "TILES_TO_RUN" tile.params | grep -v "#" | awk '{print $3}'`
    foreach log (`ls logs/*.log.gz`)
        set n_output = `zgrep "Required Outputs:" $log | wc -w`
        set n_missing = `zgrep " Output dependency file" $log | grep -v rde.txt | grep -v "iobuf_max_dist_viol.rpt" | wc -w`
        if ($n_missing > 0 || $n_output == 0) then
            continue
        endif
        set n = `expr $n + 1` 
    end
    echo "$run_dir $n"
end
