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
set refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`
set n_refDir = `echo $refDir | wc -w`
if ($n_refDir == 0) then
    source csh/env.csh
    echo "#text#\
    No link dir found" >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    set target_run_dir = ":"
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif


cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The  for $tile :
#table#
Tile,def,destDir
EOF
set table_used = 0
set run_time = "NA"
if (-e data/$tag.table) then
    set n_table = `cat data/$tag.table | wc -w`
    if ($n_table > 0) then
        echo "# Found table input."
        foreach sect (`cat  $source_dir/data/$tag.table | sed 's/|/ /g'`)
            set n_run_dir = `echo $sect | egrep "main/pd/tiles" | wc -w`
            if ($n_run_dir > 0) then
                if (-e $sect/tile.params) then
                    echo "# Found run dir $sect"
                    if (-e $refDir) then
                        cd $refDir
                        set t = `grep "TILES_TO_RUN" $sect/tile.params | grep -v "#" | awk '{print $3}'`
                        touch $sect/$tag.task
                        if (-e data/PostFloorPlan.def.gz) then
                            mkdir -p $refDir/$t
                            cp data/PostFloorPlan.def.gz $refDir/$t/${t}.def.gz
                            echo "$t,$sect/data/PostFloorPlan.def.gz,$refDir/$t" >> $source_dir/data/${tag}_spec
                        else
                            echo "$t,NA,NA" >> $source_dir/data/${tag}_spec
                        endif
                        set run_status = "finished"
                    endif
                endif
            endif
        end
        set table_used = 1
    endif
    cd $source_dir
endif

set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
if ($n_tile == 0 && $table_used == 0) then
    source csh/env.csh
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif


foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($table_used == 1) then
        continue
    endif
    set linked = 0
    foreach rd (`cat $source_dir/$runDir`)
        set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($rd_tile == $t) then
            if (-e data/PostFloorPlan.def.gz) then
                mkdir -p $refDir/$t
                cp data/PostFloorPlan.def.gz $refDir/$t/${t}.def.gz
                echo "$t,$sect/data/PostFloorPlan.def.gz,$refDir/$t" >> $source_dir/data/${tag}_spec
            else
                echo "$t,NA,NA" >> $source_dir/data/${tag}_spec
            endif

        endif
    end
    cd $source_dir
end
cd $source_dir 
echo "#table end#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
