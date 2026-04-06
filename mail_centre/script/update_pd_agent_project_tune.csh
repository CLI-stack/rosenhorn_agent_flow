# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set tag = $5
echo "# Finished params $tile $runDir $refDir $file $tag"
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

set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`
if ($n_tile == 0) then
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif
if ($n_file == 0) then
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The tune file has been updated:
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
set project = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "project," | awk -F "," '{print $2}' | sed 's/\r//g'`
set tuneCenter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "tune," | awk -F "," '{print $2}' | sed 's/\r//g'`
foreach rd (`echo $eff_rd`)
    cd $rd
    echo "# update agent project tune:"
    echo "cp -rf /tool/aticad/1.0/src/zoo/PD_agent/tile/project/$project/tune/* tune/"
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    cp -rf /tool/aticad/1.0/src/zoo/PD_agent/tile/project/$project/tune/* tune/
    set tcls = ""
    foreach tcl (`ls -1d /tool/aticad/1.0/src/zoo/PD_agent/tile/project/$project/tune/*/*.tcl`)
        set tcls = "$tcl;$tcls"
    end
    echo "# update tune center tune:"
    if (-e ${tuneCenter}/${t}) then
        echo "# Found tune in tune Center, copying tune."
        foreach target_path (`ls -1d $tuneCenter/$t/tune/*`)
            set target = `echo $target_path | sed 's/\// /g' | awk '{print $NF}'`
            foreach tcl_path (`ls $tuneCenter/$t/tune/$target/*.tcl`)
                set tcls = "$tcl_path;$tcls"
                set tcl = `echo $tcl_path | sed 's/\// /g' | awk '{print $NF}'`
                if (-e tune/$target) then
                    if (-e tune/$target/$tcl) then
                        cat $tcl_path >> tune/$target/$tcl
                    else
                        cp $tcl_path tune/$target/
                    endif
                else
                    cp -rf  $tuneCenter/$t/tune/$target tune/
                endif

            end
        end
     endif
     echo "$t,$rd,$tcls" >> $source_dir/data/${tag}_spec 
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

