set curr_dir = `pwd`
echo "# Rerun $target at $curr_dir"
## switch FC
set n_fx = `echo $target | grep Fx | wc -w`
if ($n_fx > 0) then
    if (-e $target.log) then
        set eda_version = `grep "setenv FC_MODULE" $target.log | grep -v "#" | awk '{print $3}'`
        set date = `date` 
        echo "$date $target $eda_version" >> crash.list
        if (-e $source_dir/data/jira/edatool.list) then
            foreach new_version (`cat $source_dir/data/jira/edatool.list | grep fusioncompiler`)
                set n_used = `grep $new_version crash.list | wc -w`
                if ($n_used == 0) then
                    echo "FC_MODULE = $new_version" >> override.controls
                    break
                endif
            end
        endif 
    endif
    if (-e $target.log.gz) then
        set eda_version = `grep "setenv FC_MODULE" $target.log | grep -v "#" | awk '{print $3}'`
        set date = `date`
        echo "$date $target $eda_version" >> crash.list
        if (-e $source_dir/data/jira/edatool.list) then
            foreach new_version (`cat $source_dir/data/jira/edatool.list | grep fusioncompiler`)
                set n_used = `grep $new_version crash.list | wc -w`
                if ($n_used == 0) then
                    echo "FC_MODULE = $new_version" >> override.controls
                    break
                endif
            end
        endif
    endif

endif
## switch ICV
if ($target == "FxGenReRouteFill" || $target == "FxGenRouteFill") then
    if (-e $target.log) then
        set eda_version = `grep "setenv ICV_MODULE" $target.log | grep -v "#" | awk '{print $3}'`
        set date = `date`
        echo "$date $target $eda_version" >> crash.list
        if (-e $source_dir/data/jira/edatool.list) then
            foreach new_version (`cat $source_dir/data/jira/edatool.list | grep icvalidator`)
                set n_used = `grep $new_version crash.list | wc -w`
                if ($n_used == 0) then
                    echo "ICV_MODULE = $new_version" >> override.controls
                    break
                endif
            end
        endif
    endif
    if (-e $target.log.gz) then
        set eda_version = `grep "setenv ICV_MODULE" $target.log | grep -v "#" | awk '{print $3}'`
        set date = `date`
        echo "$date $target $eda_version" >> crash.list
        if (-e $source_dir/data/jira/edatool.list) then
            foreach new_version (`cat $source_dir/data/jira/edatool.list | grep icvalidator`)
                set n_used = `grep $new_version crash.list | wc -w`
                if ($n_used == 0) then
                    echo "ICV_MODULE = $new_version" >> override.controls
                    break
                endif
            end
        endif
    endif

endif

#TileBuilderTerm -x "serascmd -find_jobs "status==RUNNING dir=~$curr_dir" --action stop;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action unskip;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action reset;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action rerun;"
TileBuilderTerm -x "TileBuilderGenParams;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action stop;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action unskip;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action reset;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action rerun;"
