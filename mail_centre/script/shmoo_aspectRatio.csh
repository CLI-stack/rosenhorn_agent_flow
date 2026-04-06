set project = $1
set tile = $2
set runDir = $3
set disk = $4
set params = $5
set tune = $6
set digits = $7
set file = $8
set tag = $9
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch  $source_dir/data/${tag}_spec
rm  $source_dir/data/${tag}_spec
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


cat >> ${tag}_spec << EOF
#text#
    The shmoo run is following:
#table#
Tile,Utilization,RunDir
EOF
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
foreach digit (`echo $digits | sed 's/digit://g' | sed 's/:/ /g' |  awk '{for(i=0;i<($2-$1)/0.03;i++) {print $1+i*0.03} }'`)
    set diskUsage = 0
    set diskUsed = ""
    set reply = ""
    foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
        set run_used = 0
        foreach rd (`cat $runDir`)
            if ($run_used == 1) then
                #echo "----- stop"
                continue
            endif
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            if ($t == $curr_tile) then
                set baseDir = `echo "$rd" | sed 's/\// /g' | awk '{print "/"$1"/"$2"/"$3"/"$4"/"$5}'`
                cd $baseDir
                touch override.params
                touch override.controls
                rm override.params
                rm override.controls
                set nickname = `echo ${tag}_util_$digit | sed 's/\./p/g'`
                echo "NICKNAME = $nickname" > override.params
                echo "TILES_TO_RUN = $t" >> override.params
                cat $rd/override.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params 
                cat $params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
                echo "TILEBUILDERCHECKLOGS_STOPFLOW   = 0" >> override.controls
                setprj $project
                TileBuilderStart --params override.params --controls override.controls
                set run_dir = `ls -1dlar main/pd/tiles/${t}_${nickname}_TileBuilder* | tail -n 1 | awk '{print $9}'`
                set n_run_dir = `echo $run_dir | wc -w`
                if ($n_run_dir == 0) then
                    set reply = "$reply The run failed to start for $t\n"
                    set run_status = "failed"
                    set target_run_dir = "${target_run_dir}:"
                else
                    set run_status = "started"
                    set run_dir = `resolve $run_dir`
                    set target_run_dir = "${target_run_dir}:$run_dir"
                    set reply = "The TB run has been started at: \n $target_run_dir\n"
                    echo "$t,$digit,$run_dir" >> $source_dir/data/${tag}_spec 
                endif
                set run_used = 1
                echo "### $tag $run_status ${run_dir} $source_dir $run_used"
            endif
            if ($run_used == 1) then
                #echo "----- stop"
                continue 
            endif
        end
        # no exist dir found
        if ($run_used == 0) then
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
            set dir = `date | sed 's/ /_/g' | sed 's/:/_/g'`
            mkdir $dir
            cd $dir
            touch override.params
            touch override.controls
            set nickname = `echo ${tag}_util_$digit | sed 's/\./p/g'`
            echo "NICKNAME = $nickname" > override.params
            echo "TILES_TO_RUN = $t" >> override.params
            cat $params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
            setprj $project
            TileBuilderStart --params override.params --controls override.controls
            set run_dir = `ls -1dlar main/pd/tiles/${t}_${nickname}_TileBuilder* | tail -n 1 | awk '{print $9}'`
            set n_run_dir = `echo $run_dir | wc -w`
            if ($n_run_dir == 0) then
                set reply = "$reply \n The run failed to start for $t"
                set run_status = "failed"
                set target_run_dir = "${target_run_dir}:"
            else
                set run_status = "started"
                set run_dir = `resolve $run_dir`
                set target_run_dir = "${target_run_dir}:${run_dir}"
                set reply = "$reply \n The TB run has been started at $target_run_dir"
                echo "########### use new run"
                echo "$t,$digit,$run_dir" >> $source_dir/data/${tag}_spec
            endif
        endif
    end
    cd $source_dir
end
cd $source_dir
if ($run_used == 0) then
    echo "# use new run"
endif
source csh/env.csh
echo "#table end#" >> ${tag}_spec
echo "#line#" >> ${tag}_spec
echo "#text#" >> ${tag}_spec
source csh/updateTask.csh
