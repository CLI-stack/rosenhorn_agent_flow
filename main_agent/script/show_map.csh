set tile = $1
set runDir = $2
set refDir = $3
set stage = $4
set file = $5
set tag = $6
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec
echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
    set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
    if ($n_rd_tile == 0) then
        echo "I don't own $t or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    endif
end

set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set n_stage = `echo $stage | sed 's/:/ /g' | sed 's/stage//g' | wc -w`
set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`

if ($n_stage == 0 && $n_file == 0) then
    source csh/env.csh
    echo "No stage(pv_clean/fp_clean/floorplan/place/route/reroute) specified" >> $source_dir/data/${tag}_spec
    echo "No png specified" >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

if ($n_tile == 0) then
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif
set imgs = ""
if ($n_file > 0) then
    set imgs = `echo $file | sed 's/:/ /g' | sed 's/file//g'`
else
    if ($stage == "stage:floorplan") then
        if (-e rpts/FxFpPlaceMacros/check_row_placement.png) then
            set imgs = "rpts/FxFpPlaceMacros/check_row_placement.png" 
        else
            set imgs = "rpts/FxFpPlaceMacros/PlaceMacros.png"
        endif
    endif
    if ($stage == "stage:place") then
        set imgs = "rpts/FxPixPlace/utilization.png rpts/FxPixPlace/congestion.png"
    endif

    if ($stage == "stage:route") then
        set imgs = "rpts/FxPixRoute/utilization.png rpts/FxPixRoute/violations.png"
    endif
endif

if ($stage == "stage:reroute") then
    set imgs = "rpts/FxPixReRoute/utilization.png rpts/FxPixReRoute/violations.png"
endif

cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The $stage map is following:
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set eff_rd = ""
set release_script = `cat assignment.csv | grep release | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
set release_script = "$release_script -$stage"
if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        set eff_rd = "$eff_rd $rd"
    end
endif
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_refDir > 0) then
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
            cd $rd
        endif
    end
    cd $source_dir
end

foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    echo "#list#" >> $source_dir/data/${tag}_spec
    echo "# check $imgs"
    foreach img (`echo $imgs`)
        if (-e $img) then
            echo "$t : https://logviewer-atl.amd.com/$rd/$img" >> $source_dir/data/${tag}_spec
            echo "#img#" >>  $source_dir/data/${tag}_spec
            echo "https://logviewer-atl.amd.com/$rd/$img" >> $source_dir/data/${tag}_spec
        endif
    end

end


cd $source_dir
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
