# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set tag = $4
set integer = $5
set unit = $6
set repeat = $7

#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set n_repeat = `echo $repeat | sed 's/:/ /g' | sed 's/repeat//g' | wc -w`
set n_integer = `echo $integer | sed 's/:/ /g' | sed 's/integer//g' | wc -w`
set n_unit = `echo $unit | sed 's/:/ /g' | sed 's/unit//g' | wc -w`

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


cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The tile status as following:
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
set is_eco = 0    
if ($n_tile == 0 && $table_used == 0) then
    source csh/env.csh
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif

set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
if ($n_refDir > 0) then
    cd data/$tag
    echo "# Report specific run dir:"
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        # Identify if it is run dir
        if (-e $rd/tile.params) then
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            echo "$curr_tile $rd" >> tileStatus.list
            set is_eco = `grep PERSONALITY $rd/override.params | grep eco | wc -w`
        else
        # Identify if it is dir with all run dir link
            foreach lrd (`ls -1d $rd/*`)
                if (-e $lrd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $lrd/tile.params | grep -v "#" | awk '{print $3}'`
                    echo "$curr_tile $lrd" >> tileStatus.list
                    set is_eco = `grep PERSONALITY $lrd/override.params | grep eco | wc -w`
                endif
            end

            foreach lrd (`ls -1d $rd/*/latest/workspace`)
                if (-e $lrd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $lrd/tile.params | grep -v "#" | awk '{print $3}'`
                    echo "$curr_tile $lrd" >> tileStatus.list
                    set is_eco = `grep PERSONALITY $lrd/override.params | grep eco | wc -w`
                endif
            end

        endif
    
    end
endif
foreach t (`echo $tile |sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_table > 0 || $n_refDir > 0) then
        continue
    endif
    cd data/$tag 
    foreach rd (`cat $source_dir/$runDir`)
        if ($n_refDir > 0) then
            continue
        endif
        set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($t == $curr_tile) then
            echo "# Found matched $t $curr_tile at $rd"
            set is_eco = `grep PERSONALITY $rd/override.params | grep eco | wc -w`
            echo "$t $rd" >> tileStatus.list
        endif
    end
    cd $source_dir
end
cd $source_dir/data/$tag
set n_tileStatus = `cat tileStatus.list | wc -w`
set project = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "project," | awk -F "," '{print $2}' | sed 's/\r//g'`
set qorCfg = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "qorCfg," | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_qorCfg = `echo $qorCfg | wc -w`
if ($n_tileStatus > 0) then
    set sara  = 1
    if ($sara == 0) then
        cat tileStatus.list | sort -k 1 | awk '{print $2}' > tileStatus.sort.list
        # tt0p9v
        #/tool/aticad/1.0/src/zoo/TileFlowScripts/tile_status/tile_extraction.pl  -run_file tileStatus.sort.list
        # tt0p65v
        /home/simchen/script/tile_status/tile_extraction.pl  -run_file tileStatus.sort.list
        if (-e status_report/index.html) then
            set run_status  = `resolve status_report/index.html`
            echo "http://logviewer-atl.amd.com/$run_status" >> $source_dir/data/${tag}_spec
            set run_status = "finished"
        endif
    else
        set n = 1
        foreach lk (` cat tileStatus.list | sort -k 1 | awk '{print $2}' `)
            set lk = `resolve $lk`
            echo "# link $lk"
            set name = `echo $lk | sed 's/\// /g' | awk '{print $NF}'`
            set name = "${name}_$n"
            ln -s $lk $name
            set n = `expr $n + 1`
        end
        source $source_dir/csh/env.csh
        set lsfProject = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "lsfProject," | awk -F "," '{print $2}'`
        set n_lsfProject = `echo $lsfProject | wc -w`
        deactivate
        cp -rf $source_dir/script/project/sawatchrange/config.pm ./
        if (-e $source_dir/script/project/$project/config.pm) then
            cp -rf $source_dir/script/project/$project/config.pm ./
        endif
        if ($n_qorCfg > 0) then
            if (-e $qorCfg) then
                cp  -rf $qorCfg ./
            endif
        endif
        if ($is_eco > 0) then
            perl /tool/aticad/1.0/src/zoo/safeng/SARA/ECO/gen_data_eco.pl 
        else
            if (-e $source_dir/script/project/$project/gen_data.pl) then
                perl $source_dir/script/project/$project/gen_data.pl
            else
                perl /tools/aticad/1.0/src/zoo/safeng/SARA/gen_data.pl 
            endif
        endif
        awk '{print $2}' tileStatus.list > runlist
         /tool/aticad/1.0/src/zoo/TileFlowScripts/tile_status/perl_module/extract_info.pl -spreadsheet $tag.xls -runlist runlist
        echo "http://logviewer-atl.amd.com/$source_dir/data/$tag/index.html" >> $source_dir/data/${tag}_spec
        set ei = `/tool/pandora64/bin/resolve $source_dir/data/$tag/Tile_Status_*.xlsx | head -n 1`
        echo "http://logviewer-atl.amd.com/$ei" >> $source_dir/data/${tag}_spec
        set run_status = "finished"
    endif
endif
cd $source_dir

echo "$n_repeat $n_integer $n_unit"
set repeat = `echo $repeat | sed 's/:/ /g' | sed 's/repeat//g' `
set integer = `echo $integer | sed 's/:/ /g' | sed 's/integer//g' `
set unit = `echo $unit | sed 's/:/ /g' | sed 's/unit//g'`
echo "$repeat $integer $unit"
if ($n_repeat > 0) then
    if ($n_integer > 0 && $n_unit > 0) then
        set run_status = "${repeat}:${integer}:${unit}"
    endif
    if ($n_integer == 0 && $n_unit > 0) then
        set run_status = "${repeat}:1:${unit}"
    endif

endif


echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
