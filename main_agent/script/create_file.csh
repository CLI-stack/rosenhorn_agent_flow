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
    The file has been created:
#table#
EOF

if ($n_file > 0) then
    set file_used = `echo $file | sed 's/:/ /g' | sed 's/file//g' | awk '{print $1}'`
else
    echo "# file not specified"  >> $source_dir/data/${tag}_spec
    exit
endif


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
set target_dir = ""
if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        # Identify if it is run dir
        if (-e $rd/tile.params) then
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set eff_rd = "$eff_rd $rd"
        else
            set target_dir = $rd
        endif
    end
else
    echo "# No run dir specify." >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif

## execute task and create finish file
set task = "create file"
set task_file = ${task}_$tag
set n_target_dir = `echo $target_dir | wc -w`
set t_dir = ""
foreach rd (`echo $eff_rd`)
    cd $rd
    set full_name = `resolve $file_used`
    set dir = `dirname $full_name`
    if (-e $dir) then
        if (-e $full_name) then
            chmod 744 $full_name
        endif
        cat $source_dir/data/${tag}.table | sed "s/^|//g" | sed "s/||$//g" > $full_name
        echo "$full_name hass been created" >> $source_dir/data/${tag}_spec
    else
        mkdir -p $dir
        cat $source_dir/data/${tag}.table | sed "s/^|//g" | sed "s/||$//g" > $full_name
        echo "$full_name hass been created" >> $source_dir/data/${tag}_spec
    endif
end

echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh

