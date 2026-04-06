# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com

# Copyright (c) 2024 Chen, Simon ; simon1.chen@amd.com;  Advanced Micro Devices, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

echo $dir
#  TileBuilderTerm --localterm -x "serascmd -find_jobs "name==FxRoute dir=~df_rpt_6_t_2023_06_07_16_11_20_919000_00_00_TileBuilder_Jun07_0451_54336_GUI" --action run"
cd $dir
if (-e exec_monitor_debug.csh) then
else
    echo "set source_dir = $source_dir" > exec_monitor_debug.csh
    echo "set dir = $dir" >> exec_monitor_debug.csh
    echo "set monitorAction = 1" >> exec_monitor_debug.csh
    echo "source $source_dir/script/exec_monitor_dir.csh" >> exec_monitor_debug.csh
endif
set maxRetrace = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "maxRetrace,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set monitorDuration = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "monitorDuration,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_maxRetrace = `echo $maxRetrace | wc -w`
if ($n_maxRetrace == 0) then
    set maxRetrace = 2
endif
set n_monitorAction = `echo $monitorAction | wc -w`
if ($n_monitorAction == 0) then
    set monitorAction = 1
endif
echo "# monitorAction $monitorAction"

echo "# check $dir"
set function = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "function," | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_function = `echo $function | wc -w`
if (n_function == 0)  then
    set function = "tile"
endif

####################################
# execute hack script generated when starting run, e.g. hack sdc,add command to tune during after TB start
####################################
foreach task (`ls *.task`)
    set tag = `echo $task | awk -F "." '{print $1}'`
    set n_sub = `cat $task | wc -w`
    if ($n_sub > 0) then
        set sub = `cat  $task`
        foreach hs (`ls $source_dir/data/$tag/run__${sub}__*.csh`)
            source $hs
        end
    endif
end
set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
#echo "# Retrace $dir"
#TileBuilderTerm --localterm -x "serascmd -find_jobs "status==NOTRUN dir=~$curr_dir" --action run" 
# Generate target status
echo "# Generate target status"
TileBuilderTerm --localterm -x "TileBuilderShow -o tbs.log" 
set tb_dir = `ls -1d ../../../../TileBuilder*` 
set n_tb_dir = `ls -1d ../../../../TileBuilder* | wc -l`
if ($n_tb_dir == 1) then
else
    echo "# Warning: multiple tb dir found, use TileBuilder"
    set tb_dir = `ls -1d ../../../../TileBuilder`
endif
if (-e tbs.log) then
    cp tbs.log $source_dir/
    set n_tbs = `cat tbs.log | wc -w`
    if ($n_tbs == 0) then
        echo "# TileBuilderShow version too old to generate tbs.log"
        cd $tb_dir 
        p4 sync //depot/tools/aticad/1.0/flow/TileBuilder/lib/TileBuilderShow/TileBuilderShow.py#10
        cd -
    endif
else
    echo "# TileBuilderShow version too old to generate tbs.log"
    cd $tb_dir 
    p4 sync //depot/tools/aticad/1.0/flow/TileBuilder/lib/TileBuilderShow/TileBuilderShow.py#10
    cd -
endif
echo "# Check seras activity"
# Running -sanity and -stats may cause script hung.
#TileBuilderTerm --localterm -x "seras -sanity > sanity.log"
#TileBuilderTerm --localterm -x "seras -stats > stats.log"
if (-e sanity.log) then
    set n_sanity = `cat sanity.log | wc -w`
    if ($n_sanity == 0) then
        echo "# TileBuilderTerm version too old to redirect sanity.log"
        cd $tb_dir 
        p4 sync //depot/tools/aticad/1.0/flow/TileBuilder/bin/.TileBuilderTerm#14
        cd -
    endif
else
    echo "# TileBuilderTerm version too old to redirect sanity.log"
    cd $tb_dir 
    p4 sync //depot/tools/aticad/1.0/flow/TileBuilder/bin/.TileBuilderTerm#14
    cd -
