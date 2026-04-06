set tile = $1
set runDir = $2
set refDir = $3
set tag = $4
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The following run has been re-started
#list#
EOF
set tile_filter = ""
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
if ($n_tile > 0) then
    foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
        set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
        if ($n_rd_tile == 0) then
        else
            set tile_filter = "$tile_filter $t"
        endif
    end
    set tile = "$tile_filter"
else
    if ($n_refDir == 0) then
        set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
        echo "You don't specify any tiles or run dir, do you want to rerun for $tile_owned ? " >> $source_dir/data/${tag}_spec
        set run_status = "failed"
        exit
    endif
endif
set n_tile_filter = `echo $tile_filter | wc -w`
if ($n_tile_filter == 0 && $n_tile > 0) then
    echo "I don't own $tile or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif

set refDir = `echo $refDir | sed 's/:/ /g' | awk '{$1="";print $0}'`
echo "$tile $refDir"
set run_status = "failed"
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set eff_rd = ""

if ($n_refDir > 0) then
    foreach dir (`echo $refDir`)
        if (-e $dir) then
            cd $dir
            if (-e $dir/tile.params) then
                TileBuilderTerm -x "seras -shutdown;seras -start;touch seras_restart_$tag.started"
                set reply = "The run restarted\n"
                set run_status = "started"
                set eff_rd = "$eff_rd $dir"
            else
                echo "No tile.params,please check." >> $source_dir/data/${tag}_spec
            endif
        else
            echo "$dir not exist" >> $source_dir/data/${tag}_spec
            set reply = "The run failed to started\n"
        endif
    end
else
    echo "dir not exist" >> $source_dir/data/${tag}_spec
    set reply = "The run failed to started\n"
endif
    
set rd_valid = 0
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_refDir > 0) then
        continue
    endif
    cd $source_dir
    echo "# run for $t $runDir"
    set run_used = 0
    set n_runDir = `cat $runDir | wc -w`
    echo "$n_runDir"
    # check available run dir
    if ($n_runDir > 0) then
        foreach rd (`cat $source_dir/$runDir`)
            cd $rd
            #echo "# check $rd."
            set n_rd = `echo $rd | wc -w`
            if ($n_rd == 0) then
                continue
            endif
            if (-e $rd/tile.params) then
                set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            endif
            # found the matched tile run
            if ($t == $curr_tile) then
                set run_used = 1
                set current_dir = `pwd`
                echo "# Found matched dir: $current_dir"
                set rd_valid = $rd
                TileBuilderTerm -x "seras -shutdown;seras -start;touch seras_restart_$tag.started"
                set eff_rd = "$eff_rd $rd"
                set reply = "The run restarted for $t\n"
                set run_status = "started"
            endif
            cd  $source_dir
        end
    endif
end
cd $source_dir

foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set n_wait = 0
    while(1)
        if (-e seras_restart_$tag.started) then
            echo "$rd,seras_restart passed" >> $source_dir/data/${tag}_spec
            break
        endif
        set n_wait = `expr $n_wait + 1`
        if ($n_wait > 1800) then
            echo "$rd,seras_restart failed in 30 mins" >> $source_dir/data/${tag}_spec
            break
        endif
        sleep 1
    end
end

cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
