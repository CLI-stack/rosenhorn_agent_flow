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
    The vto monitor has been started for $tile :
#table#
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "Tile,runDir,Comment" >> $source_dir/data/${tag}_spec
set eff_rd = ""
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
     if ($n_refDir > 0) then
        foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
            cd $rd
            if (-e stop_vto_monitor) then
                rm -rf stop_vto_monitor
            endif
            echo "$t,$rd,start_vto_monitor pass" >> $source_dir/data/${tag}_spec
            set eff_rd = "$eff_rd $rd"
        end
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
            if (-e stop_vto_monitor) then
                rm -rf stop_vto_monitor
            endif
            echo "$t,$rd,start_vto_monitor pass" >> $source_dir/data/${tag}_spec
            set eff_rd = "$eff_rd $rd"
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