endif
############################
# check jira params/p4/tune/tool version 
#############################
echo "# Check Jira"
if (-e $source_dir/script/compare_jira.py) then
    python $source_dir/script/compare_jira.py --source_dir $source_dir --item "params"
    if (-e jira/params.list) then
        set n_params = `cat jira/params.list | wc -w`
        if ($n_params > 0) then
            echo "# Found new params, add params and TBgen."
            cat jira/params.list
            cat jira/params.list >> override.params
            TileBuilderTerm --localterm -x "TileBuilderGenParams;"  
            echo "" > jira/params.list
        endif
    endif
    python $source_dir/script/compare_jira.py --source_dir $source_dir --item "controls" 
    if (-e jira/controls.list) then
        set n_controls = `cat jira/controls.list | wc -w`
        if ($n_controls > 0) then
            echo "# Found new controls, add controls and TBgen."
            cat jira/controls.list 
            cat jira/controls.list >> override.controls
            TileBuilderTerm --localterm -x "TileBuilderGenParams;" 
            echo "" > jira/controls.list
        endif
    endif

    python $source_dir/script/compare_jira.py --source_dir $source_dir --item "p4"
    if (-e jira/p4.list) then
        set n_p4 = `cat jira/p4.list | wc -w`
        if ($n_p4 > 0) then
            echo "# Found new p4 file, sync p4 file."
            foreach file (`cat $dir/jira/p4.list | grep -v '^#'`)
                set n_tb = `echo $file | grep TileBuilder | wc -w`
                echo "# sync $file"
                if ($n_tb > 0) then
                    cd ../../../../TileBuilder/
                    p4 sync -f "$file"
                    cd $dir
                else
                    p4 sync -f "$file"
                endif
            end
        endif
        echo "" > $dir/jira/p4.list

    endif
endif

set finishedTarget = ""
set latestTarget = ""
set runningTarget = ""
set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
set n_failed = 0
set n_running = 0
set checked_targets = ""
# python $source_dir/script/parseFlowXml.py --xml data/flow.xml --direction downcone --target ShGetDef
echo "# check skipped target as follow check will skip targets which cause check overlap"
foreach target (`grep SKIPPED tbs.log |  awk '{print $2}' | egrep "FxFpPlaceMacros"`)
    set n_checked_target = `echo $checked_targets | grep $target | wc -w`
    if ($n_checked_target > 0) then
        continue
    endif
    set checked_targets = "$checked_targets $target"
    set n_target = `echo $target | wc -w`
    if ($n_target == 0) then
        continue
    endif
    echo "# check skipped $target"
    source $source_dir/script/debug/analyze_target.csh $target $source_dir 0 &
end

# Process skipable target 
set exception_target = "GenerateAllCommands"
foreach target (`echo $exception_target`)
    set n_skip = `grep NOTRUN tbs.log |  awk '{print $2}' | grep $target | wc -w`
    if ($n_skip > 0) then
        if (-e logs/$target.log.gz) then
            echo "# Skip exception target $target"
            if ($monitorAction == 1) then
                set skip_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action skip;"
                TileBuilderTerm --localterm -x $skip_cmd

            endif
        endif
    endif
