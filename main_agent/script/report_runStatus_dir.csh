echo "# start report tile qor"
source $source_dir/script/report_tileStatus_core.csh &
set userMetrics = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "userMetrics,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_userMetrics = `echo $userMetrics | wc -w`
source $source_dir/script/report_flowIssue_dir.csh &
source $source_dir/script/tile/debug/check_CbReport.csh
if ($n_userMetrics > 0) then
    echo "# Launch $userMetrics"
    source $userMetrics
endif

# dmsa for eco
set dmsa_script = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "dmsa,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_dmsa_script = `echo $dmsa_script | wc -w`
if ($n_dmsa_script > 0) then
    echo "# Launch $dmsa_script"
    source $dmsa_script
endif

