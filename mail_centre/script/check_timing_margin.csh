# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set clk = $4
set file = $5
set tag = $6
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec

set tile_filter = ""
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | sed 's/:/ /g' | wc -w`
set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
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
    if ($n_refDir == 0) then
        set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
        echo "You don't specify any tiles or run dir, do you want to rerun for $tile_owned ? " >> $source_dir/data/${tag}_spec
        set run_status = "failed"
        exit
    endif
endif
set n_tile_filter = `echo $tile_filter | wc -w`
if ($n_tile_filter == 0 && $n_tile > 0) then
    echo "I don't own $tile or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif

set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`
set n_clk = `echo $clk | sed 's/:/ /g' | sed 's/clk//g' | wc -w`
if ($n_clk == 0) then
    echo "CLK name not specified,please find it in SDC." >> $source_dir/data/${tag}_spec
    exit
else
    set clk = `echo $clk | sed 's/://g' | sed 's/clk//g'`
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The timing margin has been checked:
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
set task = "check_timing_margin"
set task_file = ${task}_$tag
foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    foreach f (`echo $file | sed 's/:/ /g' | sed 's/file//g' `)
        set n_pt_cmd = `echo $f | grep "Pt.*cmd" | wc -w`
        set n_fc_cmd = `echo $f | grep ".nlib" | wc -w`
        set clk = `echo $clk | sed 's/://g' | sed 's/clk//g'`
        if ($n_pt_cmd > 0) then
            echo "source /tools/aticad/1.0/src/zoo/PD_agent/tile/check_timing_margin.tcl" > check_timing_margin.$clk.tcl
            echo "check_timing_margin $clk" >> check_timing_margin.$clk.tcl
            echo "echo finished > rpts/${task}_$tag" >> check_timing_margin.$clk.tcl
            echo "exit" >>  check_timing_margin.$clk.tcl
    
            TileBuilderTerm -x "TileBuilderLoadTiming --nosi $f -a check_timing_margin.$clk.tcl;touch $task_file"
        else if ($n_fc_cmd > 0) then
            echo "source /tools/aticad/1.0/src/zoo/PD_agent/tile/check_timing_margin_fc.tcl" > check_timing_margin.$clk.tcl
            echo "check_timing_margin $clk" >> check_timing_margin.$clk.tcl
            echo "echo finished > rpts/${task}_$tag" >> check_timing_margin.$clk.tcl
            echo "exit" >>  check_timing_margin.$clk.tcl

            TileBuilderTerm -x "TileBuilderIntFX $f -ng -a check_timing_margin.$clk.tcl;touch $task_file"
        else
            echo "$t,$rd,Pt cmd not correct"  >> $source_dir/data/${tag}_spec
        endif
    end
end
## wait for task finish
foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    source $source_dir/script/wait_file_finish.csh rpts/${task}_$tag 3000 
    echo "$t,$rd,$rd/rpts/check_timing_margin.$clk.rpt" >> $source_dir/data/${tag}_spec
end


echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh

