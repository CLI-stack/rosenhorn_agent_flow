# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com

# Copyright (c) 2024 Chen, Simon ; simon1.chen@amd.com;  Advanced Micro Devices, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set tile = $1
set runDir = $2
set refDir = $3
set target = $4
set tag = $5
echo "# Finished params $target $tag"
set source_dir = `pwd`
touch  $source_dir/data/${tag}_spec
echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
set tile_filter = ""
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
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
        echo "You don't specify any tiles or run dir, do you want to update params for $tile_owned ? " >> $source_dir/data/${tag}_spec
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


set n_target = `echo $target | sed 's/:/ /g' | sed 's/target//g' | wc -w`
set target = `echo $target | sed 's/:/ /g' | sed 's/target//g'`
if ($n_target == 0) then
    source csh/env.csh
    echo "#text#\
    No target specified." >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec
    exit
endif

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The $target has been skipped at:
EOF

set target_run_dir = ":"
set reply = ""
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,runDir,status" >> $source_dir/data/${tag}_spec
#set runDir = `cat $runDir | sed 's/:/ /g' | awk '{print $2}'`
set target_orig = "$target"
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
        set eff_rd = "$eff_rd $rd"
    end
endif
set run_used = 0
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_refDir > 0 || $n_table > 0 ) then
        break
    endif
    foreach rd (`cat $runDir`)
        echo "# check $rd"
        if ($n_refDir > 0 ) then
            continue
        endif
        set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($t == $curr_tile) then
            set eff_rd = "$eff_rd $rd"
        endif
        if ($run_used == 1) then
                #echo "----- stop"
                #break
        endif
    end
    cd $source_dir
end
# perform instruction in effective run dir
foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
    TileBuilderTerm -x "serascmd -find_jobs "dir=~$curr_dir" --action stop;"
    sleep 60
    touch skip_targets_$tag.started
    rm skip_targets_$tag.started
    set ids = ""
    foreach tg (`echo $target_orig | sed 's/:/ /g' | sed 's/target//g' `)
        echo "$curr_dir $tg $tag"
        set id = `grep $tg tbs.log | awk '{print $1}'`
        set ids = "$ids,$id"
        set skip_flag = 0
    end
    set skip_cmd = "serascmd --action skip --jobs $ids;touch skip_targets_$tag.started"
    TileBuilderTerm -x $skip_cmd
end

foreach rd (`echo $eff_rd`)
    cd $rd
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_wait = 0
    while(1)
        echo "check skip_targets_$tag.started $rd"
        if (-e skip_targets_$tag.started) then
            set run_status = "started"
            set run_dir = `resolve $rd`
            set target_run_dir = "${target_run_dir}:$run_dir"
            echo "$t,$rd,skip $target_orig pass" >> $source_dir/data/${tag}_spec
            set reply = "Success"
            set run_used = 1

            break
        endif

        set n_wait = `expr $n_wait + 1`
        if ($n_wait > 3600) then
            break
        endif
        sleep 1
    end
end


echo "#table end#" >> $source_dir/data/${tag}_spec
cd $source_dir
echo "#line#" >> ${tag}_spec
echo "#text#" >> ${tag}_spec
source csh/env.csh

source csh/updateTask.csh
