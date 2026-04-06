# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set tag = $3
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set runDirReply = ""
set target_run_dir = ""
echo "# report_runDir.csh $tile $runDir $tag "
touch $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_tile > 0) then
        continue
    endif
    set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
    set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
    if ($n_rd_tile == 0) then
        echo "I don't own $t or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    endif
end

if ($n_tile == 0) then
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif


cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The run dir is following:
EOF
set foundDir = 0
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,runDir,Params" >> $source_dir/data/${tag}_spec
if ($n_tile == 0) then
    foreach rd (`cat $runDir`)
        if (-e $rd/tile.params)  then
            set foundDir = 1
            #set params_part = `egrep -v "NICKNAME|TILES_TO_RUN" $rd/override.params|head -n 1`
            set t = `egrep  "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set params_part = `egrep  "DESCRIPTION" $rd/tile.params | grep -v "#" | head -n 1`
            echo "$t,$rd,$params_part" >> $source_dir/data/${tag}_spec
            set run_status = "finished"
        endif
    end
endif
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_tile == 0) then
        continue
    endif
    foreach rd (`cat $runDir`)
        if (-e $rd/tile.params)  then
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            echo "$t $curr_tile $rd"
            if ($t == $curr_tile) then
                #set params_part = `egrep -v "NICKNAME|TILES_TO_RUN" $rd/override.params|head -n 1`
                set params_part = `egrep  "DESCRIPTION" $rd/tile.params | grep -v "#" | head -n 1`
                echo "$t,$rd,$params_part" >> $source_dir/data/${tag}_spec 
                set runDirReply = "$runDirReply \n $rd"
                set foundDir = 1
                set run_status = "finished"
            endif
        endif
    end
end
echo "#table end#" >> $source_dir/data/${tag}_spec
if ($foundDir == 0) then
    echo "NA" >> $source_dir/data/${tag}_spec
endif
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
