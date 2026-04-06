# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
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
    The following run has been stopped
#table#
EOF
set refDir = `echo $refDir | sed 's/:/ /g' | awk '{$1="";print $0}'`
echo "$tile $refDir"
set run_status = "failed"
if ($tile == "tile") then
    set n_refDir = `echo $refDir | wc -w`
    echo "# No tile specity, use run dir $refDir $n_refDir"
    if ($n_refDir > 0) then
        echo "runDir" >> $source_dir/data/${tag}_spec
        foreach dir (`echo $refDir`)
            if (-e $dir) then
                cd $dir
                TileBuilderTerm -x "seras -shutdown"
                sleep 20
                set reply = "The run restopped\n"
                echo "$dir" >> $source_dir/data/${tag}_spec
                set run_status = "stopped"
                echo "$dir" >> $source_dir/data/${tag}_spec
                touch stop_vto_monitor
            else
                echo "$dir not exist" >> $source_dir/data/${tag}_spec
                set reply = "The run failed to stopped\n"
            endif
        end
        echo "#table end#" >> $source_dir/data/${tag}_spec
    else
        echo "dir not exist" >> $source_dir/data/${tag}_spec
        set reply = "The run failed to stopped\n"
    endif
else
    set rd_valid = 0
    echo "tile,runDir" >> $source_dir/data/${tag}_spec
    foreach t (`echo $tile | sed 's/:/ /g' | sed 's/tile //g'`)
        echo "# run for $t $runDir"
        set run_used = 0
        set n_runDir = `cat $runDir | wc -w`
        echo "$n_runDir"
        # check available run dir
        if ($n_runDir > 0) then
            foreach rd (`cat $runDir`)
                echo "# check $rd."
                set n_rd = `echo $rd | wc -w`
                if ($n_rd == 0) then
                    continue
                endif
                if ($rd_valid == 1) then
                    continue
                endif
                if (-e $rd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
                endif
                # found the matched tile run
                if ($t == $curr_tile) then
                    set run_used = 1
                    set rd_valid = $rd
                    cd $rd
                    TileBuilderTerm -x "seras -shutdown"
                    sleep 20
                    touch stop_vto_monitor
                    echo "$t,$rd" >> $source_dir/data/${tag}_spec
                    set reply = "The run stopped for $t\n"
                    set run_status = "stopped"
                endif
            end
        endif
        cd $source_dir
    end
    echo "#table end#" >> $source_dir/data/${tag}_spec
endif
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
