# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set tag = $4
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec
echo "The following tasks are pending" >> $source_dir/data/${tag}_spec
set pendingTimeLimit = 1
foreach line ("`bjobs -w | grep PEND | egrep 'csh/vtoMonitor.csh|runs/runExecution'`")
    set current_day = `date | awk '{print $3}'`
    set current_hour = ` date | awk '{print $4}' | sed 's/:/ /g' | awk '{print $1}' | sed 's/ 0//g'`
    set job_hour = `echo $line | awk '{print $NF}' | sed 's/:/ /g' | awk '{print $1}' | sed 's/ 0//g'`
    set job_day = `echo $line | awk '{print $(NF-1)}'`
    set delta = `echo $job_day $job_hour $current_day $current_hour | awk '{print $3*24+$4-$1*24-$2}'` 
    #echo "$job_day $job_hour $current_day $current_hour"
    #echo $delta
    if ($delta >= $pendingTimeLimit) then
        echo "$line" >> $source_dir/data/${tag}_spec
    endif
end

echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh

