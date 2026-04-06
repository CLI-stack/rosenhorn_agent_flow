set tile = $1
set runDir = $2
set refDir = $3
set tune = $4
set tag = $5
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set n_tune = `echo $tune | sed 's/:/ /g' | sed 's/tune//g' | wc -w`

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

if ($n_tune == 0) then
    echo "# No tune specified or tune not defined in arguement.csv." >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The commands has been removed from tune:
#table#
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "Tile,runDir,tune" >> $source_dir/data/${tag}_spec
set eff_rd = ""
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
    if (-e $source_dir/data/${tag}/tune) then
        set tunes = ""
        foreach tune (`ls -1d $source_dir/data/${tag}/tune/*`)
            echo "$tune"
            set target = `echo $tune | sed 's/\// /g' | awk '{print $NF}'`
            if (-e tune/$target) then
                foreach tcl (`ls $tune/*.tcl | awk -F "/" '{print $NF}' `)
                    echo "$target $tcl"
                    if (-e tune/$target/$tcl) then
                        set tunes = "$tunes;tune/$target/$tcl"
                        echo "#  remove $tcl tune/$target/$tcl"
                        python3 /home/simchen/aigc/remove_line.py --f1 tune/$target/$tcl --f2 $source_dir/data/${tag}/tune/$target/$tcl
                    endif
                end
            endif
        end
        echo "$t,$rd,$tunes" >>  $source_dir/data/${tag}_spec
    endif
end

cd $source_dir
echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
