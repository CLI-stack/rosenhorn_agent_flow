# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set tag = $4
echo "# Finished params"
set source_dir = `pwd`
echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
if (-e $source_dir/data/${tag}/set_tile.csh) then
    #source $source_dir/data/${tag}/set_tile.csh
endif
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
    echo "# Available tile : $tile_filter"
else
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif
set n_tile_filter = `echo $tile_filter | wc -w`
if ($n_tile_filter == 0 && $n_tile > 0) then
    echo "I don't own $tile or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif


echo "# Finish syntax"
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The environment has been updated:
#table#
Tile,runDir,Comment
EOF
    
set target_run_dir = ":"
set reply = ""
echo $tile | sed 's/^tile//g' | sed 's/:/ /g'

set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
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
            set eff_rd = "$eff_rd $rd"
        endif
    end
    cd $source_dir
end

set project = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "project," | awk -F "," '{print $2}' | sed 's/\r//g'`
foreach rd (`echo $eff_rd`)
    cd $rd
    touch SyncAllFlowEnvironment_$tag.started
    rm SyncAllFlowEnvironment_$tag.started
    set script = `resolve $source_dir/script/project/$project/sync_flow_env_core.csh`
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    echo "# Use $script"
    if (-e ../scripts/tile_flow/SyncAllFlowEnvironment.csh) then
        set env_script = `resolve ../scripts/tile_flow/SyncAllFlowEnvironment.csh`
        echo "# use $env_script"
        TileBuilderTerm -x "source $env_script;touch SyncAllFlowEnvironment_$tag.started"
    else if (-e $source_dir/script/project/$project/sync_flow_env_core.csh) then
            set env_script = "$source_dir/script/project/$project/sync_flow_env_core.csh"
            set n_env_script = `echo $env_script | wc -w`
            if ($n_env_script > 0) then
                echo "# use $env_script"
                TileBuilderTerm -x "source $source_dir/script/project/$project/sync_flow_env_core.csh;touch SyncAllFlowEnvironment_$tag.started"
            endif
        endif
    else
        echo "$t,$rd,script/project/$project/sync_flow_env_core.csh not set"
    endif
end

foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    if (-e ../scripts/tile_flow/SyncAllFlowEnvironment.csh)  then
        source $source_dir/script/wait_file_finish.csh SyncAllFlowEnvironment_$tag.started
        echo "$t,$rd,SyncAllFlowEnvironment pass" >> $source_dir/data/${tag}_spec
    else if (-e $source_dir/script/project/$project/sync_flow_env_core.csh) then
            set env_script = "$source_dir/script/project/$project/sync_flow_env_core.csh"
            set n_env_script = `echo $env_script | wc -w`
            if ($n_env_script > 0) then
                source $source_dir/script/wait_file_finish.csh SyncAllFlowEnvironment_$tag.started
                echo "$t,$rd,SyncAllFlowEnvironment pass" >> $source_dir/data/${tag}_spec
            endif
        endif
    else
        echo "$t,$rd,sync_env script not exist" >> $source_dir/data/${tag}_spec
    endif
    set run_status = "finished"
end



cd $source_dir
echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh

