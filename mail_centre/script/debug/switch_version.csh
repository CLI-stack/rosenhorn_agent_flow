# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set curr_dir = `pwd`
echo "# Rerun $target at $curr_dir"
set monitorAction = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "monitorAction,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_monitorAction = `echo $monitorAction | wc -w`
if ($n_monitorAction == 0) then
    set monitorAction = 1
endif
if ($monitorAction == 1) then
endif
## switch FC
set n_fx = `echo $target | grep Fx | wc -w`
set switched = 0
if ($n_fx > 0) then
    if (-e $target.log) then
        set eda_version = `grep "setenv FC_MODULE" $target.log | grep -v "#" | awk '{print $3}'`
        set date = `date` 
        echo "$date $target $eda_version" >> crash.list
        echo "$source_dir/data/jira/edatool.list $date $target $eda_version"
        if (-e $source_dir/data/jira/edatool.list) then
            foreach new_version (`cat $source_dir/data/jira/edatool.list | grep fusioncompiler`)
                set n_used = `grep $new_version crash.list | grep $target |  wc -w`
                if ($n_used == 0) then
                    echo "FC_MODULE_$target = $new_version" >> override.controls
                    set switched = 1
                    break
                endif
            end
        endif 
    endif
    if (-e $target.log.gz) then
        set eda_version = `zgrep "setenv FC_MODULE" $target.log.gz | grep -v "#" | awk '{print $3}'`
        set date = `date`
        echo "$date $target $eda_version" >> crash.list
        echo "$source_dir/data/jira/edatool.list $date $target $eda_version"
        if (-e $source_dir/data/jira/edatool.list) then
            foreach new_version (`cat $source_dir/data/jira/edatool.list | grep fusioncompiler`)
                set n_used = `grep $new_version crash.list | grep $target | wc -w`
                if ($n_used == 0) then
                    echo "# swhich to $new_version"
                    echo "FC_MODULE_$target = $new_version" >> override.controls
                    set switched = 1
                    break
                endif
            end
        endif
    endif

endif
## switch ICV
if ($target == "FxGenReRouteFill" || $target == "FxGenRouteFill" || $target == "FxGenOptRouteFill") then
    if (-e $target.log) then
        set eda_version = `grep "setenv ICV_MODULE" $target.log | grep -v "#" | awk '{print $3}'`
        set date = `date`
        echo "$date $target $eda_version" >> crash.list
        if (-e $source_dir/data/jira/edatool.list) then
            foreach new_version (`cat $source_dir/data/jira/edatool.list | grep icvalidator`)
                set n_used = `grep $new_version crash.list | grep $target | wc -w`
                if ($n_used == 0) then
                    echo "ICV_MODULE_$target = $new_version" >> override.controls
                    set switched = 1
                    break
                endif
            end
        endif
    endif
    if (-e $target.log.gz) then
        set eda_version = `zgrep "setenv ICV_MODULE" $target.log.gz | grep -v "#" | awk '{print $3}'`
        set date = `date`
        echo "$date $target $eda_version" >> crash.list
        if (-e $source_dir/data/jira/edatool.list) then
            foreach new_version (`cat $source_dir/data/jira/edatool.list | grep icvalidator`)
                set n_used = `grep $new_version crash.list | grep $target | wc -w`
                if ($n_used == 0) then
                    echo "ICV_MODULE_$target = $new_version" >> override.controls
                    set switched = 1
                    break
                endif
            end
        endif
    endif

endif
set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
if ($monitorAction == 1 && $switched == 1) then
    set seras_cmd = ";serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action stop;serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action unskip;serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action reset;serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action rerun"
    set id = `date | sed 's/ /_/g'`
    TileBuilderTerm --localterm -x "TileBuilderGenParams;$seras_cmd;touch switch_version_${id}.log"
endif
source $source_dir/script/debug/report.csh manager
