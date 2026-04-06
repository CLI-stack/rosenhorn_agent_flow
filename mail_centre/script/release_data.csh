set tile = $1
set runDir = $2
set refDir = $3
set stage = $4
set file = $5
set tag = $6
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
set targets = "FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower FxPostFloorPlan FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxOptCts FxIncrProuteOptCts FxRoute FxOptRoute FxReRoute FxStreamOut"

touch $source_dir/data/${tag}_spec
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


set n_stage = `echo $stage | sed 's/:/ /g' | sed 's/stage//g' | wc -w`

if ($n_stage == 0) then
    source csh/env.csh
    echo "#text#\
    No stage(pv_clean/fp_clean/floorplan/place/route/reroute) specified" >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif
set file = `echo $file | sed 's/^file//g' | sed 's/:/ /g'`

echo "$stage $n_tile $n_stage"
set stage = `echo $stage | sed 's/:/ /g' | sed 's/stage//g'`
touch release_${stage}_failed
rm release_${stage}_failed
echo $stage
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The $stage data release status is following:
#table#
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "Tile,runDir,finished,Status" >> $source_dir/data/${tag}_spec
set eff_rd = ""
set release_script = `cat assignment.csv | grep releaseScript | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
echo "$release_script"
set release_script = "source $release_script $stage > release.log"
if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        cd $rd
        touch release_data_$tag.started
        rm release_data_$tag.started
        touch release_info.txt
        rm release_info.txt
        set n_file = `echo $file | wc -w`
        if ($n_file > 0) then
            foreach f (`echo $file`)
                set a = `echo $f | sed 's/\// /g' | awk '{print $NF}'` 
                set f_dir = `echo $f | sed "s/$a//g"`
                mkdir -p $f_dir
                echo "# touch for release" > $f
                echo "# touch $f for release in $rd"
            end
        endif
        TileBuilderTerm -x  "$release_script;touch release_data_$tag.started"
        set eff_rd = "$eff_rd $rd"
            ## only release latest data
     end
endif
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_refDir > 0) then
        break
    endif
    cd $source_dir
    foreach rd (`cat $source_dir/$runDir`)
        set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($t == $curr_tile) then
            cd $rd
            set skip = 0
            if ($refDir == "refDir") then
            else
                foreach r (`echo $refDir | sed 's/:/ /g' | sed 's/refDir //g'`)
                    set r = `echo $r | sed 's/\/$//g'`
                    if ($r == "$rd") then
                        echo "# found match dir $r $rd"
                        set skip = 0
                    else
                        set skip = 1
                        echo "# not match $r $rd"
                    endif
                end
            endif
            if ($skip == 1) then
                continue
            endif
            touch release_data_$tag.started
            rm release_data_$tag.started
            touch release_info.txt
            rm release_info.txt
            set n_file = `echo $file | wc -w`
            if ($n_file > 0) then
                foreach f (`echo $file`)
                    set a = `echo $f | sed 's/\// /g' | awk '{print $NF}'` 
                    set f_dir = `echo $f | sed "s/$a//g"`
                    mkdir -p $f_dir
                    echo "# touch for release" > $f
                    echo "# touch $f for release in $rd"
                    touch $f
                end
            endif
            # Strange, "TileBuilderTerm -x " must add ";touch", otherwise the source script.csh cannot work
            TileBuilderTerm -x  "$release_script;touch release_data_$tag.started"
            set eff_rd = "$eff_rd $rd"
            break
        endif
    end
    cd $source_dir
end
echo "# Check if release  finished."
foreach rd (`echo $eff_rd`)
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

    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_wait = 0
    while(1)
        if (-e release_data_$tag.started) then
            set error = `egrep -i "ERROR|INVALID" release.log | sed 's/,/ /g'| sed 's/ /__/g'`
            set n_error = `echo "$error" | wc -w` 
            set release_pointer = `grep -i "Released to" release.log | awk '{print $3}'`
            set n_release_pointer = `echo $release_pointer | wc -w`
            if ($n_error == 0) then
                if ($n_release_pointer > 0) then
                    echo "$t,$rd,$finishedTarget,$release_pointer" >> $source_dir/data/${tag}_spec
                else
                    echo "$t,$rd,$finishedTarget,Error: no release pointer" >> $source_dir/data/${tag}_spec
                endif
            else
                set errors = ""
                foreach e (`echo "$error"`)
                    set errors = "$errors;$e"
                end
                echo "$t,$rd,$finishedTarget,$release_pointer;$errors" >> $source_dir/data/${tag}_spec
            endif
            break
        endif
        set n_wait = `expr $n_wait + 1`
        if ($n_wait > 1800) then
            echo "$t,$rd,$finishedTarget,release_data failed in 30 mins" >> $source_dir/data/${tag}_spec
            touch release_${stage}_failed
            break
        endif
        sleep 1

    end
end
cd $source_dir
echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
