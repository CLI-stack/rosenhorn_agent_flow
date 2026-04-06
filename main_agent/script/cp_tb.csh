# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set tag = $5
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
set diskUsage = 0
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec

set tile_filter = ""
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g' | wc -w`
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
if ($n_tile > 0) then
    foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g'`)
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

set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The run dir has been copied:
#table#
EOF

echo "tile,source_dir,copy_dir" >> $source_dir/data/${tag}_spec
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
set target_rd = ""
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
        else
            set target_rd = $rd
        endif
    end
else
    echo "# No run dir specify." >> >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif

## execute task and create finish file
set task = "TileBuilderCopy"
set task_file = ${task}_$tag
set n_target_rd = `echo $target_rd | wc -w`
foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set disks = `python3 $source_dir/script/assign_disk.py --csv $source_dir/assignment.csv --tile $t`
    foreach d (`echo $disks`)
        set temp = `df $d | grep -v Filesystem | awk '{print $4}'`
        if ($temp > $diskUsage) then
            set diskUsage = $temp
            set diskUsed = $d
        endif
    end
    set vto = `cat $source_dir/assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
    if ($n_target_rd > 0) then
        cd $target_rd
        if (-e $t) then
            cd $t
        else
            mkdir -p $t
            cd $t
        endif 
    else
        if (-e $diskUsed/$vto) then
            cd $diskUsed/$vto
            if (-e $t) then
                cd $t
            else
                mkdir -p $t
                cd $t
            endif
        else
            cd $diskUsed
            mkdir -p $diskUsed/$vto/$t
            cd $diskUsed/$vto/$t
        endif
    endif
    set dir = ${tag}
    mkdir $dir
    cd $rd
    TileBuilderCopy -f ./ -t $diskUsed/$vto/$t/$dir & 
    set orig_dir_name = `echo $rd |sed 's/\// /g' | awk '{print $NF}'`
    set copy_dir = `$diskUsed/$vto/$t/$dir/main/pd/tiles/${orig_dir_name}_copy`
    sleep 180
    if (-e $copy_dir) then
        echo "$t,$rd,$copy_dir" >> $source_dir/data/${tag}_spec
    endif
    
end

echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh

