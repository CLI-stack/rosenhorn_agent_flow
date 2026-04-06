# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set regu = $5
set target = $6
set tag = $7
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
echo "$tile | $runDir | $refDir | $file | $regu | $tag"
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec

set tile_filter = ""
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
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


set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`
set n_regu = `echo $regu | sed 's/:/ /g' | sed 's/regu//g' | wc -w`
set n_target = `echo $target | sed 's/:/ /g' | sed 's/target//g' | wc -w`

if ($n_file == 0 && $n_regu == 0 && $n_target == 0) then
    source csh/env.csh
    echo "#text#\
    No cmds or target specified, will overwrite all cmds." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec

endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The cmds has been overwrited:
#table#
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "Tile,runDir,Comment" >> $source_dir/data/${tag}_spec
set eff_rd = ""
echo "# n_refDir $n_refDir"
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
     if ($n_refDir > 0) then
        echo "# Found refDir $refDir"
        foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
            cd $rd
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            if ($t == $curr_tile) then
            else
                continue
                echo "# $t $curr_tile"
            endif
            set eff_rd = "$eff_rd $rd"
        end
        continue 
    endif
    cd $source_dir
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
            set eff_rd = "$eff_rd $rd"
        endif
    end
    cd $source_dir
end

foreach rd (`echo $eff_rd`)
    cd $rd
    touch TileBuilderOverwriteCommand_$tag.started
    rm TileBuilderOverwriteCommand_$tag.started
     
    if ($n_file > 0) then
        foreach f (`echo $file | sed 's/:/ /g' | sed 's/file//g'`)
            TileBuilderTerm -x "TileBuilderOverwriteCommand $f ;touch TileBuilderOverwriteCommand_$tag.started;sleep 20"
            echo "# TileBuilderOverwriteCommand $f "
        end
    endif

    if ($n_target > 0) then
        foreach tg (`echo $target | sed 's/:/ /g' | sed 's/target//g'`)
            TileBuilderTerm -x "TileBuilderOverwriteCommand $tg ;touch TileBuilderOverwriteCommand_$tag.started"
            echo "# TileBuilderOverwriteCommand $tg"
        end

    endif

    if ($n_regu > 0) then
        echo "TileBuilderOverwriteCommand $regu ;touch TileBuilderOverwriteCommand_$tag.started" > $source_dir/data/${tag}/tb_overwrite.csh
        sed -i 's/^/TileBuilderTerm -x "/g'  $source_dir/data/${tag}/tb_overwrite.csh
        sed -i 's/$/"/g'  $source_dir/data/${tag}/tb_overwrite.csh
                #echo "TileBuilderTerm -x \"TileBuilderOverwriteCommand $regu ;touch TileBuilderOverwriteCommand_$tag.started\"" > $source_dir/data/${tag}/tb_overwrite.csh
        sed -i 's/__/\*/g' $source_dir/data/${tag}/tb_overwrite.csh
        sed -i 's/regu://g' $source_dir/data/${tag}/tb_overwrite.csh
        source $source_dir/data/${tag}/tb_overwrite.csh
    endif
    if ($n_file == 0 && $n_regu == 0 && $n_target == 0) then
        TileBuilderTerm -x "TileBuilderOverwriteCommand $f ;touch TileBuilderOverwriteCommand_$tag.started"
    endif

end


echo "# Check if TileBuilderOverwriteCommand finished."
foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_wait = 0
    while(1)
        if (-e TileBuilderOverwriteCommand_$tag.started) then
            echo "$t,$rd,TileBuilderOverwriteCommand passed" >> $source_dir/data/${tag}_spec
            break
        endif
        set n_wait = `expr $n_wait + 1`
        if ($n_wait > 1800) then
            echo "$t,$rd,TileBuilderOverwriteCommand failed in 30 mins" >> $source_dir/data/${tag}_spec
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