end
echo "# checked_targets skipped target $checked_targets"
# check pass targets
echo "# Check pass targets"
foreach target (`grep PASSED tbs.log |  awk '{print $2}'`)
    set n_target = `echo $target | wc -w`

    if ($n_target == 0) then
        continue
    endif
    set n_checked_target = `echo $checked_targets | grep $target | wc -w`
    if ($n_checked_target > 0) then
        continue
    endif
    set checked_targets = "$checked_targets $target"
    echo "# check pass targets $target"
   # echo "# checked_targets pass targets $checked_targets"
   if (-e logs/${target}.log.gz) then
        set log_time = `ls -l logs/${target}.log.gz | sed "s/:/ /g" | sed "s/ 0/  /g" | awk '{print $7*24*60*60+$8*60*60+$9*60}'`
        set n_output = `zgrep "Required Outputs:" logs/$target.log.gz | wc -w`
        set n_missing = `zgrep " Output dependency file" logs/${target}.log.gz | egrep -v "rde.txt|iobuf_max_dist_viol.rpt|instance_gsc" | wc -w`
        set n_false_missing = `zgrep " Output dependency file" logs/${target}.log.gz | wc -w`
        set n_except = `echo $target | egrep "UpdateTunable" | wc -w`
        if ($n_missing == 0  && $n_output > 0) then
            echo "# skip finished target $target."
            if ($monitorAction == 1) then
                set skip_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action skip;"
                TileBuilderTerm --localterm -x $skip_cmd 
            endif
        endif

        # missing ouput or not finish
        if ($n_missing > 0 || $n_output == 0 && $n_except == 0) then
            
            source $source_dir/script/debug/analyze_target.csh $target $source_dir 1 &
        endif
        if ($n_missing > 0 && $n_output > 0) then
            if (-e $target.rerun && $monitorAction == 1) then
                set n_n_rerun = `cat $target.rerun | wc -w`
                set n_rerun = `cat $target.rerun`
                if ($n_n_rerun > 0 && $n_rerun < $maxRetrace) then
                    echo " # Found logs/$target.log.gz w/ output but missing file, rerun $n_rerun"
                    set reset_cmd = "serascmd -find_jobs 'name==$target dir=~$curr_dir' --action reset"
                    set rerun_cmd = "serascmd -find_jobs 'name==$target dir=~$curr_dir' --action rerun"
                    TileBuilderTerm --localterm -x $reset_cmd
                    TileBuilderTerm --localterm -x $rerun_cmd
                    rm logs/$target.log.gz
                    set n_rerun = `expr $n_rerun + 1`
                    echo $n_rerun > $target.rerun
                else
                    echo "# $target rerun count > $maxRetrace, not rerun to save iteration time"
                endif
            else
                if ($monitorAction == 1) then
                    set n_rerun = 1
                    echo " # Found logs/$target.log.gz w/ output but missing file, rerun $n_rerun"
                    set reset_cmd = "serascmd -find_jobs 'name==$target dir=~$curr_dir' --action reset"
                    set rerun_cmd = "serascmd -find_jobs 'name==$target dir=~$curr_dir' --action rerun"
                    TileBuilderTerm --localterm -x $reset_cmd
                    TileBuilderTerm --localterm -x $rerun_cmd
                    rm logs/$target.log.gz
                    echo "1" > $target.rerun
                endif
            endif

        endif
        #set n_skip = `grep $target skip_targets.list | wc -l` 

    endif
 
end
echo "# checked_targets pass targets $checked_targets"

# check running targets
echo "# check running targets"
foreach target (`grep RUNNING tbs.log |  awk '{print $2}'`)
    set n_target = `echo $target | wc -w`
    if ($n_target == 0) then
        continue
    endif
    set n_checked_target = `echo $checked_targets | grep $target | wc -w`
    if ($n_checked_target > 0) then
        continue
    endif
    set checked_targets = "$checked_targets $target"
    echo "# check running targets $target"
    # echo "# checked_targets running targets $checked_targets"
    if (-e logs/${target}.log) then
        source $source_dir/script/debug/analyze_target.csh $target $source_dir 0 &
    endif
    source $source_dir/script/check_runTime.csh
end
echo "# checked_targets running targets $checked_targets"

# check warning targets
echo "# check warning targets"
foreach target (`grep WARNING tbs.log |  awk '{print $2}'`)
    set n_target = `echo $target | wc -w`
    if ($n_target == 0) then
        continue
    endif
    set n_checked_target = `echo $checked_targets | grep $target | wc -w`
    if ($n_checked_target > 0) then
        echo "# $target has been checked before check warning"
        continue
    endif
    set checked_targets = "$checked_targets $target"
    echo "# check warning targets $target"
    #echo "# checked_targets warning targets $checked_targets"
    if (-e logs/${target}.log.gz) then
        set log_time = `ls -l logs/${target}.log.gz | sed "s/:/ /g" | sed "s/ 0/  /g" | awk '{print $7*24*60*60+$8*60*60+$9*60}'`
        set n_output = `zgrep "Required Outputs:" logs/$target.log.gz | wc -w`
        set n_missing = `zgrep " Output dependency file" logs/${target}.log.gz | egrep -v "rde.txt|iobuf_max_dist_viol.rpt|instance_gsc" | wc -w`
        set n_false_missing = `zgrep " Output dependency file" logs/${target}.log.gz | wc -w`
        set n_except = `echo $target | egrep "UpdateTunable" | wc -w`
        if ($monitorAction == 1) then
            set skip_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action skip;"
            TileBuilderTerm --localterm -x $skip_cmd
        endif
        if ($n_missing == 0  && $n_output > 0) then
            echo "# skip finished target $target."
            #source $source_dir/script/debug/analyze_target.csh $target $source_dir 0 &
            #TileBuilderTerm --localterm -x "serascmd -find_jobs "name==$target dir=~$curr_dir" --action skip"
        endif

        source $source_dir/script/debug/analyze_target.csh $target $source_dir 0 &
    endif
