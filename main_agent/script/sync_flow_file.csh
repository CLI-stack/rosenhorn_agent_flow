# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set p4File = $4
set tag = $5
echo "# Finished params $tile $runDir $refDir $p4File $tag"
set source_dir = `pwd`
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

set n_p4File = `echo $p4File | sed 's/:/ /g' | sed 's/p4File//g' | wc -w`
if ($n_tile == 0) then
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif
if ($n_p4File == 0) then
    source csh/env.csh
    echo "#list#\
    No p4File( //depot/tools/aticad/1.0/flow/TileBuilder/..) specified." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The flow file has been updated:
#table#
Tile,runDir,Status
EOF

set target_run_dir = ":"
set reply = ""
set eff_rd = ""
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
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
        if (-e $rd) then
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

foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set err_list = ""
    foreach f (`echo $p4File | sed 's/:/ /g' | sed 's/p4File//g' `)
        set f  = `echo $f | sed 's/__/.../g'`
        set n_tb = `echo $p4File | grep TileBuilder | wc -w`
        set n_tune_project = `echo $p4File | grep "ProjectTune" | wc -w`
        set n_placeroute_params = `echo $p4File | egrep "placeroute.params|placeroute.controls" | wc -w`
        if ($n_tb > 0) then
            cd ../../../../TileBuilder/
            set curr_dir = `pwd`
            echo "# Sync $f at $curr_dir"
            p4 sync $f >& sync.log
            set err = `grep "not on client" sync.log`
            set n_err = `echo $err | wc -w`
            if ($n_err > 0) then
                set err_list = "$f $err;$err_list"
            endif
            cd $rd
        endif
        if ($n_tune_project > 0) then
            cd tune/project
            set curr_dir = `pwd`
            echo "# Sync $f at $curr_dir"
            p4 sync $f >& sync.log
            set err = `grep "not on client" sync.log`
            set n_err = `echo $err | wc -w`
            if ($n_err > 0) then
                set err_list = "$f $err;$err_list"
            endif
            cd $rd
        endif
        if ($n_placeroute_params > 0) then
            cd ../../../..
            set curr_dir = `pwd`
            echo "# Sync $f at $curr_dir"
            p4 sync $f >& sync.log
            set err = `grep "not on client" sync.log`
            set n_err = `echo $err | wc -w`
            if ($n_err > 0) then
                set err_list = "$f $err;$err_list"
            endif
            cd $rd
        else
            
            cd ..
            set curr_dir = `pwd`
            echo "# Sync $f at $curr_dir"
            p4 sync $f >& sync.log
            set err = `grep "not on client" sync.log`
            set n_err = `echo $err | wc -w`
            if ($n_err > 0) then
                set err_list = "$f $err;$err_list"
            endif
            cd $rd
        endif 
    end
    echo "$t,$rd,$p4File sync;$err_list" >> $source_dir/data/${tag}_spec
    touch $tag.task
    set run_status = "finished" 
end

cd $source_dir
echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
echo "## check tag $tag"
source csh/updateTask.csh

