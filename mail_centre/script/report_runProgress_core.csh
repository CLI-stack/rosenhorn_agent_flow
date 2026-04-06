# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set tag = "report_runProgress"
set tasksModelFile = "tasksModel.csv"
set targets = "BuildTechDir FxGenProcessLabelMap GenerateAllCommands FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower FxPostFloorPlan FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxOptCts FxIncrProuteOptCts FxRoute FxOptRoute FxReRoute FxStreamOut"
mkdir -p data/$tag
python3 $source_dir/py/report_runProgress.py --tag $tag --tasksModelFile $tasksModelFile --item 'runDir'
set t = "NA"
set pre_t = "NA"
echo "" > $source_dir/data/${tag}_spec
echo "#table#" >> $source_dir/data/${tag}_spec
echo "Tag,Tile,Finished,Running,runTime(hour),Failed,isMonitored,description,runDir" >> $source_dir/data/${tag}_spec
set function = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "function," | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_function = `echo $function | wc -w`
if (n_function == 0)  then
    set function = "tile"
endif
echo "#title#" > $source_dir/data/${tag}/pptx.spec
echo "Run Progress" >> $source_dir/data/${tag}/pptx.spec
echo "#table#" >> $source_dir/data/${tag}/pptx.spec
echo "Tile|Finished Target"  >> $source_dir/data/${tag}/pptx.spec
set n_line_slide = 0
set run_time = 0
foreach trd (`cat $source_dir/data/$tag/report_runProgress`)
    set t = `echo $trd | awk -F ":" '{print $1}'`
    set rd = `echo $trd | awk -F ":" '{print $2}'`
    set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_rd_tile = 1
    if ($n_rd_tile > 0) then
        if ($t != $pre_t) then
            if ($pre_t != "NA") then
                #echo "#table end#" >> $source_dir/data/${tag}_spec
                #echo " " >> $source_dir/data/${tag}_spec
                #echo "#table#" >> $source_dir/data/${tag}_spec
                #echo "Tag,Tile,Finished,Running,runTime(hour),Failed,isMonitored,description,runDir" >> $source_dir/data/${tag}_spec
            else
                #echo "#table#" >> $source_dir/data/${tag}_spec
                #echo "Tag,Tile,Finished,Running,runTime(hour),Failed,isMonitored,description,runDir" >> $source_dir/data/${tag}_spec
            endif
        endif

        cd $rd

        set n = 0
        set finishedTarget = "NA"
        set latestTarget = ""
        set runningTarget = ""
        set n_shutdown = 0
        if (-e stats.log) then
            set n_shutdown = `grep "Server owner" stats.log | grep "not running" | wc -w`
        endif
        #set failed_target = `zgrep " Output dependency file" logs/*.log.gz | sed 's/:/ /g' | grep -v rde.txt | awk '{print $1}' | sort -u`
        set failed_target = `ls *.failed | sort -k 1 | sed 's/$/;/g'`
        set error_target = `ls *.error.log | sort -k 1 | sed 's/$/;/g'`
        set failed_target = "$failed_target $error_target"
        
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
        if (-e tbs.log) then
            source $source_dir/script/env.csh
            deactivate
            python3  $source_dir/script/gen_console_spec.py --run_dir $rd
            source $source_dir/script/env.csh
            python $source_dir/script/spec2Html.py --spec console.spec --html console.html
            set runningTarget = ""
            set run_time = ""
            foreach target (`grep RUNNIN tbs.log | awk '{print $2}'`)
                set runningTarget = "$rd/logs/$target.log ; $runningTarget"
                set start_time = `head -n 1 logs/${target}.log | sed 's/:/ /g' | awk '{print $4,$5}'`
                set end_time = `ls -l logs/${target}.log | sed 's/:/ /g' | awk '{print $7,$8}'`
                set rt = `echo "$start_time $end_time" | awk '{print ($3-$1)*24 + $4-$2}' `
                set run_time = "$rt ; $run_time"
            end
            set failed_target = ""
            foreach target (`grep FAILED tbs.log | awk '{print $2}'`)
                set failed_target = "$rd/logs/$target.log.gz ; $failed_target"
            end
            

        endif
        if (-e logs/FxStreamOut.log.gz && -e  logs/ShGetDef.log.gz) then
            set time1 = `stat -c %Y logs/FxStreamOut.log.gz`
            set time2 = `stat -c %Y logs/ShGetDef.log.gz`
            set tot_runtime = `echo $time1 $time2 | awk '{printf "%.2f\n",($1-$2)/(24*3600)}'`
            set run_time = "$run_time;total runtime: $tot_runtime days" 
        endif
        set length_running = `echo $runningTarget | wc -w`
        if ($n_shutdown > 0) then
            set runningTarget = "Seras shutdown::#FF0000"
        else
            if ($length_running == 0) then
                set runningTarget = "NA"
            endif
        endif
        if (-e $rd/rpts/FxFpPlaceMacros/PlaceMacros.png) then
            set fp_map = "$rd/rpts/FxFpPlaceMacros/PlaceMacros.png"
        else
            set fp_map = ""
        endif
        set isMonitored = "start ; $fp_map ; $rd/console.html"
        if (-e stop_vto_monitor) then
            set isMonitored = "stop ; $fp_map ; $rd/console.html"
        endif
        set vto = `cat  $source_dir/assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
        set maito_adress = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "mailto,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
        set mailto = "mailto:$maito_adress?subject=show TB console&body=Hi $vto %0A could you show TB console %0A $rd"
        set isMonitored = "$isMonitored;$mailto" 
        if (-e $target.runtime.log ) then
            set run_time = "$run_time (exceed 2X expected)"
        endif
        if (-e tile.params) then
            set description = `grep "^DESCRIPTION" tile.params |  grep -v "#" |sed 's/,/./g'`
            set chip_release = `grep CHIP_RELEASE tile.params | grep -v "#"`
            set fp_pointer = `grep FLOORPLAN_POINTER tile.params | grep -v "#"`
            set description = "$fp_pointer;$description"
            set description = "$chip_release;$description"
            set mailto = "mailto:$maito_adress?subject=vto add note&body=Hi $vto %0A could you add note %0A $rd %0A DESCRIPTION ="
            set description = "$description;$mailto"
        else
            set description = ""
        endif

        if (-e $source_dir/data/$t/$t.log) then
            set tinfo = "$source_dir/data/$t/$t.log"
        else
            set tinfo = $t
        endif
        if (-e $source_dir/script/extract_status_dir.csh) then
        endif
        if (-e $rd/tile_status/tile_status.html) then
            set tile_status = "$rd/tile_status/tile_status.html"
            set isMonitored = "$isMonitored ; $tile_status"
        endif
        touch test_1G.log
        rm -rf *G.log
        if (-e run_disk_usage) then
            set run_disk_usage = `cat run_disk_usage | tail -n 1 | awk '{print $1}'`
            set isMonitored = "$isMonitored ; $run_disk_usage"
            du -sh ./ >> run_disk_usage &
        else
            du -sh ./ > run_disk_usage &
        endif

        set disk_usage = `df ./ | grep -v "Filesystem" | awk '{print int($4/1000000)"G"}'`
        df ./ > ${disk_usage}.log
        set isMonitored = "$isMonitored;$rd/${disk_usage}.log"
        cd $rd
        if (-e flow_issue.html) then
             set isMonitored = "$isMonitored;$rd/flow_issue.html"
        endif
        set n_eco = `ls DMSA_SF/eco/*.eco | wc -w`
        if ($n_eco > 0) then
            set isMonitored = "$isMonitored;DMSA eco"
        endif
        set vto_clean_run = "mailto:$maito_adress?subject=vto clean run&body=Hi $vto %0A could you clean run %0A $rd"
        set vto_open_FpPlaceMacros = "mailto:$maito_adress?subject=vto open FpPlaceMacros &body=Hi $vto %0A could you open nlib data/FpPlaceMacros.nlib %0A $rd"
        set vto_open_PostFloorplan = "mailto:$maito_adress?subject=vto open PostFloorplan &body=Hi $vto %0A could you open nlib data/PostFloorPlan.nlib %0A $rd"
        set vto_open_ReRoute = "mailto:$maito_adress?subject=vto open ReRoute &body=Hi $vto %0A could you open nlib data/ReRoute.nlib %0A $rd"

        set rd = "$vto_open_FpPlaceMacros;$vto_open_PostFloorplan;$vto_open_ReRoute;$rd;$vto_clean_run"
        echo "$tinfo,$rd_tile,$finishedTarget,$runningTarget,$run_time,$failed_target,$isMonitored,$description,$rd" >> $source_dir/data/${tag}_spec
        set pre_t = $t
        set n_line_slide = `expr $n_line_slide + 1`
        if ($n_line_slide > 14) then
            set n_line_slide = 0
            echo "#table end#" >> $source_dir/data/${tag}/pptx.spec
            echo "#title#" >> $source_dir/data/${tag}/pptx.spec
            echo "Run Progress" >> $source_dir/data/${tag}/pptx.spec
            echo "#table#" >> $source_dir/data/${tag}/pptx.spec
            echo "Tile|Finished Target" >> $source_dir/data/${tag}/pptx.spec
        endif

    echo "$rd_tile|$finishedTarget" >> $source_dir/data/${tag}/pptx.spec

    endif
end
cd $source_dir 
echo "#table end#" >> $source_dir/data/${tag}_spec
echo "#table end#" >> $source_dir/data/${tag}/pptx.spec
source $source_dir/script/env.csh
python $source_dir/py/spec2Html.py --spec $source_dir/data/${tag}_spec --html $source_dir/${tag}_spec.html
python $source_dir/py/spec2pptx.py --spec $source_dir/data/${tag}/pptx.spec --pptx $source_dir/data/${tag}/run_prgress.pptx
