# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set project = $1
set tile = $2
set runDir = $3
set disk = $4
set params = $5
set tune = $6
set tag = $7
set table = $8
set refDir = $9
set diskUsage = 0
set diskUsed = ""
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
set start_new_run = 0
touch $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/:/ /g' | sed 's/tile//g' | wc -w`
source csh/env.csh
set tile_filter = ""
if ($n_tile > 0) then
    foreach t (`echo $tile | sed 's/:/ /g' | sed 's/tile//g'`)
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

set refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`
#set params = `resolve $params`
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The TB run for $tile has been started at: 
EOF
set n_params = 0 
set n_files = 0
set eff_rd = ""
if (-e $table) then
    set n_table = `head -n 1 $table | sed 's/|/ /g' | awk '{print NF}'`
    echo $n_table
    if ($n_table > 0) then
        python3 $source_dir/py/start_run.py --table $table --arguement $source_dir/arguement.csv --tag $tag
        if (-e $source_dir/data/$tag.sub0.params || -e $source_dir/data/$tag.sub1.params)  then
            set n_params = `ls $source_dir/data/$tag.sub*.params | wc -l`
        endif
        if (-e $source_dir/data/$tag.sub0.files || -e $source_dir/data/$tag.sub1.files ) then
            set n_files = `ls $source_dir/data/$tag.sub*.files | wc -l`
            touch data/$tag.runDirFiles
        endif
    else
        set n_params = 0
        echo "# No table used."
    endif
endif
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
set rd_valid = 0
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,runDir,Params" >> $source_dir/data/${tag}_spec
foreach t (`echo $tile | sed 's/:/ /g' | sed 's/tile //g'`)
    set rd_valid = 0
    echo "# run for $t $runDir"
    set run_used = 0
    set n_runDir = `cat $runDir | wc -w`
    echo "$n_runDir"
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
            # found the matched tile run
                if ($t == $curr_tile) then
                    set run_used = 1
                    # If use latest run reasonable?
                    echo "# Found ref dir: $rd"
                    set rd_valid = $rd
                endif
            endif
        end
    endif
        #set baseDir = `echo "$rd" | sed 's/\// /g' | awk '{print "/"$1"/"$2"/"$3"/"$4"/"$5}'`
        #cd $baseDir
    foreach d (`echo $disk | sed 's/:/ /g'`)
        set temp = `df $d | grep -v Filesystem | awk '{print $4}'`
        if ($temp > $diskUsage) then
            set diskUsage = $temp
            set diskUsed = $d
        endif
    end
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
    # Params in table
    if ($n_params > 0 ) then
        
        foreach pf (`ls $source_dir/data/$tag.sub*.params`)

            set sub = `echo $pf | sed 's/\./ /g' | awk '{print $2}'`
            set dir = ${tag}_${sub}
            mkdir $dir
            cd $dir
            touch override.params
            touch override.controls
            rm override.params
            rm override.controls
 
            echo "NICKNAME = ${tag}_${sub}" > override.params
            echo "TILES_TO_RUN = $t" >> override.params
            echo "TILEBUILDERCHECKLOGS_STOPFLOW   = 0" >> override.controls
            set n_refDir = `echo $refDir | wc -w`
            if ($n_refDir > 0) then
                echo "# Use refDir:$refDir"
                if (-e $refDir/override.params) then
                    cat $refDir/override.params | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" >> override.params
                endif
                if (-e $refDir/override.controls) then
                    cat $refDir/override.controls >> override.controls
                endif
            endif

            if ($run_used == 1 && $n_refDir == 0 && $start_new_run == 0) then
                cat $rd_valid/override.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
                python $source_dir/py/merge_params.py --origParams override.params --newParams $pf --outParams out.params --op remove
                cp out.params override.params

                cat $rd_valid/override.controls | egrep -v "NICKNAME|TILES_TO_RUN" >> override.controls
                if (-e $source_dir/data/${tag}.${sub}.controls) then
                    python $source_dir/py/merge_params.py --origParams override.controls --newParams $source_dir/data/${tag}.${sub}.controls --outParams out.controls --op remove
                    cp out.controls override.controls
                endif
            endif

            if ($run_used == 0 && $n_refDir == 0 && $start_new_run == 0) then
                set n_formal_release_params = 0
                foreach p (`ls -lat $source_dir/data/*.params | awk '{print $9}'`)
                    set n_formal_release_params = `grep DESCRIPTION $p |  grep -i "formal release" | wc -w`
                    set n_chip_release = `egrep "CHIP_RELEASE|FLOORPLAN_POINTER" $p | wc -l`
                    if ($n_formal_release_params > 0 && $n_chip_release == 2) then
                        cat $p  | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" >> override.params
                        break
                    endif
                end
                if ($n_formal_release_params == 0) then
                    echo "$t,NA,# No formal release params" >> $source_dir/data/${tag}_spec
                    continue
                endif
            endif
 
            set paramsCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "params," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r//g'`
            if (-e $paramsCenter/$t/override.params) then
                python $source_dir/py/merge_params.py --origParams override.params --newParams $paramsCenter/$t/override.params --outParams out.params --op merge
                cp out.params override.params
            endif
            if (-e $paramsCenter/$t/override.controls) then
                python $source_dir/py/merge_params.py --origParams override.controls --newParams $paramsCenter/$t/override.controls --outParams out.controls --op merge
                cp out.controls override.controls
            endif

            cat $pf >> override.params
            if (-e $source_dir/data/${tag}.${sub}.controls) then
                cat $source_dir/data/${tag}.${sub}.controls >> override.controls
            endif
            setprj $project
            set tb_dir = `pwd`
            set eff_rd = "$eff_rd $tb_dir"
            TileBuilderStart --params override.params --controls override.controls
            set run_dir = `ls -1dlar main/pd/tiles/${t}_${tag}_${sub}_TileBuilder* | tail -n 1 | awk '{print $9}'`
            set n_run_dir = `echo $run_dir | wc -w`
            if ($n_run_dir == 0) then
                set reply = "$reply The run failed to start for $t\n"
                set run_status = "failed"
                set target_run_dir = "${target_run_dir}:"
            else
                set run_status = "started"
                set run_dir = `resolve $run_dir`
                set target_run_dir = "${target_run_dir}:$run_dir"
                set reply = "The TB run has been started."
                set sub_params = `cat $pf`
                #set params_part = `egrep  "DESCRIPTION" tile.params | grep -v "#" | head -n 1`
                echo "$t,$run_dir,$sub_params" >> $source_dir/data/${tag}_spec
                if ($n_files > 0) then
                    echo "$t,$run_dir,$tag.$sub.files" >> $source_dir/data/$tag.runDirFiles 
                endif
                echo "# Wait for tune built."
                set tuneCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "tune," | awk -F "," '{print $2}' | sed 's/\r//g'`
                cd $run_dir
                touch $tag.task
                echo "$sub" | sed 's/sub//g' > $tag.task
                set n_wait = 0
                while(1)
                    if (-e tune) then
                        break
                    endif
                    set n_wait = `expr $n_wait + 1`
                    if ($n_wait > 3600) then
                        echo "## Long time to wait tune."
                        break
                    endif
                    sleep 1
                end
                if (-e tile.params) then
                    set curr_tile = `grep TILES_TO_RUN tile.params | grep -v "#" | awk '{print $3}'`
                ## copy tune from tune center
                    if (-e copyTune.finished) then
                        touch copyTune.finished
                    else
                        if (-e tune) then
                            echo "# tune build for $tuneCenter"
                            if (-e ${tuneCenter}/${curr_tile}/tune) then
                                echo "# Found tune in tune Center, copying tune."
                                cp -rf $tuneCenter/$curr_tile/tune/* tune/
                                touch copyTune.finished
                            endif
                        endif
                    endif
                endif
                cd -

            endif
            echo "# Hold 10 sec to avoid crash."
            sleep 10
            cd  $diskUsed/$vto/$t
        end
    else
        echo "# start new run"
        set dir = $tag
        if (-e $dir) then
            cd $dir
        else
            mkdir $dir
            cd $dir
        endif
        touch override.params
        touch override.controls
        rm override.params
        rm override.controls
        echo "NICKNAME = $tag" > override.params
        echo "TILES_TO_RUN = $t" >> override.params
        echo "TILEBUILDERCHECKLOGS_STOPFLOW   = 0" >> override.controls
        set n_refDir = `echo $refDir | wc -w`
        echo "# check ref run."
        if ($n_refDir > 0) then
            echo "# Use refDir:$refDir"
            if (-e $refDir/override.params) then
                #python $source_dir/script/merge_params.py --origParams $refDir/override.params --newParams override.params --outParams out.params --op remove
                #cp out.params override.params
                cat $refDir/override.params | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" >> override.params
            endif
            if (-e $refDir/override.controls) then
                cat $refDir/override.controls >> override.controls
            endif
        endif
        echo "# check used run."
        if ($run_used == 1 && $n_refDir == 0 && $start_new_run == 0) then
            cat $rd_valid/override.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
            cat $rd_valid/override.controls | egrep -v "NICKNAME|TILES_TO_RUN" >> override.controls
        endif
        echo "# check historical params $run_used | $n_refDir"
        
        if ($run_used == 0 && $n_refDir == 0 && $start_new_run == 0) then
            set n_formal_release_params = 0
            foreach p (`ls -lat $source_dir/data/*.params | awk '{print $9}'`)
                echo "# $p"
                set n_formal_release_params = `grep DESCRIPTION $p |  grep -i "formal release" | wc -w`
                set n_chip_release = `egrep "CHIP_RELEASE|FLOORPLAN_POINTER" $p | wc -l`
                echo "# $n_formal_release_params $n_chip_release"
                if ($n_formal_release_params > 0 && $n_chip_release > 0) then
                    cat $p  | egrep -v "FORGOTTEN_TARGETS|BRANCHED_|NICKNAME|TILES_TO_RUN" >> override.params
                    break
                endif
            end
            if ($n_formal_release_params == 0) then
                echo "$t,NA,# No formal release params" >> $source_dir/data/${tag}_spec
                #continue
            endif
        endif
        echo "# check mail params, remove old params from prevous run"
        if (-e $source_dir/data/$tag.params) then
            cat $source_dir/data/$tag.params | egrep -v "NICKNAME|TILES_TO_RUN" > new.params
            python $source_dir/py/merge_params.py --origParams override.params --newParams new.params --outParams out.params --op remove
        endif
        cp out.params override.params
        if (-e $source_dir/data/$tag.controls) then
            python $source_dir/py/merge_params.py --origParams override.controls --newParams $source_dir/data/$tag.controls --outParams out.controls --op merge
            cp out.controls override.controls
        endif
        
        echo "# check params center params."
        set paramsCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "params," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r//g'`
        echo "$paramsCenter/$t/override.params"
        if (-e $paramsCenter/$t/override.params) then
            python $source_dir/py/merge_params.py --origParams override.params --newParams $paramsCenter/$t/override.params --outParams out.params --op merge
            cp out.params override.params
        endif
        echo "# check params center controls."
        if (-e $paramsCenter/$t/override.controls) then
            python $source_dir/py/merge_params.py --origParams override.controls --newParams $paramsCenter/$t/override.controls --outParams out.controls --op merge
            cp out.controls override.controls
        endif

        echo "# check source dir params"
        if (-e $source_dir/data/$tag.params) then
            cat $source_dir/data/$tag.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
        endif
        source /tools/aticad/1.0/src/sysadmin/cpd.cshrc
        setenv FAMILY supra
        setprj $project
        echo "# start run"
        # xterm -e "TileBuilderStart --params override.params --controls override.controls > ${t}_${tag}.log;touch ${t}_${tag}.finished" &
        set tb_dir = `pwd`
        set eff_rd = "$eff_rd $tb_dir"
        TileBuilderStart --params override.params --controls override.controls
        set run_dir = `ls -1dlar main/pd/tiles/${t}_${tag}_TileBuilder* | tail -n 1 | awk '{print $9}'`
        set n_run_dir = `echo $run_dir | wc -w`
        if ($n_run_dir == 0) then
            set reply = "$reply The run failed to start for $t\n"
            set run_status = "failed"
            set target_run_dir = "${target_run_dir}:"
        else
            set run_status = "started"
            set run_dir = `resolve $run_dir`
            set target_run_dir = "${target_run_dir}:$run_dir"
            set reply = "The TB run has been started."
            set params_part = `egrep  "DESCRIPTION" $run_dir/tile.params | grep -v "#" | head -n 1`
            echo "$t,$run_dir,$params_part" >> $source_dir/data/${tag}_spec
            touch $tag.task        
            set tuneCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "tune," | awk -F "," '{print $2}' | sed 's/\r//g'`
            echo "# Wait for tune built and logs/UpdateTunable.log.gz."
            cd $run_dir
            set n_wait = 0
            while(1)
                if (-e tune && -e logs/UpdateTunable.log.gz) then
                    break
                endif
                set n_wait = `expr $n_wait + 1`
                if ($n_wait > 3600) then
                    echo "## Long time to wait tune."
                    break
                endif
                sleep 1
            end
            if (-e tile.params) then
                set curr_tile = `grep TILES_TO_RUN tile.params | grep -v "#" | awk '{print $3}'`
            ## copy tune from tune center
                if (-e copyTune.finished) then
                    touch copyTune.finished
                else
                    if (-e logs/UpdateTunable.log.gz && -e tune) then
                        echo "# tune build for $tuneCenter/${curr_tile} .."
                        if (-e ${tuneCenter}/${curr_tile}) then
                            echo "# Found tune in tune Center, copying tune."
                            cp -rf $tuneCenter/$curr_tile/tune/* tune/
                            touch copyTune.finished
                        endif
                    endif
                endif
            endif
            cd -

        endif
    endif
    cd $source_dir
end
echo "#table end#" >> $source_dir/data/${tag}_spec
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
