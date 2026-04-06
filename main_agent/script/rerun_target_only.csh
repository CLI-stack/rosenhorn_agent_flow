# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set target = $4
set tag = $5
echo "# Finished params $target $tag"
set source_dir = `pwd`
touch  $source_dir/data/${tag}_spec
echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`

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


set n_target = `echo $target | sed 's/:/ /g' | sed 's/target//g' | wc -w`
if ($n_target == 0) then
    source csh/env.csh
    echo "#text#\
    No target specified." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The $target has been rerun only at:
EOF

set target_run_dir = ":"
set reply = ""
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,runDir,status" >> $source_dir/data/${tag}_spec
#set runDir = `cat $runDir | sed 's/:/ /g' | awk '{print $2}'`
set target_orig = $target
set eff_rd = ""
if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        set eff_rd = "$eff_rd $rd"
    end
endif

foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    foreach target (`echo $target_orig | sed 's/:/ /g' | sed 's/target//g' `)
        echo "# check $t refDir:$n_refDir"
        set run_used = 0
        echo "## $runDir"
        cd $source_dir
        foreach rd (`cat $runDir`)
            echo "# check $rd"
            if ($n_refDir > 0 ) then
                continue
            endif
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            if ($t == $curr_tile) then
                set eff_rd = "$eff_rd $rd"
            endif
            if ($run_used == 1) then
                #echo "----- stop"
                #break
            endif
        end
        echo "# finish all"
    end
    cd $source_dir
end
# perform instruction in effective run dir
foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
    touch rerun_$tag.started
    rm rerun_$tag.started
    echo "$curr_dir $target $tag"
    TileBuilderTerm -x "serascmd -find_jobs "dir=~$curr_dir" --action stop;"
    set rerun_flag = 0
    set cmd = ""
    if (-e $target.reported) then
        rm $target.reported
    endif
    set ids = ""
    foreach tg (`echo $target_orig | sed 's/:/ /g' | sed 's/target//g' `)
        echo "$curr_dir $tg $tag"
        set id = `grep $tg tbs.log | awk '{print $1}'`
        set ids = "$ids,$id"
        set rerun_flag = 0
    end
    set rerun_cmd = "serascmd --action rerun --jobs $ids;touch rerun_target_$tag.started"
    TileBuilderTerm -x $rerun_cmd

    if (-e logs/$target.log.gz) then
        echo "# remove logs/$target.log.gz"
        #rm logs/$target.log.gz
    endif

end
echo "# sleep 180"

foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_wait = 0
    while(1)
        if (-e rerun_target_$tag.started) then
            set run_status = "started"
            set run_dir = `resolve $rd`
            set target_run_dir = "${target_run_dir}:$run_dir"
            echo "$t,$rd,$target pass" >> $source_dir/data/${tag}_spec
            set reply = "Success"
            set run_used = 1

            break
        endif
        set n_wait = `expr $n_wait + 1`
        if ($n_wait > 3600) then
            break
        endif
        sleep 1
    end
end


echo "#table end#" >> $source_dir/data/${tag}_spec
cd $source_dir
echo "#line#" >> ${tag}_spec
echo "#text#" >> ${tag}_spec
source csh/env.csh

source csh/updateTask.csh
