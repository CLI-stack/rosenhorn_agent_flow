# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
source $source_dir/script/env.csh
set pendingTimeLimit = $1
touch pending_job.log
rm pending_job.log
echo "Hi Expert," >> pending_job.log
foreach line ("`bjobs -w | grep PEND | egrep 'csh/vtoMonitor.csh|runs/runExecution'`")
    set current_day = `date | awk '{print $3}'`
    set current_hour = ` date | awk '{print $4}' | sed 's/:/ /g' | awk '{print $1}' | sed 's/ 0//g'`
    set job_hour = `echo $line | awk '{print $NF}' | sed 's/:/ /g' | awk '{print $1}' | sed 's/ 0//g'`
    set job_day = `echo $line | awk '{print $(NF-1)}'`
    set delta = `echo $job_day $job_hour $current_day $current_hour | awk '{print $3*24+$4-$1*24-$2}'` 
    #echo "$job_day $job_hour $current_day $current_hour"
    #echo $delta
    if ($delta >= $pendingTimeLimit) then
        echo "$line" >> pending_job.log
    endif
end

set team = "manager"
set n_team = `echo $team | wc -w`
set curr_dir = `pwd`
set n_debuggers =  `egrep flowLead $source_dir/assignment.csv | awk -F "," '{print $2}' | wc -l`
set vto = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "vto,"  | awk -F "," '{print $2}'`
set debuggers = ""
set name = ""
foreach debugger (`python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "flowLead|debugger" | awk -F "," '{print $2}'`)
    set debuggers = "$debuggers,$debugger"
    set name = `echo $debugger | sed 's/\@/ /g' | sed 's/\./ /g' | sed 's/[0-9]\+//g'  | awk '{print $1}'`
end
if ($n_team > 0) then
    foreach tm (`echo $team | sed 's/:/ /g'`)
        set tme = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "$tm," | awk -F ',' '{print $2}' | sed 's/\r//g' | head -n 1`
        echo "# add team to list $debuggers $tme"
        set n_tme = `echo $tme | wc -w`
        if ($n_tme == 0) then
            continue
        endif
        set n_tme = `echo $debuggers | grep $tme | wc -w`
        # remove duplicate address
        if ($n_tme > 0) then
        else
            set debuggers = "$debuggers,$tme"
        endif
    end
endif

set mgr = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "manager," |  awk -F ',' '{print $2}' | sed 's/\r//g'`
set n_mgr = `echo $debuggers | grep $mgr | wc -w`
# remove duplicate address
if ($n_mgr > 0) then
else
    set debuggers = "$debuggers,$mgr"
endif
set n_pending_job = `cat pending_job.log | wc -l`
if ($n_pending_job > 1) then
    echo "# Report Pending tasks at $curr_dir to $team"
    python $source_dir/script/spec2Html.py --spec pending_job.log --html pending_job.log.html
    cat pending_job.log.html | formail -I "To:$debuggers" -I "From: $vto" -I "MIME-Version:1.0" -I "Content-type:text/html;charset=utf-8" -I "Subject:Tasks Pending" | /sbin/sendmail -oi $debuggers
endif


