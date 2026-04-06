# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
#set disk = `echo $disk | sed 's/:/ /g'`

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
set tag = $4
set source_dir = `pwd`
set target_run_dir = ":"
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`

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
     What-if analysis for congestion as following:
EOF
echo "#list#" >> $source_dir/data/${tag}_spec
set n_run_dir = 0
set table_used = 0
echo "#table#" >> $source_dir/data/${tag}_spec
echo "utilization,aspect_ratio,congestion_probability,comment" >> $source_dir/data/${tag}_spec

set eff_rd = ""
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
     if ($n_refDir > 0) then
        foreach baseDir (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
            cd $baseDir
            set eff_rd = "$eff_rd $rd"
        end
    endif
    foreach rd (`cat $runDir`)
        set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($t == $curr_tile) then
            cd $rd
            set skip = 0
            if ($refDir == "refDir") then
                echo "# All dir need updated."
            else
                foreach r (`echo $refDir | sed 's/:/ /g' | sed 's/refDir //g'`)
                    set r = `echo $r | sed 's/\/$//g'`
                    if ($r == "$rd") then
                        echo "# found match dir $r $rd"
                        set skip = 0
                    else
                        set skip = 1
                        echo "# not match $r $rd"
                    endif
                end
            endif
            if ($skip == 1) then
                continue
            endif
            set eff_rd = "$eff_rd $rd"
            break
        endif
    end
    cd $source_dir
end

foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    if (-e $source_dir/data/$tag.table) then
        set n_table = `cat $source_dir/data/$tag.table | wc -w`
        set default_util = `zgrep "Standard cell utilization" rpts/FxFpPlaceMacros/amd_utilization.rpt.gz | awk '{printf "%.4f\n",$5/100}'`
        set cr = `python3 $source_dir/script/get_aoi_ratio.py --rpt rpts/FxFpPlaceMacros/report_design.rpt.gz | grep "# aoi ratio" | awk '{printf "%.4f\n",$6}'`
        set dbu = `zgrep "UNITS DISTANCE MICRONS" data/GetDef.def.gz | awk '{print $4}'`
        set ar = `python3 $source_dir/script/get_aspect_ratio.py --indef data/GetDef.def.gz | grep "# min max point" | awk '{printf "%.4f\n",$9}'`
        set node = `grep TECHNO_NAME tile.params | grep -v "#" | awk '{print $3}'`
        source $source_dir/script/env.csh
        if (-e $source_dir/script/${node}.txt) then
        else
            echo "$default_util,$ar,NA,No_tech_training_file" >> $source_dir/data/${tag}_spec
            break
        endif
        python3 $source_dir/script/RF_congestion_train.py --node $source_dir/script/${node}.txt --util $default_util  --ar $ar --cr $cr | grep "# congestion prob" | awk '{print $4","$5","$6",default def"}' >> $source_dir/data/${tag}_spec
        if ($n_table > 0) then
            foreach sect ("`cat $source_dir/data/$tag.table`")
                set n_sect = `echo $sect | sed 's/|//g' | sed 's/[0-9]//g' | sed 's/\.//g' | wc -w`
                echo "# check if it is number $n_sect"
                if ($n_sect > 0) then
                    continue
                endif
                set util = `echo $sect | sed "s/|/ /g" | awk '{print $1}'`
                set ar = `echo $sect | sed "s/|/ /g" | awk '{print $2}'`
                python3 $source_dir/script/RF_congestion_train.py --node $source_dir/script/${node}.txt --util $util  --ar $ar --cr $cr | grep "# congestion prob" | awk '{print $4","$5","$6",what-if"}' >> $source_dir/data/${tag}_spec
            end
        endif
    endif
end

echo "#table end#" >> $source_dir/data/${tag}_spec
set run_status = "finished"

cd $source_dir
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
