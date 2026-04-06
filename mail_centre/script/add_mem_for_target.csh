# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set target = $4
set integer = $5
set tag = $6
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec

set tile_filter = ""
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g' | wc -w`
if ($n_tile > 0) then
    foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g'`)
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

set n_target = `echo $target | sed 's/:/ /g' | sed 's/target//g' | wc -w`
set target = `echo $target | sed 's/:/ /g' | sed 's/target//g'`
if ($n_target == 0) then
    source csh/env.csh
    echo "#text#\
    No target specified." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

set n_integer = `echo $integer | sed 's/:/ /g' | sed 's/integer//g' | wc -w`
set integer = `echo $integer | sed 's/:/ /g' | sed 's/integer//g' | awk '{print $1}'`
if ($n_integer == 0) then
    source csh/env.csh
    echo "#text#\
    No mem specified." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

set target_orig = "$target"
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The $integer mem has been added for ${target}:
#table#
tile,runDir,status
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set eff_rd = ""
set n_table = 0
if (-e data/$tag.table) then
    set n_table = `cat data/$tag.table | wc -w`
    foreach sect (`cat  $source_dir/data/$tag.table | sed 's/|/ /g' | sort -u`)
        set n_run_dir = `echo $sect | egrep "main/pd/tiles" | wc -w`
        if ($n_run_dir > 0) then
            if (-e $sect/tile.params) then
                set eff_rd = "$eff_rd $sect"
                set n_table = 1
            endif
        endif
    end
endif

if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        # Identify if it is run dir
        if (-e $rd/tile.params) then
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set eff_rd = "$eff_rd $rd"
        else
        # Identify if it is dir with all run dir link
            foreach lrd (`ls -1d $rd/*`)
                if (-e $lrd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $lrd/tile.params | grep -v "#" | awk '{print $3}'`
                    set eff_rd = "$eff_rd $lrd"
                endif
            end
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
            cd $rd
        endif
    end
    cd $source_dir
end

## execute task and create finish file
set task = "TBgen"
set task_file = ${task}_$tag
foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    foreach target (`echo $target_orig | sed 's/:/ /g' | sed 's/target//g' `)
        echo "# check $t refDir:$rd"
        echo "TILEBUILDER_RAM_${target} = $integer" >> override.controls
        TileBuilderTerm -x "TileBuilderGenParams > TileBuilderGenParams_${tag}.log;touch $task_file"
    end
    
end

## wait for task finish
foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    source $source_dir/script/wait_file_finish.csh $task_file
end

set task = "TBmake"
set task_file = ${task}_$tag
foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    TileBuilderTerm -x "TileBuilderMake > TileBuilderMake_${tag}.log;touch $task_file"
end

## wait for task finish
foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    source $source_dir/script/wait_file_finish.csh $task_file
    foreach target (`echo $target_orig | sed 's/:/ /g' | sed 's/target//g' `)
         source $source_dir/script/rerun_target_core.csh $target &
         echo "$t,$rd,$target rerun pass" >> $source_dir/data/${tag}_spec

    end

end


echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh

