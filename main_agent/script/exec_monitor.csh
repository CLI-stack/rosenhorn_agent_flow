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

touch vtoMonitor.lock
set tasksModelFile = $1
# check if any task finished
#source $source_dir/script/send_finished_report.csh $tasksModelFile
set targets = "ShGetMacroLists BuildTechDir GetSdc FxGenProcessLabelMap FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower FxPostFloorPlan PyPrepScanDef FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxXtrcttyprc100cCts FxOptCts FxIncrProuteOptCts FxRoute FxGenRouteFill FxOptRoute FxReRoute FxStreamOut"
set source_dir = `pwd`
set tuneCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "tune,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set monitorAction = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "monitorAction,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_monitorAction = `echo $monitorAction | wc -w`
if ($n_monitorAction == 0) then
    set monitorAction = 1
endif
echo "# monitorAction $monitorAction"
if (-e vto_stop_action) then
    set stop_action = 1
else
    set stop_action = 0
endif
if (-e vto_debug) then
    set vto_debug = 1
else
    set vto_debug = 0
endif
foreach disk (`python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "^disk," | awk -F "," '{print $2}' | sed 's/\r//g'`)
    cd $disk
    set vto = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "^vto," | head -n 1 | awk -F "," '{print $2}' | sed 's/\r//g'`
    if (-e $vto) then
        cd $vto
    else
        mkdir $vto
        cd $vto
    endif
    echo "# check disk usage  $disk"
    source $source_dir/script/alertDisk.csh
end
cd $source_dir
set function = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "function," | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_function = `echo $function | wc -w`
if (n_function == 0)  then
    set function = "tile"
endif
####################################
# Copy hacked file to run dir
###################################
foreach subFile (`ls $source_dir/data/*.sub*.files | sort -r`)
    set tag = `echo $subFile | sed 's/data\// /g' | sed 's/\./ /g' | awk '{print $2}'`
    if (-e $source_dir/data/$tag.runDirFiles) then
        if (-e $source_dir/data/$tag.runDirFiles.progress) then
            set n_runDirFiles = `cat $source_dir/data/$tag.runDirFiles | wc -l`
            set n_progress = `cat $source_dir/data/$tag.runDirFiles.progress | wc -l`
            #echo "# check progress $n_runDirFiles $n_progress"
            if ($n_runDirFiles == $n_progress) then
                continue
            endif
        endif
        touch $source_dir/data/$tag.runDirFiles.progress
        foreach rdf (`cat $source_dir/data/$tag.runDirFiles`)
            set rd = `echo $rdf | sed 's/,/ /g' | awk '{print $2}'`
            set f = `echo $rdf | sed 's/,/ /g' | awk '{print $3}'`
            set n_rd_done = `cat $source_dir/data/$tag.runDirFiles.progress | grep $rd | wc -w`
            set allReady = 0
            if (-e $rd && $n_rd_done == 0) then
                #echo "$rd $f"            
                cd $rd
                set n_hf = `cat $source_dir/data/$f | grep -v "tune" | wc -l`
                set i_hf = 0
                # check if all to be hacked file exist
                foreach hf (`cat $source_dir/data/$f`)
                    set fileName = `echo $hf | sed 's/\// /g' | awk '{print $NF}'`
                    echo "$hf $fileName"
                    if (-e data/$fileName) then
                        echo "# Found file data/$fileName"
                        set i_hf = `expr $i_hf + 1`
                    endif
                    if (-e cmds/$fileName) then
                        echo "# Found file cmds/$fileName"
                        set i_hf = `expr $i_hf + 1`
                    endif
                    if (-e data/sdc/$fileName) then
                        echo "# Found data/sdc/$fileName"
                        set i_hf = `expr $i_hf + 1`
                    endif
                end
                echo "$n_hf $i_hf"
                if ($n_hf == $i_hf) then
                    echo "# all hacked file ready"
                    set allReady = 1
                    # Copy all hacked file
                    foreach hf (`cat $source_dir/data/$f`)
                        set fileName = `echo $hf | sed 's/\// /g' | awk '{print $NF}'`
                        echo "$hf $fileName"
                        if (-e data/$fileName) then
                            cp -rf $hf data/
                        endif
                        if (-e cmds/$fileName) then
                            cp -rf $hf cmds/
                        endif
                        set n_tune = `echo $hf | grep "/tune/" | wc -w` 
                        if ($n_tune > 0) then
                            set target = `echo $hf | sed 's/\// /g' | awk '{print $(NF-1)}'`
                            if (-e tune/$target) then
                                cp $hf tune/$target/
                            else
                                mkdir -p tune/$target
                                cp -rf $hf tune/$target
                            endif
                        endif

                        if (-e data/sdc/$fileName) then
                            cp -rf $hf  data/sdc/
                        endif
                    end
                    echo $rd >> $source_dir/data/$tag.runDirFiles.progress
                    # which target rerun?
                endif
            endif
        end
    cd $source_dir
    endif
end

########################################
# check target error and perform action
#########################################
set used_params = 0
set used_controls = 0
set used_p4 = 0
cat $source_dir/runDir.list | sort -u
set maxRetrace = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "maxRetrace,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set monitorDuration = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "monitorDuration,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set monitorValidDays = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "monitorValidDays,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_maxRetrace = `echo $maxRetrace | wc -w`
if ($n_maxRetrace == 0) then
    set maxRetrace = 2
endif
set n_monitorDuration = `echo $monitorDuration | wc -w`
if ($n_monitorDuration == 0) then
    set monitorDuration = 5
endif
set n_monitorValidDays = `echo $monitorValidDays | wc -w`
if ($n_monitorValidDays == 0) then
    set monitorValidDays = 30
endif
foreach dir (` cat $source_dir/runDir.list | sort -u`)
    echo $dir
    cd $dir
    if (-e override.params) then
        set file_life = `python3 $source_dir/script/get_file_life.py --f override.params`
        if ($file_life > $monitorValidDays) then
            echo "# override.params of $dir has been created over $file_life days, skip monitor."
            continue
        endif
    else
        continue
    endif
    if (-e stop_vto_monitor) then
        echo "skip $dir due to seeing stop_vto_monitor"
        continue
    endif
    if (-e data/flow.xml) then
    else
        echo "skip $dir due to missing data/flow.xml"
        continue
    endif

    if ($vto_debug == 0) then
        source $source_dir/script/exec_monitor_dir.csh | tee exec_monitor.log &
    else
        source $source_dir/script/exec_monitor_dir.csh | tee exec_monitor.log &
    endif
    
end
cd $source_dir
echo "# wait for monitor per dir finish for 180s"
sleep 180

###################################
# Extract status for retrival
# ##################################
# every 2 hours extraction int($4/2)
source script/env.csh
set project = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "project," | awk -F "," '{print $2}' | sed 's/\r//g'`
set current_hour = `date | sed 's/:/ /g' | awk '{print int($4/2)}'`
if (-e data/record_status) then
    set n_record = `cat data/record_status`
    echo "$current_hour $n_record"
    if ($current_hour == $n_record) then
    else
        echo "$current_hour" > data/record_status
        #### each function can define each extract_status.csh
        if (-e $source_dir/script/extract_status.csh) then
            source $source_dir/script/extract_status.csh
        endif
    endif
else
    echo "0" > data/record_status
endif
source $source_dir/script/check_csv.csh
cd $source_dir
############################
# Report flow issue
# ####################
source $source_dir/script/report_flowIssue_core.csh >& report_flowIssue_core.log
cd $source_dir
##################
# Report run Progress
# ###############
source $source_dir/script/report_runProgress_core.csh >& report_runProgress_core.log
##################
# Report pending issue
# ################
set pendingTime = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "pendingTime," | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_pendingTime = `echo $pendingTime | wc -w`
if ($n_pendingTime == 0) then
    set pendingTime = 2
endif


cd $source_dir
if (-e vtoMonitor.lock) then   
    rm vtoMonitor.lock
endif
