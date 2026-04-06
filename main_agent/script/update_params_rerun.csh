set tile = $1
set runDir = $2
set refDir = $3
set params = $4
set target = $5
set tag = $6
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
if ($n_tile == 0) then
    source csh/env.csh
    echo "#text#\
    No tile specified or I don't own this tile." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

set n_target = `echo $target | sed 's/:/ /g' | awk '{print $2}' | wc -w`
if ($n_target == 0) then
    source csh/env.csh
    echo "#text#\
    No target specified." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif


cat >> ${tag}_spec << EOF
#text#
    The params has been updated and $target has been rerun:
#list#
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
     if ($n_refDir > 0) then
        set baseDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`
        echo $baseDir
        cd $baseDir
        echo "#list#" >> $source_dir/data/${tag}_spec
    endif

    foreach rd (`cat $runDir`)
        echo $rd
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
            foreach p (`cat $params | sed 's/=/ /g' | awk '{print $1}'`)
                sed -i "/$p/d" override.params
            end
            cat $params >> override.params
            touch update_params_$tag.started
            rm update_params_$tag.started
            TileBuilderTerm -x "TileBuilderGenParams;touch update_params_$tag.started"
             while(1)
                if (-e update_params_$tag.started) then
                    break
                endif
            end
            set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
            touch rerun_$tag.started
            rm rerun_$tag.started
            echo "$curr_dir $target $tag"
            TileBuilderTerm -x "serascmd -find_jobs "status==RUNNING dir=~$curr_dir" --action stop;sleep 5;serascmd -find_jobs "name=~$target dir=~$curr_dir" --action rerun;sleep 5;serascmd -find_jobs "status==NOTRUN dir=~$curr_dir" --action run;touch rerun_$tag.started"
            while(1)
                if (-e rerun_$tag.started) then
                    break
                endif
            end
            echo "$rd" >> $source_dir/data/${tag}_spec
        endif
    end
    cd $source_dir
end
set run_status = "started"
cd $source_dir
source csh/env.csh
echo "#line#" >> ${tag}_spec
echo "#text#" >> ${tag}_spec
source csh/updateTask.csh
