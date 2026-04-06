set tag = $1
set n = 0
touch tasksModel.csv.lock
rm -rf tasksModel.csv.lock 
touch vtoMonitor.lock
rm -rf vtoMonitor.lock

set startTime = `date`
echo "## Start at $startTime"
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
while(1)
    set disk = `df ./ | grep -v Filesystem | awk '{print $5}' | sed 's/%//g'`
    if ($disk > 99) then
        echo "# Disk is full! "
        df ./
        touch disk_full
        sleep 5
        continue
    else
        touch disk_full
        rm disk_full
    endif
    
    set tasksMail = `python3 script/read_csv.py --csv assignment.csv | grep "^mail," | awk -F "," '{print $2}'`
    set n_tasksMail = `echo $tasksMail | wc -w`
    set source_dir = `pwd`
    set tasksGui = "$source_dir/chatbot.csv"
    set n_tasksGui = `echo $tasksGui | wc -w`

    if ( $n_tasksMail > 0) then
        if (-e $tasksMail) then
        else
            echo "########## $tasksMail not exist."
            if (-e $tasksGui) then
                echo "########## Only $tasksGui available."
            else
                echo "########## $tasksGui or $tasksMail not exist."
                break
            endif
        endif
        if (-e $tasksGui && -e $tasksMail) then
            cp $tasksMail tasksMail.csv
            set tasksMail = `resolve tasksMail.csv`
            echo "# Merge $tasksMail and $tasksGui to $tasksMail"
            python3 $source_dir/script/merge_tasks.py --mailFile $tasksGui --tasksLLMFile $tasksMail
        endif
    endif

    if ($n_tasksMail == 0) then
        if (-e $tasksGui) then
            set tasksMail = $tasksGui
            echo "########## Only $tasksGui available."
        else
            echo "########## $tasksGui or mail csv not exist."
            break
        endif
    endif
    

    if (-e tasksModel_bk) then
    else
        mkdir tasksModel_bk
    endif
    if (-e run.stop || -e vto_exit) then
        echo "## Found run.stop, stop process."
        break
    endif
    set day = `date | sed 's/:/ /g' | sed 's/ 0/ /g' | awk '{print $3}'`
    set hour = `date | sed 's/:/ /g' | sed 's/ 0/ /g' | awk '{print $4}'`
    set minute = `date | sed 's/:/ /g' | sed 's/ 0/ /g' | awk '{print $5}'` 
    if ($hour == 0 && $minute == 0) then
        cp tasksModel.csv tasksModel_bk/tasksModel.$day.csv
    endif
    set n = `expr $n + 1`
    set current_date = `date`
    echo "-------------------------------------------------------------------------------     $vto $current_date"
    echo "############## vtoHybridModel Don't Ctrl+c now, otherwise tasksModel.csv may be damaged"
    source csh/vtoHybridModel_sep.csh $tasksMail "tasksModel.csv" "instruction.csv" >& vtoHybridModel_sep.log
    echo "# You can Ctrl+c this script now within 10s"
    set n = 10
    while($n > 0) 
        set n = `expr $n - 1`
        echo "# $n"
        sleep 1
    end
    echo "############## vtoExecution"
    source csh/vtoExecution.csh 'tasksModel.csv' 'runExecution.csh'  & 
    echo "# Sleep 20s for csh/vtoExecution.csh start, avoiding new tasksModel.csv.lock created."
    sleep 20
    set pendingTimeLimit = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "pendingTimeLimit," | awk -F "," '{print $2}' | sed 's/\r//g'`
    set n_pendingTimeLimit = `echo $pendingTimeLimit | wc -w`
    if ($n_pendingTimeLimit == 0) then
        set pendingTimeLimit = 10
    endif

    echo "############## vtoMonitor"
    set source_dir = `pwd`
    set monitorPeriod = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "monitorPeriod," | awk -F "," '{print $2}' | sed 's/\r//g'`
    set n_monitorPeriod = `echo $monitorPeriod | wc -w`
    if ($n_monitorPeriod  == 0) then
        set monitorPeriod  = 1
    endif

    set monitorPop = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "monitorPop," | awk -F "," '{print $2}' | sed 's/\r//g'`
    set n_monitorPop = `echo $monitorPop | wc -w`
    if ($n_monitorPop  == 0) then
        set monitorPop  = 1
    endif
    if ($monitorPop == 1) then
        #set monitor_csh = 'xterm -e "source csh/vtoMonitor.csh tasksModel.csv $vto | tee vtoMonitor.log"'
        set monitor_csh = "source csh/vtoMonitor.csh tasksModel.csv $vto | tee vtoMonitor.log"
    else
        set monitor_csh = "source csh/vtoMonitor.csh tasksModel.csv $vto | tee vtoMonitor.log"
    endif

    set current_hour = `date | sed 's/:/ /g' | awk '{print int($4/1)}'`
    set current_hour = `echo "$current_hour $monitorPeriod"  | awk '{print int($1/$2)}'`
    if (-e data/record_monitor) then
        set n_record = `cat data/record_monitor`
        echo "# Monitor record: $current_hour $n_record"
        if ($current_hour == $n_record) then
        else
            echo "$current_hour" > data/record_monitor
            echo "# Launch monitor $monitor_csh"
            set lsfProject = `python3 $source_dir/script/read_csv.py --csv assignment.csv | grep "lsfProject," | awk -F "," '{print $2}'`
            set n_lsfProject = `echo $lsfProject | wc -w`
            set noXterm = `python3 $source_dir/script/read_csv.py --csv assignment.csv | grep "noXterm," | awk -F "," '{print $2}'`
            set n_noXterm = `echo $noXterm | wc -w`
            if ($n_lsfProject > 0) then
                if ($n_noXterm > 0) then
                    bsub -P $lsfProject -q regr_high -R 'select[type==RHEL7_64] rusage[mem=10000]' -R 'select[(type==RHEL7_64||type==RHEL8_64)&&(csbatch||gb64||gb128||tmplongforce)]' -o vtoMonitor.log /bin/csh csh/vtoMonitor.csh tasksModel.csv $vto
                else
                    bsub -P $lsfProject -q regr_high -R 'select[type==RHEL7_64] rusage[mem=10000]' -R 'select[(type==RHEL7_64||type==RHEL8_64)&&(csbatch||gb64||gb128||tmplongforce)]' csh/vtoMonitor.csh tasksModel.csv $vto > vtoMonitor.log
                endif
            else
                $monitor_csh &
            endif
            echo "# check pending tasks"
            source $source_dir/script/check_pending_tasks_core.csh 
        endif
    else
        echo "$current_hour" > data/record_monitor
    endif
    echo "## Generate tasks status:"
    echo "#list#" > tasks_viewer.spec
    echo "$source_dir/report_runProgress_spec.html" >> tasks_viewer.spec
    echo "$source_dir/report_flowIssue_spec.html" >> tasks_viewer.spec
    echo "$source_dir/tile_status.html" >> tasks_viewer.spec
    python3 script/tasks_viewer.py --tasksMail $tasksMail --tasksModel tasksModel.csv >> tasks_viewer.spec
    python3 script/spec2Html.py --spec tasks_viewer.spec --html tasks_viewer.html 
    echo "## $source_dir/tasks_viewer.html is generated."
    echo "######### periodical_action"
    # use to define periodical action for each function team
    if (-e $source_dir/script/periodical_action.csh) then
        source $source_dir/script/periodical_action.csh
    endif
    #source csh/vtoMonitor.csh
    if (-e run.step) then
        echo "## Found tasks.step, end process."
        break
    endif
    sleep 20
    if ($n == 20) then
        #break
    endif
    echo `date`
    # if in debug mode, the run_sep.log will keep updated
    if (-e vto_debug) then
    else
        break
    endif

end