end
echo "# checked_targets warning targets $checked_targets"

# Process skipable target 
set exception_target = "GenerateAllCommands"
foreach target (`echo $exception_target`)
    set n_skip = `grep NOTRUN tbs.log |  awk '{print $2}' | grep $target | wc -w`
    if ($n_skip > 0) then
        if (-e logs/$target.log.gz) then
            echo "# Skip exception target $target"
            if ($monitorAction == 1) then
                set skip_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action skip;"
                TileBuilderTerm --localterm -x $skip_cmd

            endif
        endif
    endif
end

# check norun
echo "# check norun"
foreach target (`grep NOTRUN tbs.log |  awk '{print $2}'`)
    set n_target = `echo $target | wc -w`
    if ($n_target == 0) then
        continue
    endif
    set n_checked_target = `echo $checked_targets | grep $target | wc -w`
    if ($n_checked_target > 0) then
        echo "# $target has been checked before check norun"
        continue
    endif
    set checked_targets = "$checked_targets $target"
    #echo "# checked_targets  check norun $checked_targets"
    # echo "# check norun targets $target"
    if (-e logs/${target}.log) then
        source $source_dir/script/debug/analyze_target.csh $target $source_dir 0 &
    endif
end
echo "# checked_targets  check norun $checked_targets"


# check failed targets
echo "# check failed targets"
foreach target (`grep FAILED tbs.log |  awk '{print $2}'`)
    set n_target = `echo $target | wc -w`
    if ($n_target == 0) then
        continue
    endif
    set n_checked_target = `echo $checked_targets | grep $target | wc -w`
    if ($n_checked_target > 0) then
        echo "# $target has been checked before failed targets"
        continue
    endif
    set checked_targets = "$checked_targets $target"
    echo "# check failed targets $target" 
    if (-e logs/${target}.log.gz) then
        echo "## check failed target $target"
        set log_time = `ls -l logs/${target}.log.gz | sed "s/:/ /g" | sed "s/ 0/  /g" | awk '{print $7*24*60*60+$8*60*60+$9*60}'`
        set n_output = `zgrep "Required Outputs:" logs/$target.log.gz | wc -w`
        set n_missing = `zgrep " Output dependency file" logs/${target}.log.gz | egrep -v "rde.txt|iobuf_max_dist_viol.rpt|instance_gsc" | wc -w`
        set n_false_missing = `zgrep " Output dependency file" logs/${target}.log.gz | wc -w`

        # no output missing, skip.
        if ($n_missing == 0  && $n_output > 0 && $monitorAction == 1) then
            echo "# skip finished target $target."
            set skip_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action skip;"
            TileBuilderTerm --localterm -x $skip_cmd
            #echo "$target" >> skip_targets.list
        endif

        # missing output can be ignore, skip
        if ($n_missing == 0  && $n_output > 0 && $n_false_missing > 0 && $monitorAction == 1) then
            echo "# skip finished target $target."
            set skip_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action skip;"
            TileBuilderTerm --localterm -x $skip_cmd

            #echo "$target" >> skip_targets.list
        endif
        
        if ($n_missing > 0  && $n_output == 0) then
            source $source_dir/script/debug/analyze_target.csh $target $source_dir 1 &
        endif
    
        if ($n_missing > 0 && $n_output > 0) then
            cp logs/$target.log.gz ./
            source $source_dir/script/debug/analyze_target.csh $target $source_dir 1 & 
            if (-e $target.rerun && $monitorAction == 1) then
                set n_n_rerun = `cat $target.rerun | wc -w`
                set n_rerun = `cat $target.rerun`
                if ($n_n_rerun > 0 && $n_rerun < $maxRetrace) then
                    echo " # Found logs/$target.log.gz w/ output but missing file, rerun $n_rerun"
                    set reset_cmd = "serascmd -find_jobs 'name==$target dir=~$curr_dir' --action reset"
                    set rerun_cmd = "serascmd -find_jobs 'name==$target dir=~$curr_dir' --action rerun"
                    TileBuilderTerm --localterm -x $reset_cmd
                    TileBuilderTerm --localterm -x $rerun_cmd

                    rm logs/$target.log.gz
                    set n_rerun = `expr $n_rerun + 1`
                    echo $n_rerun > $target.rerun
                else
                    echo "# $target rerun count > $maxRetrace, not rerun to save iteration time"
                endif
            else
                if ($monitorAction == 1) then
                    set n_rerun = 1
                    echo " # Found logs/$target.log.gz w/ output but missing file, rerun $n_rerun"
                    set reset_cmd = "serascmd -find_jobs 'name==$target dir=~$curr_dir' --action reset"
                    set rerun_cmd = "serascmd -find_jobs 'name==$target dir=~$curr_dir' --action rerun"
                    TileBuilderTerm --localterm -x $reset_cmd
                    TileBuilderTerm --localterm -x $rerun_cmd
                    rm logs/$target.log.gz
                    echo "1" > $target.rerun
                endif
            endif
            continue
        endif
        #set n_skip = `grep $target skip_targets.list | wc -l` 

    endif
