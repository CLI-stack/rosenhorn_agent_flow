# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set tag = $4
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
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


cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The params has been updated:
#table#
tile,runDir,status
EOF
#set params = `resolve $params`
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set eff_rd = ""
if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        set eff_rd = "$eff_rd $rd"
        cd $rd
        foreach p (`cat $source_dir/data/$tag.params | awk '{print $1}'`)
            set n_p = `echo $p | wc -w`
            if ($n_p > 0) then
                sed -i "/$p/d" override.params
            endif
        end
        foreach p (`cat $source_dir/data/$tag.controls | awk '{print $1}'`)
            set n_p = `echo $p | wc -w`
            if ($n_p > 0) then
                echo "# remove $p in controls in $rd"
                sed -i "/$p/d" override.controls
            endif
        end
    end
endif

foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
     if ($n_refDir > 0) then
        break
    endif

    foreach rd (`cat $runDir`)
        set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($t == $curr_tile) then
            cd $rd
            set skip = 0
            if ($refDir == "refDir") then
                echo "# All dir need updated."
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
            foreach p (`cat $source_dir/data/$tag.params | awk '{print $1}'`)
                set n_p = `echo $p | wc -w`
                if ($n_p > 0) then
                    sed -i "/$p/d" override.params
                endif
                end
            foreach p (`cat $source_dir/data/$tag.controls | awk '{print $1}'`)
                set n_p = `echo $p | wc -w`
                if ($n_p > 0) then
                    echo "# remove $p in controls."
                    sed -i "/$p/d" override.controls
                endif
            end
            set eff_rd = "$eff_rd $rd"
        endif
    end
    cd $source_dir
end

# perform instruction in effective run dir
foreach rd (`echo $eff_rd`)
    cd $rd
    set n_params = `cat $source_dir/data/$tag.params | wc -w`
    set n_controls = `cat $source_dir/data/$tag.controls | wc -w`
    set update_params = ""
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    if ($n_params > 0) then
        set update_params = `cat $source_dir/data/$tag.params`
    endif
    if ($n_controls > 0) then
        set update_params = `cat $source_dir/data/$tag.controls`
    endif
    set n_update_params = `echo $update_params | sed 's/\r/ /g' | wc -w`
    if ($n_update_params == 0) then
        set n_update_params = "update params failed"
    endif
    echo "$t,$rd,$update_params" >> $source_dir/data/${tag}_spec
    touch TileBuilderGenParams_$tag.started
    rm TileBuilderGenParams_$tag.started
    TileBuilderTerm -x "TileBuilderGenParams;touch TileBuilderGenParams_$tag.started"
    touch $tag.task 
end


echo "# Check if TB gen finished."
foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_wait = 0
    while(1)
        if (-e TileBuilderGenParams_$tag.started) then
            break
        endif
        set n_wait = `expr $n_wait + 1`
        if ($n_wait > 3600) then
            break
        endif
        sleep 1
    end
end

set run_status = "started"
echo "#table end#" >> $source_dir/data/${tag}_spec
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
echo "## Finished update_params "
source csh/updateTask.csh
