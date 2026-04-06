# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set tag = $5
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set n_file = `echo $file | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set file = `echo $file | sed 's/:/ /g' | sed 's/file//g'`
set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set tile_filter = ""
if ($n_tile > 0) then
    foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
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

if ($n_file == 0 ) then
    echo "No nlib specified" >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif


cat >> $source_dir/data/${tag}_spec << EOF
#list#
    $file has been open at following dir, please wait.
EOF
echo "#list#" >> $source_dir/data/${tag}_spec
if (-e data/$tag) then
    echo "# data/$tag existed."
    touch data/$tag/tileStatus.list
    rm data/$tag/tileStatus.list
    touch data/$tag/tileStatus.list

else
    mkdir -p data/$tag
    touch data/$tag/tileStatus.list
    rm data/$tag/tileStatus.list
    touch data/$tag/tileStatus.list

endif
set n_run_dir = 0
set table_used = 0
# Detect table based input
if (-e data/$tag.table) then
    set n_table = `cat data/$tag.table | wc -w`
    if ($n_table > 0) then
        echo "# Found table input."
        cd data/$tag
        foreach sect (`cat  $source_dir/data/$tag.table | sed 's/|/ /g'`)
            set n_run_dir = `echo $sect | egrep "main/pd/tiles" | wc -w`
            if ($n_run_dir > 0) then
                if (-e $sect/tile.params) then
                    echo "# Found run dir $sect"
                    set curr_tile = `grep TILES_TO_RUN $sect/tile.params | grep -v "#" | awk '{print $3}'`
                    echo "$curr_tile $sect" >> tileStatus.list
                endif
            endif
        end
    endif
    cd $source_dir
endif
    
if ($n_tile == 0 && $table_used == 0) then
    source csh/env.csh
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif

set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
foreach t (`echo $tile |sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($table_used > 0) then
        continue
    endif
    # Specify run dir in mail
    if ($n_refDir > 0) then
        cd data/$tag
        echo "# Report specific run dir:"
        foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            echo "$curr_tile $rd" >> tileStatus.list
        end
        break
    endif
    cd data/$tag 
    foreach rd (`cat $source_dir/$runDir`)
        if ($n_refDir > 0) then
            continue
        endif
        set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($t == $curr_tile) then
            echo "# Found matched $t $curr_tile at $rd"
            echo "$t $rd" >> tileStatus.list
        endif
    end
    cd $source_dir
end
cd $source_dir/data/$tag
set n_tileStatus = `cat tileStatus.list | wc -w`
if ($n_tileStatus > 0) then
    deactivate
        foreach lk (` cat tileStatus.list | sort -k 1 | awk '{print $2}' `)
            cd $lk 
            set run_tcl = "" 
            foreach tcl (`echo $file`)
                set n_tcl = `echo $tcl | grep tcl | wc -w`
                if ($n_tcl > 0) then
                    # check if contain other function
                    set n_source = `grep source $tcl | wc -w`
                    set n_write_v = `grep write_verilog $tcl | wc -w`
                    if ($n_source > 0 || $n_write_v > 0) then
                        echo "tcl contain source or write_verilog, will be skip!" >> $source_dir/data/${tag}_spec
                        continue
                    endif
                    set run_tcl = "$tcl"
                    break
                endif
            end
            
            foreach nlib (`echo $file`)
                set n_nlib = `echo $nlib | grep nlib | wc -w`
                set n_run_tcl = `echo $run_tcl | wc -w`
                if ($n_nlib > 0) then
                    if (-e $nlib) then
                    else
                        echo "$nlib not exist in $lk" >> $source_dir/data/${tag}_spec
                    endif
                    set n_run_tcl = `cat $source_dir/data/$tag/$tag.tcl | wc -w`
                    if ($n_run_tcl > 0) then
                        TileBuilderTerm -x "TileBuilderIntFX $nlib -a $source_dir/data/$tag/$tag.tcl --nogui"
                    else
                        TileBuilderTerm -x "TileBuilderIntFX $nlib"
                        echo "$n_run_tcl not run tcl"
                    endif
                endif
            end
            echo "$lk" >> $source_dir/data/${tag}_spec
            echo "# open nlib for $lk"
        end
        set run_status = "finished"
    endif
endif

cd $source_dir
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
