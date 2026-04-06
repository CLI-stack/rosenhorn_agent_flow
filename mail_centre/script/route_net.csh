# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set target = $4
set tag = $5
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec

set tile_filter = ""
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g' | wc -w`
if ($n_tile > 0) then
    foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g'`)
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

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The fix eco timing has been done:
#table#
EOF

echo "tile,runDir,status" >> $source_dir/data/${tag}_spec
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
        if (-e $rd/tile.params) then
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set eff_rd = "$eff_rd $rd"
        else
        # Identify if it is dir with all run dir link
            foreach lrd (`ls -1d $rd/*`)
                if (-e $lrd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $lrd/tile.params | grep -v "#" | awk '{print $3}'`
                    set eff_rd = "$eff_rd $lrd"
                endif
            end
        endif
    end
endif

foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g'`)
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
set task = "route_net"
set task_file = ${task}_$tag
foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    if (-e $source_dir/data/$tag.table) then
        echo "# Check table format"
        set table_n = `cat $source_dir/data/$tag.table | head -n 1 | sed 's/|/ /g' | awk '{print NF}'`
        if ($table_n != 6) then
            echo "$t,$rd,table format not correct.Should be 6 column: tile/net/min_routing_layer/max_routing_layer/rule/tune" >> $source_dir/data/${tag}_spec 
            continue
        endif
        set curr_tile = `cat $source_dir/data/$tag.table | awk '{print $1}'`
        # set_routing_rule $net -min_routing_layer M16 -max_routing_layer M17 -rule Track2X_Wide1X_Metal_With_Shield
        set tune = `egrep $t $source_dir/data/$tag.table | sed 's/|/ /g' | awk '{print $6}' | head -n 1`
        set dir = `dirname $tune`
        if (-e $dir) then
            if (-e $tune) then
                chmod 744 $tune
            endif
        else
            mkdir -p $dir
        endif
        if (-e $tune) then
            chmod 744 $tune
        endif
        echo "# $t $tune"
        echo "# $tag route net" >> tune
        cat $source_dir/data/$tag.table | sed 's/|/ /g' | egrep $t | awk '{print "set_routing_rule",$2,"-min_routing_layer",$3,"-max_routing_layer",$4,"-rule",$5}' >> $tune
        echo "set nets {"  >> $tune
        cat $source_dir/data/$tag.table | sed 's/|/ /g' | egrep $t | awk '{print $2}' >> $tune
        echo "}"  >> $tune
        echo 'route_eco -nets $nets -max_detail_route_iterations 2 -reuse_existing_global_route 1' >> $tune
        echo 'write_def -objects [get_nets $nets] data/route_net.def.gz' >> $tune
    else
        echo "# Net Table not exist."
    endif
    set tg = `cat $source_dir/data/$tag.table | sed 's/|/ /g' | egrep $t | awk '{print $6}' | sed 's/\// /g' | awk '{print $2}'`
    #source $source_dir/script/rerun_target_core.csh $tg &
    echo "$t,$rd,$tune add route net and rerun" >> $source_dir/data/${tag}_spec
end


echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh

