#set disk = `echo $disk | sed 's/:/ /g'`
set tag = "flow_issue"
mkdir -p data/$tag
set tasksModelFile = "tasksModel.csv"
set t = "NA"
set pre_t = "NA"
set rd_valid = ""
echo "#table#" > data/${tag}_spec
touch data/$tag/flow_issue.sum
rm data/$tag/flow_issue.sum
touch data/$tag/flow_issue.sum
touch data/$tag/test.log
rm data/$tag/*.log
source $source_dir/script/env.csh

set n = 0
touch flow_issue.sum
rm flow_issue.sum
set rd = `pwd`
echo "$rd"
set rd_tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
if (-e tbs.log) then
    set errlog = ""
    foreach tg (`cat tbs.log | awk '{print $2}'`)
        set errlog = ""
        set n_tb_issue = `ls *.$tg.analyze_target.log | wc -w`
        echo "# check $tg $n_tb_issue $rd"
        if ($n_tb_issue > 0) then
            foreach issue (`ls *.$tg.analyze_target.log`)
                echo "# Found $tg issue"
                set errlog = "$errlog ; $rd/$issue"
                set issue_name = `echo $issue | sed 's/\./ /g' |awk '{print $1}'`
                touch data/$tag/$issue_name.$tg.log
                echo "$rd/$issue" >> data/$tag/$issue_name.$tg.log
            end
            echo "$tg | $errlog ; |  $rd_tile ; | $rd ;" >> data/$tag/flow_issue.sum
         endif
    end
endif
echo "target,log,tile,runDir" >> data/${tag}_spec
echo "#title#" > data/${tag}/pptx.spec
echo "Flow Issue" >> data/${tag}/pptx.spec
echo "#table#" >> data/${tag}/pptx.spec
echo "Target|Issues|Tile"  >> data/${tag}/pptx.spec
set n_line_slide = 0
foreach tg (`cat data/$tag/flow_issue.sum | sort -u | awk -F '|' '{print $1}' | sort -u -k 1`)
    set errlog = ""
    foreach issue (`ls data/$tag/*.$tg.log`)
        set n_err = `cat $issue | wc -l`
        echo "process $issue $n_err"
        set issue_n = `echo $issue | sed "s/\.$tg/.${tg}.${n_err}/g"`
        echo "#table#" > $issue_n
        echo "tile,issue" >> $issue_n
        foreach log (`cat $issue`)
            set t = `echo $log | sed 's/\// /g' | awk '{print $4}'`
            echo "$t,$log" >> $issue_n
        end
        echo "#table end#">> $issue_n
        python3 $source_dir/script/spec2Html.py --spec $issue_n --html $issue_n.html
        set errlog = "$errlog ; $rd/$issue_n.html"
    end
    set t = `grep $tg data/$tag/flow_issue.sum | awk -F '|' '{print $3}' | sort -u`
    #set rd = `grep $tg data/$tag/flow_issue.sum | awk -F '|' '{print $4}' | sort -u`
    echo "$tg,$errlog,$t,$rd" >> data/${tag}_spec
    set n_errlog = `echo $errlog | sed 's/;/\n/g' | grep "\S" | wc -l`
    set n_t = `echo $t | sed 's/;/\n/g' | grep "\S" | wc -l`
    set issue = `echo $errlog  | sed 's/;//g' | awk '{print $1}' | awk -F "/" '{print $NF}' | awk -F "." '{print $1}'`
    set n_pt = `echo $tg | grep Pt | wc -w`
    if ($n_pt > 0) then
        set n_pt_issue = `grep "$issue" data/${tag}/pptx.spec | grep Pt | wc -l`
    else
        set n_pt_issue = 0
    endif
    set n_tk = `echo $tg | grep Tk | wc -w`
    if ($n_tk > 0) then
        set n_tk_issue = `grep "$issue" data/${tag}/pptx.spec | grep Tk | wc -l`
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
        echo "# n_line_slide $n_line_slide $n_errlog $n_t $tg"
        if ($n_line_slide > 14) then
            set n_line_slide = $n_current_line_slide
            echo "# Start new slides"
            echo "#table end#" >> data/${tag}/pptx.spec
            echo "#title#" >> data/${tag}/pptx.spec
            echo "Flow Issue" >> data/${tag}/pptx.spec
            echo "#table#" >> data/${tag}/pptx.spec
            echo "Target|Issue|Tile" >> data/${tag}/pptx.spec
        endif

        echo "$tg|$errlog|$t" >> data/${tag}/pptx.spec
    endif
end
echo "#table end#" >> data/${tag}_spec
echo "#table end#" >> data/${tag}/pptx.spec
source $source_dir/script/env.csh
python $source_dir/py/spec2Html.py --spec data/${tag}_spec --html ${tag}.html
python $source_dir/py/spec2pptx.py --spec data/${tag}/pptx.spec --pptx data/${tag}/flow_issue.pptx
