# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set tag = $4
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`
set targets = "FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower FxPostFloorPlan FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxOptCts FxIncrProuteOptCts FxRoute FxOptRoute FxReRoute FxStreamOut" 
source csh/env.csh
set activeRunDir = ""
touch $source_dir/data/${tag}_spec
echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_tile > 0) then
        continue
    endif
    set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
    set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
    if ($n_rd_tile == 0) then
        echo "I don't own $t or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    endif
end

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The release status for $tile is following:
EOF
set table_used = 0
set run_time = "NA"
if (-e data/$tag.table) then
    set n_table = `cat data/$tag.table | wc -w`
    if ($n_table > 0) then
        echo "#table#" >> $source_dir/data/${tag}_spec
        echo "Tile,Finished,Running,runTime(hour),Failed,isMonitored,runDir" >> $source_dir/data/${tag}_spec
        echo "# Found table input."
        foreach sect (`cat  $source_dir/data/$tag.table | sed 's/|/ /g'`)
            set n_run_dir = `echo $sect | egrep "main/pd/tiles" | wc -w`
            if ($n_run_dir > 0) then
                if (-e $sect/tile.params) then
                    cd $sect
                    echo "# Found run dir $sect"
                    set t = `grep "TILES_TO_RUN" $sect/tile.params | grep -v "#" | awk '{print $3}'`
                    set n = 0
                    set finishedTarget = "NA"
                    set latestTarget = ""
                    set runningTarget = ""
                    set failed_target = `zgrep " Output dependency file" logs/*.log.gz | sed 's/:/ /g' | grep -v rde.txt | awk '{print $1}' | sort -u`
                    foreach target (`echo $targets`)
                        set run_status = "finished"
                        set length = `echo $finishedTarget | wc -w`
                        if (-e logs/${target}.log.gz) then
                            set n = `expr $n + 1`
                            set finishedTarget = $target
                            echo "$length $target $sect"
                            set latestTarget = $finishedTarget
                        endif
                        if (-e logs/${target}.log) then
                            set runningTarget = $target
                            set start_time = `head -n 1 logs/${target}.log | sed 's/:/ /g' | awk '{print $4,$5}'`
                            set end_time = `ls -l logs/${target}.log | sed 's/:/ /g' | awk '{print $7,$8}'`
                            set run_time = `echo "$start_time $end_time" | awk '{print ($3-$1)*24 + $4-$2}' `
                            echo "# Running target is $runningTarget"
                            set activeRunDir = $sect
                        endif
                    end
                    set length_running = `echo $runningTarget | wc -w`
                    if ($length_running == 0) then
                        set runningTarget = "NA"
                    endif
                    set isMonitored = "start"
                    if (-e stop_vto_monitor) then
                        set isMonitored = "stop"
                    endif
                    echo "$t,$finishedTarget,$runningTarget,$run_time,$failed_target,$isMonitored,$sect" >> $source_dir/data/${tag}_spec
                    set run_status = "finished"
                endif
            endif
        end
        set table_used = 1
        echo "#table end#" >> $source_dir/data/${tag}_spec
    endif
    cd $source_dir
endif


set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
if ($n_tile == 0 && $table_used == 0) then
    source csh/env.csh
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif


set refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`
set n_refDir = `echo $refDir | wc -w`
if ($n_refDir > 0) then
    echo "#table#" >> $source_dir/data/${tag}_spec
    echo "Tile,Finished,Running,runTime(hour),Failed,isMonitored,runDir" >> $source_dir/data/${tag}_spec
endif
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($table_used == 1) then
        continue
    endif
    if ($n_refDir > 0) then
        foreach rd (`echo $refDir`)
        echo $rd
            set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
    #echo "$rd_tile $tile"
            if ($rd_tile == $t) then
                cd $rd
                set n = 0
                set finishedTarget = "NA"
                set latestTarget = ""
                set runningTarget = ""
                set failed_target = `zgrep " Output dependency file" logs/*.log.gz | sed 's/:/ /g' | grep -v rde.txt | awk '{print $1}' | sort -u`
                foreach target (`echo $targets`)
                    set run_status = "finished"
            #echo "$target $rd"
                    set length = `echo $finishedTarget | wc -w`
                    if (-e logs/${target}.log.gz) then
                        set n = `expr $n + 1`
                        set finishedTarget = $target
                        echo "$length $target $rd"
                        set latestTarget = $finishedTarget
                    endif
                    if (-e logs/${target}.log) then
                        set runningTarget = $target
                        set start_time = `head -n 1 logs/${target}.log | sed 's/:/ /g' | awk '{print $4,$5}'`
                        set end_time = `ls -l logs/${target}.log | sed 's/:/ /g' | awk '{print $7,$8}'`
                        set run_time = `echo "$start_time $end_time" | awk '{print ($3-$1)*24 + $4-$2}' `
                        echo "# Running target is $runningTarget"
                        set activeRunDir = $rd
                    endif
                end
                set length_running = `echo $runningTarget | wc -w`
                if ($length_running == 0) then
                    set runningTarget = "NA"
                endif
                set isMonitored = "start"
                if (-e stop_vto_monitor) then
                    set isMonitored = "stop"
                endif
                echo "$t,$finishedTarget,$runningTarget,$run_time,$failed_target,$isMonitored,$rd" >> $source_dir/data/${tag}_spec
            endif
        end
    endif
    cd $source_dir
end
python $source_dir/py/report_runProgress.py --tag $tag --tasksModelFile $tasksModelFile --item 'runDir'
set t = "NA"
set pre_t = "NA"
foreach trd (`cat $source_dir/data/$tag/report_runProgress`)
    if ($n_refDir > 0 || $table_used == 1) then
        continue
    endif
    set t = `echo $trd | awk -F ":" '{print $1}'`
    set rd = `echo $trd | awk -F ":" '{print $2}'`
    if ($t != $pre_t) then
        if ($pre_t != "NA") then
            echo "#table end#" >> $source_dir/data/${tag}_spec
            echo " " >> $source_dir/data/${tag}_spec
            echo "#table#" >> $source_dir/data/${tag}_spec
            echo "Tag,Tile,Finished,Running,runTime(hour),Failed,isReleased,runDir" >> $source_dir/data/${tag}_spec
        else
            echo "#table#" >> $source_dir/data/${tag}_spec
            echo "Tag,Tile,Finished,Running,runTime(hour),Failed,isReleased,runDir" >> $source_dir/data/${tag}_spec
        endif
    endif
    set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_rd_tile = `echo $tile | grep $rd_tile | wc -l`
    set failed_released = ""
    if ($n_rd_tile > 0) then
        cd $rd
        if (-e release_info.txt) then
            set n_fail = `egrep fail release_info.txt | wc -w`
            if ($n_fail > 0) then
                set failed_released = `ls  release_*_failed`
            endif
        endif
        set n = 0
        set finishedTarget = "NA"
        set latestTarget = ""
        set runningTarget = ""
        set failed_target = `zgrep " Output dependency file" logs/*.log.gz | sed 's/:/ /g' | grep -v rde.txt | awk '{print $1}' | sort -u`
        foreach target (`echo $targets`)
            set run_status = "finished"
            #echo "$target $rd"
            set length = `echo $finishedTarget | wc -w`
            if (-e logs/${target}.log.gz) then
                set n = `expr $n + 1`
                set finishedTarget = $target
                echo "$length $target $rd"
                set latestTarget = $finishedTarget
            endif
            if (-e logs/${target}.log) then
                set runningTarget = $target
                set start_time = `head -n 1 logs/${target}.log | sed 's/:/ /g' | awk '{print $4,$5}'`
                set end_time = `ls -l logs/${target}.log | sed 's/:/ /g' | awk '{print $7,$8}'`
                set run_time = `echo "$start_time $end_time" | awk '{print ($3-$1)*24 + $4-$2}' `
                echo "# Running target is $runningTarget"
                set activeRunDir = $rd
            endif
        end
        set length_running = `echo $runningTarget | wc -w`
        if ($length_running == 0) then
            set runningTarget = "NA"
        endif
        set isMonitored = "start"
        if (-e stop_vto_monitor) then
            set isMonitored = "stop"
        endif
        echo "$t,$rd_tile,$finishedTarget,$runningTarget,$run_time,$failed_target,$failed_released,$rd" >> $source_dir/data/${tag}_spec
    endif
    set pre_t = $t
end

cd $source_dir 
echo "#table end#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
