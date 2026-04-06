# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
# merge_csv.py
# post_cal.py
# start_infer.csh
# touch_features.py
# path_classification_simplified.llm.csh
set tile = $1
set runDir = $2
set refDir = $3
set clk = $4
set tag = $5
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`

set tile_filter = ""
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
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
if ($n_tile_filter == 0 && $n_tile > 0 && $n_refDir == 0) then
    echo "I don't own $tile or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    set run_status = "failed"
    exit
endif
set n_clk = `echo $clk | sed 's/:/ /g' | sed 's/clk//g' | wc -w`
if ($n_clk == 0) then
    echo "CLK name not specified, so place timing will not be available." >> $source_dir/data/${tag}_spec
else
    set clk = `echo $clk | sed 's/://g' | sed 's/clk//g'`
endif

if ($n_tile == 0) then
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif
set llmKey = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "llmKey,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_llmKey = `echo $llmKey | wc -w`
if ($n_llmKey == 0) then
    #echo "## LLM key is not available, please check assignment.csv" >> $source_dir/data/${tag}_spec 
else
    echo "#list#" >> $source_dir/data/${tag}_spec 
    echo "You can check in browser: $source_dir/data/${tag}_spec.html" >> $source_dir/data/${tag}_spec
    echo "Slides: $source_dir/data/${tag}/timing_issue.pptx" >> $source_dir/data/${tag}_spec

endif
set eff_rd = ""
if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        # Identify if it is run dir
        if (-e $rd/tile.params) then
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set eff_rd = "$eff_rd $rd"
            set is_eco = `grep PERSONALITY $rd/override.params | grep eco | wc -w`
        else
        # Identify if it is dir with all run dir link
            foreach lrd (`ls -1d $rd/*`)
                if (-e $lrd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $lrd/tile.params | grep -v "#" | awk '{print $3}'`
                    set eff_rd = "$eff_rd $lrd"
                    echo "# found link $lrd"
                    set is_eco = `grep PERSONALITY $lrd/override.params | grep eco | wc -w`
                endif
            end

            foreach lrd (`ls -1d $rd/*/latest/workspace`)
                if (-e $lrd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $lrd/tile.params | grep -v "#" | awk '{print $3}'`
                    set eff_rd = "$eff_rd $lrd"
                    echo "# found release $lrd"
                    set is_eco = `grep PERSONALITY $lrd/override.params | grep eco | wc -w`
                endif
            end

        endif

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

foreach rd (`echo $eff_rd`)
    cd $rd
    source $source_dir/script/env.csh    
    source $source_dir/script/extract_all_path.csh
    if (-e extract_all_path.html) then
        echo "Full report: $rd/extract_all_path.html" >> $source_dir/data/${tag}_spec
    endif
end
cd $source_dir
set project = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "project," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r//g'`
set lsfProject = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "lsfProject," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r//g'`
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,timing_path,analysis" >> $source_dir/data/${tag}_spec
echo "#title#" >> $source_dir/data/${tag}/pptx.spec
echo "Timing Issue" >> $source_dir/data/${tag}/pptx.spec
echo "#table#" >> $source_dir/data/${tag}/pptx.spec
echo "tile|timing_path|analysis"  >> $source_dir/data/${tag}/pptx.spec

foreach rd (`echo $eff_rd`)
    if ($n_llmKey == 0) then
    endif
    cd $rd
    set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_pretiming = `ls rpts/Sort*NoWLStpGrp/S.INTERNAL.sorted.gz | wc -w`
    set check_timing_func = `ls rpts/PtPreTimFuncTT0p*PretimingNOWL*/check_timing.rpt.gz | head -n 1`
    set n_check_timing_func = `echo $check_timing_func | wc -w`
    set check_timing_scan = `ls rpts/PtPreTimScanShif*/check_timing.rpt.gz | head -n 1`
    set n_check_timing_scan = `echo $check_timing_scan | wc -w`
    set tile = `grep TILES_TO_RUN override.params | grep -v "#" | awk '{print $3}' | sort -u`
    set n_line_slide = 0
    source $source_dir/script/env.csh
    if ($n_check_timing_func > 0) then
        set n_noclk = `python3 $source_dir/script/extract_check_timing.py --rpt $check_timing_func --item no_clock | awk '{print $1}'`
        set rpt = `python3 $source_dir/script/extract_check_timing.py --rpt $check_timing_func --item no_clock |  awk '{print $7}'`
        echo "$tile,$rpt,no clock: $n_noclk" >> $source_dir/data/${tag}_spec
        echo "$tile|$rpt|no clock: $n_noclk" >> $source_dir/data/${tag}/pptx.spec
        set n_line_slide = `expr $n_line_slide + 1`
    endif
    if ($n_check_timing_scan > 0) then
        set n_noclk = `python3 $source_dir/script/extract_check_timing.py --rpt $check_timing_scan --item no_clock | awk '{print $1}'`
        set rpt = `python3 $source_dir/script/extract_check_timing.py --rpt $check_timing_scan --item no_clock |  awk '{print $7}'`
        echo "$tile,$rpt,no clock: $n_noclk" >> $source_dir/data/${tag}_spec
        echo "$tile|$rpt|no clock: $n_noclk" >> $source_dir/data/${tag}/pptx.spec
        set n_line_slide = `expr $n_line_slide + 1`
    endif
    if ($n_line_slide > 14) then
        set n_line_slide = $n_current_line_slide
        echo "#table end#" >> $source_dir/data/${tag}/pptx.spec
        echo "#title#" >> $source_dir/data/${tag}/pptx.spec
        echo "Timing Issue" >> $source_dir/data/${tag}/pptx.spec
        echo "#table#" >> $source_dir/data/${tag}/pptx.spec
        echo "Tile|Timing_path|Analysis" >> $source_dir/data/${tag}/pptx.spec
    endif

