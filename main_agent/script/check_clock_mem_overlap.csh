# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set tag = $4
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
if ($n_tile == 0) then
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The params has been generated:
#table#
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "Tile,runDir,Comment" >> $source_dir/data/${tag}_spec
set eff_rd = ""
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
     if ($n_refDir > 0) then
        foreach baseDir (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
            cd $baseDir
            touch checkClockMemOverlap_$tag.started
            rm checkClockMemOverlap_$tag.started
            TileBuilderTerm -x "TileBuilderIntFX -a /home/simchen/mi350/vto/write_tile_macro.tcl data/setup.nlib;touch checkClockMemOverlap_$tag.started"
            echo "$t,$rd, checkClockMemOverlap pass" >> >> $source_dir/data/${tag}_spec
            set eff_rd = "$eff_rd $rd"
        end
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
            touch checkClockMemOverlap_$tag.started
            rm checkClockMemOverlap_$tag.started
            TileBuilderTerm -x "TileBuilderIntFX -a /home/simchen/mi350/vto/write_tile_macro.tcl data/setup.nlib;touch checkClockMemOverlap_$tag.started"
            echo "$t,$rd, checkClockMemOverlap pass" >> >> $source_dir/data/${tag}_spec
            set eff_rd = "$eff_rd $rd"
            break
        endif
    end
    cd $source_dir
end
cd $source_dir
echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
