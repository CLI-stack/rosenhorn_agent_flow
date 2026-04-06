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
set tag = $4
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`
set targets = "FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower FxPostFloorPlan FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxOptCts FxIncrProuteOptCts FxRoute FxOptRoute FxReRoute FxStreamOut" 
source csh/env.csh
set activeRunDir = ""
touch $source_dir/data/${tag}_spec

set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_tile > 0) then
        continue
    endif
    set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
    set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
    if ($n_rd_tile == 0) then
        echo "I don't own $t or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    endif
end

cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The flow issue for $tile is following:
EOF
set table_used = 0
set run_time = "NA"
echo "You can check in browser: $source_dir/data/${tag}_spec.html" >> $source_dir/data/${tag}_spec
echo "Slides: $source_dir/data/${tag}/flow_issue.pptx" >> $source_dir/data/${tag}_spec
echo "hi"
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
if ($n_tile == 0 && $table_used == 0) then
    source csh/env.csh
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif


set refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`
set n_refDir = `echo $refDir | wc -w`
if ($n_refDir > 0) then
    echo "#table#" >> $source_dir/data/${tag}_spec
    echo "Tile,Finished,Running,runTime(hour),Failed,isMonitored,runDir" >> $source_dir/data/${tag}_spec
endif
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($table_used == 1) then
        continue
    endif
    if ($n_refDir > 0) then
        foreach rd (`echo $refDir`)
        echo $rd
            set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
    #echo "$rd_tile $tile"
            if ($rd_tile == $t) then
                cd $rd
                set n = 0
                set finishedTarget = "NA"
                set latestTarget = ""
                set runningTarget = ""
                set failed_target = `zgrep " Output dependency file" logs/*.log.gz | sed 's/:/ /g' | grep -v rde.txt | awk '{print $1}' | sort -u`
                foreach target (`echo $targets`)
                    set run_status = "finished"
            #echo "$target $rd"
                    set length = `echo $finishedTarget | wc -w`
                    if (-e logs/${target}.log.gz) then
                        set n = `expr $n + 1`
                        set finishedTarget = $target
                        echo "$length $target $rd"
                        set latestTarget = $finishedTarget
                    endif
                    if (-e logs/${target}.log) then
                        set runningTarget = $target
                        set start_time = `head -n 1 logs/${target}.log | sed 's/:/ /g' | awk '{print $4,$5}'`
                        set end_time = `ls -l logs/${target}.log | sed 's/:/ /g' | awk '{print $7,$8}'`
                        set run_time = `echo "$start_time $end_time" | awk '{print ($3-$1)*24 + $4-$2}' `
                        echo "# Running target is $runningTarget"
                        set activeRunDir = $rd
                    endif
                end
                set length_running = `echo $runningTarget | wc -w`
                if ($length_running == 0) then
                    set runningTarget = "NA"
                endif
                set isMonitored = "start"
                if (-e stop_vto_monitor) then
                    set isMonitored = "stop"
                endif
                echo "$t,$finishedTarget,$runningTarget,$run_time,$failed_target,$isMonitored,$rd" >> $source_dir/data/${tag}_spec
            endif
        end
    endif
    cd $source_dir
