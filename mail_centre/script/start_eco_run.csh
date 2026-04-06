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
touch $source_dir/data/${tag}_spec
if ($tile == "tile") then
    source csh/env.csh
    echo "#text#\
    No tile specified or I don't own this tile." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

set params = `resolve $params`
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The TB run has been started at: 
#list#
EOF
if (-e $table) then
    set n_table = `head -n 1 $table | sed 's/|/ /g' | awk '{print NF}'`
    echo $n_table
    if ($n_table > 0) then
        python3 $source_dir/script/start_run.py --table $table --arguement $source_dir/arguement.csv --tag $tag
        set n_params = `ls $source_dir/data/$tag.sub*.params | wc -l`
    else
        set n_params = 0
        echo "# No table used."
    endif
endif

set rd_valid = ""
foreach t (`echo $tile | sed 's/:/ /g' | sed 's/tile //g'`)
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
            endif
            # found the matched tile run
            if ($t == $curr_tile) then
                set run_used = 1
                echo "# Found ref dir: $rd"
                set rd_valid = $rd
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
    set username = `whoami`
    if (-e $diskUsed/$username) then
        cd $diskUsed/$username
        if (-e $t) then
            cd $t
        else
            mkdir -p $t
            cd $t
        endif
    else
        cd $diskUsed
        mkdir -p $diskUsed/$username/$t
        cd $diskUsed/$username/$t
    endif
    if ($n_params>0) then
        echo "#table#" >> $source_dir/data/${tag}_spec
        echo "runDir,Params" >> $source_dir/data/${tag}_spec
        foreach pf (`ls $source_dir/data/$tag.sub*.params`)
            set dir = `date | sed 's/ /_/g' | sed 's/:/_/g'`
            mkdir $dir
            cd $dir
            touch override.params
            touch override.controls
            rm override.params
            rm override.controls
 
            set sub = `echo $pf | sed 's/\./ /g' | awk '{print $2}'`
            echo "NICKNAME = ${tag}_${sub}" > override.params
            echo "TILES_TO_RUN = $t" >> override.params
            echo "TILEBUILDERCHECKLOGS_STOPFLOW   = 0" >> override.controls
            if ($run_used == 1) then
                cat $rd_valid/override.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
            endif
            cat $params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
            cat $pf >> override.params
            setprj $project
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
                echo "$run_dir,$sub_params" >> $source_dir/data/${tag}_spec
            endif
            echo "# Hold 10 sec to avoid crash."
            sleep 10
            cd  $diskUsed/$username/$t
        end
        echo "#table end#" >> $source_dir/data/${tag}_spec
    else
        echo "# start new run"
        set dir = `date | sed 's/ /_/g' | sed 's/:/_/g'`
        mkdir $dir
        cd $dir
        touch override.params
        touch override.controls
        rm override.params
        rm override.controls
        echo "NICKNAME = $tag" > override.params
        echo "TILES_TO_RUN = $t" >> override.params
        echo "TILEBUILDERCHECKLOGS_STOPFLOW   = 0" >> override.controls
        if ($run_used == 1) then
            cat $rd_valid/override.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
            cat $rd_valid/override.controls | egrep -v "NICKNAME|TILES_TO_RUN" >> override.controls
        endif
        set n_refDir = `echo $refDir | wc -w`
        if (n_refDir > 0) then
            if (-e $refDir/override.params) then
                cat $refDir/override.params >> override.params
            endif
            if (-e $refDir/override.controls) then
                cat $refDir/override.controls >> override.controls
            endif
        endif
        cat $params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
        setprj $project
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
            echo $run_dir >> $source_dir/data/${tag}_spec
        endif
    endif
end
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
