set ar = $1
set tag = $2
set h_grid = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "h_grid," | awk -F "," '{print $2}'`
set h_offset = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv"  | grep "h_offset," | awk -F "," '{print $2}'`
set v_grid = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "v_grid," | awk -F "," '{print $2}'`
set n_tune = `ls -1d tune | wc -w`
if (-e ar_tune.finished) then
else
    if ($n_tune > 0) then
        if (-e tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl) then
            echo "# start generate shmoo aspect ratio tune"
            echo "source $source_dir/script/shmoo_aspectRatio.tcl" > tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            echo "shmoo_aspectRatio $ar $h_grid $h_offset $v_grid" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl 
            grep trackplan cmds/FxFpPlaceMacros.cmd | grep -v put >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            touch ar_tune.finished
        else
            mkdir -p tune/FxFpPlaceMacros 
            echo "# start generate shmoo aspect ratio tune"
            echo "source $source_dir/script/shmoo_aspectRatio.tcl" > tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            echo "shmoo_aspectRatio $ar $h_grid $h_offset $v_grid" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            grep trackplan cmds/FxFpPlaceMacros.cmd | grep -v put >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            touch ar_tune.finished

        endif
    endif
endif
