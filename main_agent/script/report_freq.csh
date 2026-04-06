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
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
    set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
    if ($n_rd_tile == 0) then
        echo "I don't own $t or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    endif
end


set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
if ($n_tile == 0) then
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The clock frequency as following:
#table#
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "Tile,SDC,Frequency List,runDir" >> $source_dir/data/${tag}_spec
set eff_rd = ""
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
     if ($n_refDir > 0) then
        foreach baseDir (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
            cd $baseDir
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set n_sdc = `ls data/sdc/setup.FuncTT0p* | wc -w`
            if ($n_sdc > 0) then
                foreach sdc (`ls data/sdc/setup.FuncTT0p*`)
                    set freqs = ""
                    foreach freq (`grep create_clock $sdc | awk '{print $3,$5}' | grep -v virtual | sort -k 2 -g -r | awk '{print $1":"1/$2*1000"G"}' | tail -n 5`)
                        set freqs = "$freq;$freqs"
                    end
                    echo "$curr_tile,$sdc,$freqs,$baseDir"  >> $source_dir/data/${tag}_spec
                end
            endif
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
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set n_sdc = `ls data/sdc/setup.FuncTT0p* | wc -w`
            if ($n_sdc > 0) then
                foreach sdc (`ls data/sdc/setup.FuncTT0p*`)
                    set freqs = ""
                    foreach freq (`grep create_clock $sdc | awk '{print $3,$5}' | grep -v virtual | sort -k 2 -g -r | awk '{print $1":"1/$2*1000"G"}' | tail -n 5`)
                        set freqs = "$freq;$freqs"
                    end
                    echo "$curr_tile,$sdc,$freqs,$rd"  >> $source_dir/data/${tag}_spec
                end
            endif
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
