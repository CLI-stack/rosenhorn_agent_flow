set project = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "project," | awk -F "," '{print $2}' | sed 's/\r//g'`
python3.8 $source_dir/script/group_compare_time.py --run_dir $dir --refRuntime $source_dir/script/project/$project/runtime.csv --output compare_runtime.txt 
if (-e compare_runtime.txt) then
    set run_time_err = `grep $target compare_runtime.txt | grep "more than twice the uptime"`
    set n_run_time_err = `echo $run_time_err | wc -w`
else
    set n_run_time_err = 0
endif
if (-e $target.runtime.log) then
    rm $target.runtime.log
endif
#change for opening the MLMP that change the FxFpPlaceMacros run time
#if ($n_run_time_err > 0) then
#    echo "Hi Expert," > $target.runtime.log
#    echo "$run_time_err" >> $target.runtime.log
#endif
set MLMP = `grep "^I2_MLPLACE_MACROS" $dir/tile.params | awk '{print $3}'` #judge the MLMP params
if ( "$MLMP" != "1") then
		if ($n_run_time_err > 0) then
		    echo "Hi Expert," > $target.runtime.log
		    echo "$run_time_err" >> $target.runtime.log
		endif
else
        if ( "$target" != "FxFpPlaceMacros") then
			if ($n_run_time_err > 0) then
			    echo "Hi Expert," > $target.runtime.log
			    echo "$run_time_err" >> $target.runtime.log
			endif
        endif
endif
