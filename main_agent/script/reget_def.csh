# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set target = $4
set tag = $5
set target = "ShGetDef"
echo "# Finished params $target $tag"
set source_dir = `pwd`
touch  $source_dir/data/${tag}_spec
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


set targets = "ShGetMacroLists BuildTechDir GetNetlist ShGetATPG GetSdc FxGenProcessLabelMap GenerateAllCommands FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower FxPostFloorPlan FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxOptCts FxIncrProuteOptCts FxRoute FxGenRouteFill FxOptRoute FxReRoute FxStreamOut"
set n_target = `echo $target | sed 's/:/ /g' | sed 's/target//g' | wc -w`
if ($n_target == 0) then
    source csh/env.csh
    echo "#text#\
    No target specified." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The $target has been rerun at:
EOF

set target_run_dir = ":"
set reply = ""
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,runDir,status" >> $source_dir/data/${tag}_spec
#set runDir = `cat $runDir | sed 's/:/ /g' | awk '{print $2}'`
set target_orig = $target
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    foreach target (`echo $target_orig | sed 's/:/ /g' | sed 's/target//g' `)
        echo "# check $t refDir:$n_refDir"
        set run_used = 0
        if ($n_refDir > 0) then
            foreach  baseDir (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
                set curr_tile = `grep TILES_TO_RUN $baseDir/tile.params | grep -v "#" | awk '{print $3}'`
                echo "# check curr_tile"
                if ($t == $curr_tile) then
                    echo "$t $baseDir"
                    cd $baseDir
                    touch $tag.task
                    set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
                    touch rerun_$tag.started
                    rm rerun_$tag.started
                    echo "### $curr_dir $target $tag"
                    # unskip target
                    TileBuilderTerm -x "serascmd -find_jobs "status==RUNNING dir=~$curr_dir" --action stop;"
                    sleep 10
                    TileBuilderTerm -x "serascmd -find_jobs "name=~$target dir=~$curr_dir" --action unskip;"
                    TileBuilderTerm -x "serascmd -find_jobs "name=~$target dir=~$curr_dir" --action reset"
                    if (-e $target.reported) then
                        rm $target.reported
                    endif
                    if (-e logs/$target.log.gz) then
                        rm logs/$target.log.gz
                    endif
                    set cmd = ""
                    # Reset downcone targets
                    foreach tg (` python $source_dir/script/parseFlowXml.py --xml data/flow.xml --direction downcone --target $target`)
                        echo "# Reset $tg"
                        set cmd = "$cmd;serascmd -find_jobs name=~$tg --action unskip"
                        set cmd = "$cmd;serascmd -find_jobs name=~$tg --action reset"
                        if (-e logs/$tg.log.gz) then
                            rm logs/$tg.log.gz
                        endif
                        if (-e logs/$tg.log) then
                            rm logs/$tg.log
                        endif
                        if (-e $tg.reported) then
                            rm $tg.reported
                        endif
                        if (-e $tg.failed) then
                            rm $tg.failed*
                        endif
                        if (-e $tg.error.log) then
                            rm $tg.error.log*
                        endif
                    end
                    TileBuilderTerm -x "$cmd"
                    TileBuilderTerm -x "serascmd -find_jobs "status==NOTRUN dir=~$curr_dir" --action run;touch rerun_$tag.started"
                    if (-e logs/FxStreamOut.log.gz) then
                        rm logs/FxStreamOut.log.gz
                    endif
                    set n_wait = 0
                    while(1)
                        sleep 1
                        echo "# wait for rerun"
                        if (-e rerun_$tag.started) then
                            break
                        endif
                        set n_wait = `expr $n_wait + 1`
                        if ($n_wait > 1200) then
                            echo "$t,$baseDir,$target failed in 20 mins" >> $source_dir/data/${tag}_spec
                            break
                        endif
                    end
                    set run_status = "started"
                    echo "$t,$baseDir,$target pass" >> $source_dir/data/${tag}_spec
                    set reply = "Success"
                    set run_used = 1
                    #echo "### $tag $run_status $reply ${target_run_dir} $source_dir $run_used"
                endif
                echo "# finish rerun" 
            end
        endif
        echo "## $runDir"
        cd $source_dir
        foreach rd (`cat $runDir`)
            echo "# check $rd"
            if ($n_refDir > 0 ) then
                continue
            endif
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            if ($t == $curr_tile) then
                cd $rd
                touch $tag.task
                set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
                touch rerun_$tag.started
                rm rerun_$tag.started
                echo "$curr_dir $target $tag"
                TileBuilderTerm -x "serascmd -find_jobs "status==RUNNING dir=~$curr_dir" --action stop;"
                sleep 20
                set rerun_flag = 0
                TileBuilderTerm -x "serascmd -find_jobs "name=~$target dir=~$curr_dir" --action unskip;"
                TileBuilderTerm -x "serascmd -find_jobs "name=~$target dir=~$curr_dir" --action reset"
                # Reset downcone targets
                #TileBuilderTerm -localterm
                #TileBuilderTerm -x "serascmd -find_jobs "name=~$target" --report downstream_jobs | xargs serascmd --action reset --jobs"
                set cmd = ""
                if (-e $target.reported) then
                    rm $target.reported
                endif
                if (-e logs/$target.log.gz) then
                    rm logs/$target.log.gz
                endif

                foreach tg (` python $source_dir/script/parseFlowXml.py --xml data/flow.xml --direction downcone --target $target`)
                    echo "# Reset $tg"
                    set cmd = "$cmd;serascmd -find_jobs name=~$tg --action unskip"
                    set cmd = "$cmd;serascmd -find_jobs name=~$tg --action reset"
                    if (-e logs/$tg.log.gz) then
                        rm logs/$tg.log.gz
                    endif
                    if (-e logs/$tg.log) then
                        rm logs/$tg.log
                    endif
                    if (-e $tg.reported) then
                        rm $tg.reported
                    endif
                    if (-e $tg.failed) then
                        rm $tg.failed*
                    endif
                    if (-e $tg.error.log) then
                        rm $tg.error.log*
                    endif

                end
                TileBuilderTerm -x "$cmd"
                echo "# wait 180s for all targets reset"
                sleep 180
                TileBuilderTerm -x "serascmd -find_jobs "status==NOTRUN dir=~$curr_dir" --action run;touch rerun_$tag.started" 
                if (-e logs/FxStreamOut.log.gz) then
                    rm logs/FxStreamOut.log.gz
                endif
                set n_wait = 0
                while(1)
                    sleep 1
                    echo "# wait for rerun"
                    if (-e rerun_$tag.started) then
                        break
                    endif
                    set n_wait = `expr $n_wait + 1`
                    if ($n_wait > 1200) then
                        echo "$t,$rd,$target failed in 20 mins" >> $source_dir/data/${tag}_spec
                        break
                    endif

                end
                set run_status = "started"
                set run_dir = `resolve $rd`
                set target_run_dir = "${target_run_dir}:$run_dir"
                echo "$t,$rd,$target pass" >> $source_dir/data/${tag}_spec
                set reply = "Success"
                set run_used = 1
                #echo "### $tag $run_status $reply ${target_run_dir} $source_dir $run_used"
            endif
            if ($run_used == 1) then
                #echo "----- stop"
                #break
            endif
        end
        echo "# finish all"
    end
    cd $source_dir
end
echo "#table end#" >> $source_dir/data/${tag}_spec
source csh/env.csh
cd $source_dir
echo "#line#" >> ${tag}_spec
echo "#text#" >> ${tag}_spec
source csh/env.csh

source csh/updateTask.csh