end

# check non-run targets
echo "# check non-run targets"
set n_norun = `grep NOTRUN tbs.log |  awk '{print $2}' | wc -w`
set rerun_targets = ""
if ($n_norun > 0 && $monitorAction == 1) then
    echo "# Check if norun targets caused by failed target that rerun over maxRetrace."
    touch maxRerun.list
    rm maxRerun.list
    source $source_dir/script/env.csh
    foreach rerun (`ls *.rerun`)
        set n_rerun = `cat $rerun`
        set target = `echo $rerun | awk -F "." '{print $1}'`
        if ($n_rerun == $maxRetrace) then
            echo "# Found max retrace target $target $maxRetrace"
            python $source_dir/script/parseFlowXml.py --xml data/flow.xml --direction downcone --target $target >> maxRerun.list
        else
            touch maxRerun.list
        endif
    end
    set rerun_cmd = ""
    foreach target (`grep NOTRUN tbs.log |  awk '{print $2}'`)
        set n_need_rerun = `grep $target maxRerun.list | wc -l`
        if ($n_need_rerun > 0) then
        else
            if (-e $target.rerun) then
                set n_n_rerun = `cat $target.rerun | wc -w`
                set n_rerun = `cat $target.rerun`
                if ($n_n_rerun > 0 && $n_rerun < $maxRetrace) then

                    set rerun_targets = "$rerun_targets $target"
                    set n_rerun = `expr $n_rerun + 1`
                    echo $n_rerun > $target.rerun
                endif
            else
                echo "1" > $target.rerun
            endif
        endif
    end

endif
# Compress non run target, only run end node
set rerun_targets = `python $source_dir/script/findCommonEndNode.py --xml data/flow.xml --direction downcone --targets "$rerun_targets"`
foreach target (`echo $rerun_targets`)
    set rerun_cmd = "$rerun_cmd;serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action run;"
end
set n_rerun_cmd = `echo $rerun_cmd | wc -w`
if ($n_rerun_cmd > 0) then
    echo "# Rerun norun target."
    TileBuilderTerm --localterm -x "$rerun_cmd"
endif

# Flow has finished
if (-e logs/FxStreamOut.log.gz) then
    #set length_running = 1
endif
if (-e $source_dir/script/report_runStatus_dir.csh) then
    echo "# Found script/report_runStatus_dir.csh"
    source $source_dir/script/report_runStatus_dir.csh
endif

echo "# collect lib info."
#source $source_dir/script/get_lib_info.csh
# auto retrace if target stop due to error
echo "# exec_monitor_dir finished."
#######################
# Generate report
#######################
