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
    The def and placeram.tcl have been submitted :
#table#
Tile,runDir,linkDir
EOF
set table_used = 0
set run_time = "NA"
set eff_rd = ""
set target_rd = ""
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
                        set def = ""
                        if (-e $sect/data/FpPlaceMacros.def.gz) then
                            set def = $sect/data/FpPlaceMacros.def.gz
                        endif
                        if (-e $sect/data/setup.def.gz) then
                            set def = $sect/data/setup.def.gz
                        endif
                        if (-e $sect/data/PostFloorPlan.def.gz) then
                            set def = $sect/data/PostFloorPlan.def.gz
                        endif

                        set n_def = `echo $def | wc -w`
                        if ($n_def > 0) then
                            cp $def $refDir/$t.def.gz
                            echo "$t,$sect,$refDir/$t.def.gz" >> $source_dir/data/${tag}_spec
                            set run_status = "finished"
                        endif
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

if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        if (-e $rd/tile.params) then
            set eff_rd = "$eff_rd $rd"
            echo "# Found source dir: $rd"
        else
            set target_rd = $rd
            echo "# Found target dir: $rd "
        endif
    end
endif

foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g'`)
    if ($n_refDir > 0 || $n_table > 0 ) then
        break
    endif
    foreach rd (`cat $runDir`)
        if (-e $rd) then
        else
            continue
        endif
        if (-e $rd/tile.params) then
        else
            continue
        endif
        set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($t == $curr_tile) then
            set eff_rd = "$eff_rd $rd"
        endif
    end
    cd $source_dir
end

foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    if (-e $rd/data/FpPlaceMacros.def.gz) then
        set def = "$rd/data/FpPlaceMacros.def.gz"
    endif
    if (-e $rd/data/setup.def.gz) then
        set def = "$rd/data/setup.def.gz"
    endif
    if (-e $rd/data/PostFloorPlan.def.gz) then
        set def = $rd/data/PostFloorPlan.def.gz
    endif
    set n_def = `echo $def | wc -w`
    echo "$t $rd $n_def $def"
    if ($n_def > 0) then
        cp $def $target_rd/$t.def.gz
        if (-e tune/FxFpPlaceMacros/FxFpPlaceMacros.placerams.tcl) then
            cp tune/FxFpPlaceMacros/FxFpPlaceMacros.placerams.tcl $target_rd/$t.placerams.tcl
            echo "$t,$rd,$target_rd/$t.placerams.tcl" >> $source_dir/data/${tag}_spec
        endif
        set run_status = "finished"
        echo "$t,$rd,$target_rd/$t.def.gz" >> $source_dir/data/${tag}_spec
        set linked = 1
    endif

end

cd $source_dir 
echo "#table end#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
