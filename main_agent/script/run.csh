set tag = $1
set n = 0
touch tasksModel.csv.lock
rm -rf tasksModel.csv.lock 
set startTime = `date`
echo "## Start at $startTime"
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
while(1)
    if (-e tasksModel_bk) then
    else
        mkdir tasksModel_bk
    endif
    if (-e run.stop) then
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
    echo "############## vtoHybridModel"
    source csh/vtoHybridModel.csh "tasksMail.csv" "tasksModel.csv" "instruction.csv" | tee run.log
    echo "############## vtoExecution"
    source csh/vtoExecution.csh "tasksModel.csv" "csh/runExecution.csh" | tee run.log
    echo "############## vtoMonitor"
    source csh/vtoMonitor.csh "tasksModel.csv" | tee run.log
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
end