end
echo "#table end#" >> $source_dir/data/${tag}/pptx.spec

echo "#table end#" >> $source_dir/data/${tag}_spec
echo "" >> $source_dir/data/${tag}_spec

echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,timing_path,analysis" >> $source_dir/data/${tag}_spec
echo "#title#" >> $source_dir/data/${tag}/pptx.spec
echo "Timing Issue" >> $source_dir/data/${tag}/pptx.spec
echo "#table#" >> $source_dir/data/${tag}/pptx.spec
echo "tile|timing_path|analysis"  >> $source_dir/data/${tag}/pptx.spec
foreach rd (`echo $eff_rd`)
    if ($n_llmKey == 0) then
    endif
    cd $rd

    touch path_classification_simplified/llm.spec
    rm path_classification_simplified/llm.spec

    set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_pretiming = `ls rpts/Sort*NoWLStpGrp/S.INTERNAL.sorted.gz | wc -w`
    set check_timing_func = `ls rpts/PtPreTimFuncTT0p*PretimingNOWL*/check_timing.rpt.gz | head -n 1`
    set n_check_timing_func = `echo $check_timing_func | wc -w`
    set check_timing_scan = `ls rpts/PtPreTimScanShif*/check_timing.rpt.gz | head -n 1`
    set n_check_timing_scan = `echo $check_timing_scan | wc -w`
    set tile = `grep TILES_TO_RUN override.params | grep -v "#" | awk '{print $3}' | sort -u`
    set n_line_slide = 0
    if ($n_clk > 0) then
        set n_place = `ls rpts/FxPixPlace/FuncTT0p*v_${clk}_max.rpt.gz | head -n 1 | wc -w`
        echo "# check place timing $clk | $n_place"
    else
        set n_place = 0

    endif

    set n_route = `ls rpts/Sort*StpRoute*/S.INTERNAL.sorted.gz  rpts/Sort*RouteStp*/S.INTERNAL.sorted.gz | wc -w`
    set n_reroute = `ls rpts/Sort*StpReRoute*/S.INTERNAL.sorted.gz rpts/Sort*ReRouteStp*/S.INTERNAL.sorted.gz | wc -w`
    echo "$rd | $n_pretiming | $n_route | $n_reroute | $project"
    if ($n_pretiming > 0) then
        source $source_dir/script/env.csh
        deactivate
        #echo "Check pretiming:" >> $source_dir/data/${tag}_spec
        echo "source $source_dir/script/path_classification_simplified.llm.csh pretiming"
        source $source_dir/script/path_classification_simplified.llm.csh pretiming
        cat path_classification_simplified/llm.spec >> $source_dir/data/${tag}_spec
        
    endif

    if ($n_place > 0) then
        source $source_dir/script/env.csh
        deactivate
        #echo "Check pretiming:" >> $source_dir/data/${tag}_spec
        echo "source $source_dir/script/path_classification_simplified.llm.csh place"
        source $source_dir/script/path_classification_simplified.llm.csh place 
        cat path_classification_simplified/llm.spec >> $source_dir/data/${tag}_spec

    endif

    if ($n_route > 0) then
        source $source_dir/script/env.csh
        deactivate
        #echo "#list#" >> $source_dir/data/${tag}_spec
        #echo "Check routing timing:" >> $source_dir/data/${tag}_spec
        source $source_dir/script/path_classification_simplified.llm.csh route
        echo "source $source_dir/script/path_classification_simplified.llm.csh route"
        cat path_classification_simplified/llm.spec >> $source_dir/data/${tag}_spec
    endif
    if ($n_reroute > 0) then
        source $source_dir/script/env.csh
        deactivate
        #echo "#list#" >> $source_dir/data/${tag}_spec
        #echo "Check reroute timing:"
        echo "source $source_dir/script/path_classification_simplified.llm.csh reroute"
        source $source_dir/script/path_classification_simplified.llm.csh reroute
        cat path_classification_simplified/llm.spec >> $source_dir/data/${tag}_spec
    endif
end
echo "#table end#" >> $source_dir/data/${tag}/pptx.spec

echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
python3 $source_dir/py/spec2pptx.py --spec $source_dir/data/${tag}/pptx.spec --pptx $source_dir/data/${tag}/timing_issue.pptx
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
