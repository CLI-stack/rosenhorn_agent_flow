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
set tile = $1
set runDir = $2
set refDir = $3
set integer = $4
set unit = $5
set repeat = $6
set tag = $7
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`
set targets = "BuildTechDir FxGenProcessLabelMap GenerateAllCommands FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower FxPostFloorPlan FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxOptCts FxIncrProuteOptCts FxRoute FxOptRoute FxReRoute FxStreamOut" 
source csh/env.csh
set activeRunDir = ""
touch $source_dir/data/${tag}_spec
set n_repeat = `echo $repeat | sed 's/:/ /g' | sed 's/repeat//g' | wc -w`
set n_integer = `echo $integer | sed 's/:/ /g' | sed 's/integer//g' | wc -w`
set n_unit = `echo $unit | sed 's/:/ /g' | sed 's/unit//g' | wc -w`
echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`

set tile_filter = ""
if ($n_tile > 0) then
    foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
        set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
        set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
        if ($n_rd_tile == 0) then
        else
            set tile_filter = "$tile_filter $t"
        endif
    end
    set tile = "$tile_filter"
else
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif
set n_tile_filter = `echo $tile_filter | wc -w`
if ($n_tile_filter == 0 && $n_tile > 0) then
    echo "I don't own $tile or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif


cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The run progress for $tile is following:
EOF
set table_used = 0
echo "You can check in browser: $source_dir/data/${tag}_spec.html" >> $source_dir/data/${tag}_spec
echo "Slide: $source_dir/data/${tag}/run_prgress.pptx" >> $source_dir/data/${tag}_spec
set run_time = "NA"
set n_table = 0
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
                    if (-e $target.runtime.log ) then
                        set run_time = "$run_time (exceed 2X expected)"
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
set eff_rd = ""
if ($n_refDir > 0) then
    echo "#table#" >> $source_dir/data/${tag}_spec
    echo "Tile,Finished,Running,runTime(hour),Failed,isMonitored,runDir" >> $source_dir/data/${tag}_spec
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        # Identify if it is run dir
        if (-e $rd/tile.params) then
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set eff_rd = "$eff_rd $rd"
        else
        # Identify if it is dir with all run dir link
            foreach lrd (`ls -1d $rd/*`)
                if (-e $lrd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $lrd/tile.params | grep -v "#" | awk '{print $3}'`
                    set eff_rd = "$eff_rd $lrd"
                endif
            end
        endif
    end

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
                if (-e $target.runtime.log ) then
                    set run_time = "$run_time (exceed 2X expected)"
                endif
                echo "$t,$finishedTarget,$runningTarget,$run_time,$failed_target,$isMonitored,$rd" >> $source_dir/data/${tag}_spec
            endif
        end
    endif
    cd $source_dir
end
python $source_dir/py/report_runProgress.py --tag $tag --tasksModelFile $tasksModelFile --item 'runDir'
if (-e data/$tag/report_runProgress) then
    set n_runProgress = `cat data/$tag/report_runProgress | wc -w`
    if ($n_runProgress == 0) then
        echo "# No run dir in agent"
        if ($n_refDir > 0) then
            foreach rd (`echo $eff_rd`) 
                echo "${tag}:${rd}" >> data/$tag/report_runProgress
            endif
        endif
    endif
endif
set t = "NA"
set pre_t = "NA"
echo "#table#" >> $source_dir/data/${tag}_spec
echo "Tag,Tile,Finished,Running,runTime(hour),Failed,isMonitored,description,runDir" >> $source_dir/data/${tag}_spec
echo "#title#" > $source_dir/data/${tag}/pptx.spec
echo "Run Progress" >> $source_dir/data/${tag}/pptx.spec
echo "#table#" >> $source_dir/data/${tag}/pptx.spec
echo "Tile|Finished Target"  >> $source_dir/data/${tag}/pptx.spec
set n_line_slide = 0
foreach trd (`cat $source_dir/data/$tag/report_runProgress`)
    if ( $table_used == 1) then
        continue
    endif
    set t = `echo $trd | awk -F ":" '{print $1}'`
    set rd = `echo $trd | awk -F ":" '{print $2}'`
    set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_rd_tile = `echo $tile | grep $rd_tile | wc -l`
    #set n_rd_tile = 1
    echo "$tile | $rd_tile | $n_rd_tile"
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
        if ($n_refDir > 0) then
            set rd = `echo $rd | sed 's/\/$//g'`
            set is_ref = `echo $eff_rd | grep $rd | wc -w`
            echo "$rd | $refDir | $is_ref"

            if ($is_ref > 0) then
            else
                continue
            endif
        endif
        set n = 0
        set finishedTarget = "NA"
        set latestTarget = ""
        set runningTarget = ""
        #set failed_target = `zgrep " Output dependency file" logs/*.log.gz | sed 's/:/ /g' | grep -v rde.txt | awk '{print $1}' | sort -u`
        set failed_target = `ls *.failed | sort -k 1 | sed 's/$/;/g'`
        set error_target = `ls *.error.log | sort -k 1 | sed 's/$/;/g'`
        set failed_target = "$failed_target $error_target"
        set n_shutdown = 0
        if (-e stats.log) then
            set n_shutdown = `grep "Server owner" stats.log | grep "not running" | wc -w`
        endif

        set n_source_target  = `grep ShGetSceData data/flow.xml | wc -w`
        if ($n_source_target > 0) then
            set source_target = "ShGetEcoSceData"
        endif
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
        TileBuilderTerm --localterm -x "TileBuilderShow -o tbs.log"
        if (-e tbs.log) then
        else
            echo "# TileBuilderShow version too old to generate tbs.log"
            cd ../../../../TileBuilder/
            p4 sync //depot/tools/aticad/1.0/flow/TileBuilder/lib/TileBuilderShow/TileBuilderShow.py#10
            cd -
            TileBuilderTerm --localterm -x "TileBuilderShow -o tbs.log"
        endif

        if (-e tbs.log) then
            cat tbs.log
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
            set maito_adress = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "mailto,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
            set vto = `cat  $source_dir/assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
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
        set lk = `resolve ./`
        echo "# generate tile status."
        if (-e tile_status) then
            rm -rf tile_status
            mkdir tile_status
            cd tile_status
        else
            mkdir tile_status
            cd tile_status
        endif
        if (-e $lk) then
            unlink $lk
            ln -s $lk
        else
            ln -s $lk
        endif
        set project = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "project," | awk -F "," '{print $2}' | sed 's/\r//g'`
        source $source_dir/script/env.csh
        deactivate
        if (-e $source_dir/script/project/$project/config.pm) then
            cp -rf $source_dir/script/project/$project/config.pm ./
        endif

        if (-e $source_dir/script/project/$project/gen_data.pl) then
            #perl $source_dir/script/project/$project/gen_data.pl
        else
            #perl /tools/aticad/1.0/src/zoo/safeng/SARA/gen_data.pl
        endif
        #ln -s index.html tile_status.html
        set tile_status = "$rd/tile_status/tile_status.html"
        set isMonitored = "$isMonitored ; $tile_status"
        cd $rd
        if (-e run_disk_usage) then
            set run_disk_usage = `cat run_disk_usage | tail -n 1 | awk '{print $1}'`
            set isMonitored = "$isMonitored ; $run_disk_usage"
            du -sh ./ >> run_disk_usage &
            echo "# found run disk usage"
        else
            du -sh ./ > run_disk_usage &
            echo "# genenerate run disk usage"
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
        if ($n_refDir > 0) then
            set rd = `echo $rd | sed 's/\/$//g'`
            set is_ref = `echo $eff_rd | grep $rd | wc -w`
            echo "$rd | $refDir | $is_ref"
            
            if ($is_ref > 0) then
                 set mailto = "mailto:$maito_adress?subject=vto clean run&body=Hi $vto %0A could you clean run %0A $rd"
                set vto_open_FpPlaceMacros = "mailto:$maito_adress?subject=vto open FpPlaceMacros &body=Hi $vto %0A could you open nlib data/FpPlaceMacros.nlib %0A $rd"
                set vto_open_PostFloorplan = "mailto:$maito_adress?subject=vto open PostFloorplan &body=Hi $vto %0A could you open nlib data/PostFloorPlan.nlib %0A $rd"
                set vto_open_ReRoute = "mailto:$maito_adress?subject=vto open ReRoute &body=Hi $vto %0A could you open nlib data/ReRoute.nlib %0A $rd"
                set rd = "$vto_open_FpPlaceMacros;$vto_open_PostFloorplan;$vto_open_ReRoute;$rd;$vto_clean_run"

                echo "$tinfo,$rd_tile,$finishedTarget,$runningTarget,$run_time,$failed_target,$isMonitored,$description,$rd" >> $source_dir/data/${tag}_spec
            endif
        else
            set mailto = "mailto:$maito_adress?subject=vto clean run&body=Hi $vto %0A could you clean run %0A $rd"
            set vto_open_FpPlaceMacros = "mailto:$maito_adress?subject=vto open FpPlaceMacros &body=Hi $vto %0A could you open nlib data/FpPlaceMacros.nlib %0A $rd"
            set vto_open_PostFloorplan = "mailto:$maito_adress?subject=vto open PostFloorplan &body=Hi $vto %0A could you open nlib data/PostFloorPlan.nlib %0A $rd"
            set vto_open_ReRoute = "mailto:$maito_adress?subject=vto open ReRoute &body=Hi $vto %0A could you open nlib data/ReRoute.nlib %0A $rd"
            set rd = "$vto_open_FpPlaceMacros;$vto_open_PostFloorplan;$vto_open_ReRoute;$rd;$vto_clean_run"
            echo "$tinfo,$rd_tile,$finishedTarget,$runningTarget,$run_time,$failed_target,$isMonitored,$description,$rd" >> $source_dir/data/${tag}_spec
        endif
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
echo "$n_repeat $n_integer $n_unit"
set repeat = `echo $repeat | sed 's/:/ /g' | sed 's/repeat//g' `
set integer = `echo $integer | sed 's/:/ /g' | sed 's/integer//g' `
set unit = `echo $unit | sed 's/:/ /g' | sed 's/unit//g'`
echo "$repeat $integer $unit"
if ($n_repeat > 0) then
    if ($n_integer > 0 && $n_unit > 0) then
        set run_status = "${repeat}:${integer}:${unit}"
    endif
    if ($n_integer == 0 && $n_unit > 0) then
        set run_status = "${repeat}:1:${unit}"
    endif

endif

cd $source_dir 
echo "#table end#" >> $source_dir/data/${tag}/pptx.spec
echo "#table end#" >> $source_dir/data/${tag}_spec
if ($n_refDir == 0 && $n_table == 0) then
    source $source_dir/script/env.csh
    python $source_dir/py/spec2Html.py --spec $source_dir/data/${tag}_spec --html $source_dir/report_runProgress_spec.html
endif
cp $source_dir/data/${tag}_spec $source_dir/data/$tag/${tag}_spec.orig
python3 $source_dir/script/remove_empty_table.py --i $source_dir/data/${tag}_spec --o $source_dir/data/$tag/${tag}_spec
cp $source_dir/data/$tag/${tag}_spec $source_dir/data/${tag}_spec
python $source_dir/py/spec2pptx.py --spec $source_dir/data/${tag}/pptx.spec --pptx $source_dir/data/${tag}/run_prgress.pptx
source csh/updateTask.csh
