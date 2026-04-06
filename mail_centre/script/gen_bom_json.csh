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

cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The bom.json has been generated for $tile :
#table#
Tile,bom.json
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
                    cd $sect
                    echo "# Found run dir $sect"
                    /tool/aticad/1.0/flow/TileBuilder/common/bom_toolkit/TileBuilderBomGenerate.py -o bom.json
                     set t = `grep "TILES_TO_RUN" $sect/tile.params | grep -v "#" | awk '{print $3}'`
                    echo "$t,$sect/bom.json" >> $source_dir/data/${tag}_spec
                    set run_status = "finished"
                endif
            endif
        end
        set table_used = 1
    endif
    cd $source_dir
endif

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


set refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`
set n_refDir = `echo $refDir | wc -w`
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
                /tool/aticad/1.0/flow/TileBuilder/common/bom_toolkit/TileBuilderBomGenerate.py -o bom.json
                set run_status = "finished"
                echo "$t,$rd/bom.json" >> $source_dir/data/${tag}_spec
            endif
        end
    endif

    foreach rd (`cat $source_dir/$runDir`)
        if ($n_refDir > 0) then
            continue
        endif
        set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
    #echo "$rd_tile $tile"
        if ($rd_tile == $t) then
            cd $rd
            /tool/aticad/1.0/flow/TileBuilder/common/bom_toolkit/TileBuilderBomGenerate.py -o bom.json
            set run_status = "finished"
            echo "$t,$rd/bom.json" >> $source_dir/data/${tag}_spec
        endif
    end
    cd $source_dir
end
cd $source_dir 
echo "#table end#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
