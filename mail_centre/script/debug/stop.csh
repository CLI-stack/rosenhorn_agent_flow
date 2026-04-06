# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set team = $1
set n_team = `echo $team | wc -w`
set curr_dir = `pwd`
echo "# Rerun $target at $curr_dir"
set n_debuggers =  `egrep flowLead $source_dir/assignment.csv | awk -F "," '{print $2}' | wc -l`
set vto = `cat $source_dir/assignment.csv | grep vto | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
set debuggers = ""
set name = ""
## stop target
set curr_dir = `pwd`
set stop_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action stop;"
TileBuilderTerm -x $stop_cmd
foreach debugger (`python $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "flowLead|debugger" | awk -F "," '{print $2}'`)
    set debuggers = "$debuggers,$debugger"
    set name = `echo $debugger | sed 's/\@/ /g' | sed 's/\./ /g' | sed 's/[0-9]\+//g'  | awk '{print $1}'`
end
if ($n_team > 0) then
    foreach tm (`echo $team | sed 's/:/ /g'`)
        set tme = `python $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "$tm," | awk -F ',' '{print $2}' | sed 's/\r//g' | head -n 1`
        echo "# add team to list $debuggers $tme"
        set n_tme = `echo $debuggers | grep $tme | wc -w`
        echo "added"
        # remove duplicate address
        if ($n_tme > 0) then
        else
            set debuggers = "$debuggers,$tme"
        endif
    end
endif

set mgr = `python $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "manager," |  awk -F ',' '{print $2}' | sed 's/\r//g'`
set n_mgr = `echo $debuggers | grep $mgr | wc -w`
# remove duplicate address
if ($n_mgr > 0) then
else
    set debuggers = "$debuggers,$mgr"
endif
set today = `date | awk '{print $3}'`
if (-e $target.error.log) then
    set log_center = `python $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "log," | awk -F "," '{print $2}'`
    if (-e $log_center/$target.reported && $team != "debugger") then
        set reported_date = `ls -l $log_center/$target.reported | awk '{print $7}'`
        if ($reported_date > $today) then
            set reported_date = `expr $reported_date - 30`
        endif
        if ($today - $reported_date > 3) then
            rm -rf $log_center/${target}.*
        endif

    else
        python $source_dir/script/spec2Html.py --spec $target.error.log --html $target.error.html
        cat $target.error.html | formail -I "To:$debuggers" -I "From: $vto" -I "MIME-Version:1.0" -I "Content-type:text/html;charset=utf-8" -I "Subject:$target Failed" | sendmail -oi $debuggers
        touch $target.reported
        cp $target.reported $log_center/
        cp $target.error.log $log_center/
    endif
endif
