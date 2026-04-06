set team = $1
set team = manager
set disk_usage = `df ./ | grep -v Filesystem | awk '{print $5}' | sed 's/\%//g'`
set alertDisk = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "alertDisk,|diskAlert," | awk -F "," '{print $2}'`
set n_alertDisk = `echo $alertDisk | wc -w`
if ($n_alertDisk > 0) then
else
    set alertDisk = 90
endif
if ($disk_usage > $alertDisk) then
endif
set n_team = `echo $team | wc -w`
set curr_dir = `pwd`
set n_debuggers =  `egrep flowLead $source_dir/assignment.csv | awk -F "," '{print $2}' | wc -l`
set vto = `cat $source_dir/assignment.csv | grep vto | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
set debuggers = ""
set name = ""
foreach debugger (`python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "flowLead|debugger" | awk -F "," '{print $2}'`)
    set debuggers = "$debuggers,$debugger"
    set name = `echo $debugger | sed 's/\@/ /g' | sed 's/\./ /g' | sed 's/[0-9]\+//g'  | awk '{print $1}'`
end
if ($n_team > 0) then
    foreach tm (`echo $team | sed 's/:/ /g'`)
        echo "# $tm"
        set tme = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "$tm," | awk -F ',' '{print $2}' | sed 's/\r//g' | head -n 1`
        set n_tme = `echo $tme | wc -w`
        if ($n_tme == 0) then
            continue
        endif
        echo "# add team to list $debuggers | $tme"
        set n_tme = `echo $debuggers | grep $tme | wc -w`
        echo "added"
        # remove duplicate address
        if ($n_tme > 0) then
        else
            set debuggers = "$debuggers,$tme"
        endif
    end
endif

set mgr = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "manager," |  awk -F ',' '{print $2}' | sed 's/\r//g'`
set n_mgr = `echo $mgr | wc -w`
if ($n_mgr > 0) then
    set n_mgr = `echo $debuggers | grep $mgr | wc -w`
    # remove duplicate address
    if ($n_mgr > 0) then
    else
        set debuggers = "$debuggers,$mgr"
    endif
endif

if ($disk_usage > $alertDisk) then
    echo "Hi guys," > alertDisk.log
    set current_disk = `df ./ | awk '{print $6}' | grep "/proj"`
    echo "$current_disk is over ${alertDisk}%!" >> alertDisk.log
    python $source_dir/script/spec2Html.py --spec alertDisk.log --html alertDisk.log.html
    cat alertDisk.log.html | formail -I "To:$debuggers" -I "From: $vto" -I "MIME-Version:1.0" -I "Content-type:text/html;charset=utf-8" -I "Subject:Disk almost Full" | sendmail -oi $debuggers
endif