end
python $source_dir/py/report_runProgress.py --tag $tag --tasksModelFile $tasksModelFile --item 'runDir'
set t = "NA"
set pre_t = "NA"
set rd_valid = ""
touch $source_dir/data/$tag/flow_issue.sum
rm $source_dir/data/$tag/flow_issue.sum
touch $source_dir/data/$tag/flow_issue.sum
touch $source_dir/data/$tag/test.log
rm $source_dir/data/$tag/*.log
touch $source_dir/data/$tag/test.html
rm $source_dir/data/$tag/*.html
echo "$n_refDir $table_used "
foreach trd (`cat $source_dir/data/$tag/report_runProgress`)
    if ($table_used == 1) then
        continue
    endif
    set t = `echo $trd | awk -F ":" '{print $1}'`
    set rd = `echo $trd | awk -F ":" '{print $2}'`
    set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_rd_tile = `echo $tile | grep $rd_tile | wc -l`
    set n_rd_tile = 1
    echo "$tile | $rd_tile | $n_rd_tile"
    if ($n_rd_tile > 0) then
        cd $rd
        set rd_valid = "$rd_valid $rd"
        set n = 0
        touch flow_issue.sum
        rm flow_issue.sum
        echo "$rd"
        if (-e tbs.log) then
            foreach tg (`cat tbs.log | awk '{print $2}'`)
                set errlog = ""
                set n_tb_issue = `ls *.$tg.analyze_target.log | wc -w`
                echo "# check $tg $n_tb_issue $rd"
                if ($n_tb_issue > 0) then
                    foreach issue (`ls *.$tg.analyze_target.log`)
                        echo "# Found $tg issue"
                        set errlog = "$errlog ; $rd/$issue"
                        set issue_name = `echo $issue | sed 's/\./ /g' |awk '{print $1}'`
                        touch $source_dir/data/$tag/$issue_name.$tg.log
                        echo "$rd/$issue" >> $source_dir/data/$tag/$issue_name.$tg.log
                    end
                    echo "$tg | $errlog ; |  $rd_tile ; | $rd ;" >> $source_dir/data/$tag/flow_issue.sum
                endif
            end
        endif
    endif
end
cd $source_dir 
echo "#table#" >> $source_dir/data/${tag}_spec
echo "target,log,tile,runDir" >> $source_dir/data/${tag}_spec
echo "#title#" > $source_dir/data/${tag}/pptx.spec
echo "Flow Issue" >> $source_dir/data/${tag}/pptx.spec
echo "#table#" >> $source_dir/data/${tag}/pptx.spec
echo "Target|Issues|Tile"  >> $source_dir/data/${tag}/pptx.spec
set n_line_slide = 0
foreach tg (`cat $source_dir/data/$tag/flow_issue.sum | sort -u | awk -F '|' '{print $1}' | sort -u -k 1`)
    set errlog = ""
    foreach issue (`ls $source_dir/data/$tag/*.$tg.log`)
        set n_err = `cat $issue | wc -l`
        echo "process $issue $n_err"
        set issue_n = `echo $issue | sed "s/\.$tg/.$tg.${n_err}/g"`
        echo "#table#" > $issue_n
        echo "tile,issue" >> $issue_n
        foreach log (`cat $issue`)
            set t = `echo $log | sed 's/\// /g' | awk '{print $4}'`
            echo "$t,$log" >> $issue_n
        end
        echo "#table end#">> $issue_n
        python3 $source_dir/script/spec2Html.py --spec $issue_n --html $issue_n.html
        set errlog = "$errlog ; $issue_n.html"
    end
    set t = `grep $tg $source_dir/data/$tag/flow_issue.sum | awk -F '|' '{print $3}' | sort -u`
    set rd = `grep $tg $source_dir/data/$tag/flow_issue.sum | awk -F '|' '{print $4}' | sort -u`
    echo "$tg,$errlog,$t,$rd" >> $source_dir/data/${tag}_spec
    set n_errlog = `echo $errlog | sed 's/;/\n/g' | grep "\S" | wc -l`
    set n_t = `echo $t | sed 's/;/\n/g' | grep "\S" | wc -l`
    set issue = `echo $errlog  | sed 's/;//g' | awk '{print $1}' | awk -F "/" '{print $NF}' | awk -F "." '{print $1}'`
    set n_pt = `echo $tg | grep Pt | wc -w`
    if ($n_pt > 0) then
        set n_pt_issue = `grep "$issue" $source_dir/data/${tag}/pptx.spec | grep Pt | wc -l`
    else
        set n_pt_issue = 0
    endif
    set n_tk = `echo $tg | grep Tk | wc -w`
    if ($n_tk > 0) then
        set n_tk_issue = `grep "$issue" $source_dir/data/${tag}/pptx.spec | grep Tk | wc -l`
    else
        set n_tk_issue = 0
    endif
    echo "# found duplicated issue $n_pt_issue $n_tk_issue |$errlog | $issue | $tg"
    if ($n_pt_issue > 2 || $n_tk_issue > 2) then
    else
        echo "# n_line_slide $n_line_slide $n_errlog $n_t"
        if ($n_errlog > $n_t) then
            set n_line_slide = `expr $n_line_slide + $n_errlog`
            set n_current_line_slide = $n_errlog
        else
            set n_line_slide = `expr $n_line_slide + $n_t`
            set n_current_line_slide = $n_t
        endif
        if ($n_line_slide > 14) then
            set n_line_slide = $n_current_line_slide
            echo "#table end#" >> $source_dir/data/${tag}/pptx.spec
            echo "#title#" >> $source_dir/data/${tag}/pptx.spec
            echo "Flow Issue" >> $source_dir/data/${tag}/pptx.spec
            echo "#table#" >> $source_dir/data/${tag}/pptx.spec
            echo "Target|Issue|Tile" >> $source_dir/data/${tag}/pptx.spec
        endif

        echo "$tg|$errlog|$t" >> $source_dir/data/${tag}/pptx.spec
    endif

end
echo "#table end#" >> $source_dir/data/${tag}_spec
echo "#table end#" >> $source_dir/data/${tag}/pptx.spec
python $source_dir/py/spec2pptx.py --spec $source_dir/data/${tag}/pptx.spec --pptx $source_dir/data/${tag}/flow_issue.pptx
source csh/updateTask.csh
