# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set tag = $5
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set tile_filter = ""
set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`
set file = `echo $file | sed 's/:/ /g' | sed 's/file//g'`
if ($n_file == 0) then
    source csh/env.csh
    echo "#text#\
    No config file specified." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif


cat >> $source_dir/data/${tag}_spec << EOF
#list#
    Release pointer has been checked.
#table#
runDir,status
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
        set eff_rd = "$eff_rd $rd"
    end
endif

foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
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
set task = "check_clock_release_pointer"
set task_file = ${task}_$tag
cd $source_dir/data/$tag
/tools/aticad/1.0/src/zoo/rampage/sitour/CLOCK/flow/cmds/CES/check_release_pointer.py --config $file
echo "$source_dir/data/$tag,check_clock_release_pointer" >> $source_dir/data/${tag}_spec
cd $source_dir

echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"

cd $source_dir
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
