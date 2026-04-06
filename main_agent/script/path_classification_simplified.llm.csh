#!/bin/csh

###usage: source /proj/cmb_pnr_vol21/leonz/timing_classification_450_update/path_classification_for_VTO_update.csh route "/proj/cmb_pnr_vol21/leonz/timing_classification_450/ML/ML_tile/train_merged/MI350_AID_balanced_stacked_filtered_clean.DATASET.RandomForestClassifier.model" csv_file mi400-pd primetime/2022.03-SP5-T-20221201 

#set model = "/proj/cmb_pnr_vol21/leonz/timing_classification_450/ML/ML_tile/train_merged/MI350_AID_balanced_stacked_filtered_clean.DATASET.RandomForestClassifier.model"
set tile_dir = `pwd`
set n_path = 3
set stage = $argv[1]
set csv_path = "path_classification_simplified"
if (-e $csv_path) then
else
    mkdir $csv_path
endif
###define file list to catch timing report
set llmKey = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "llmKey,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
if ("$stage" == "pretiming") then
    set file_list = ""
    set stp = `ls -1d rpts/SortFuncTT0p*NoWL* |sed 's/rpts\// /g' | awk '{print $1}' | grep Stp | head -n 1`
    set file_list = "$file_list $stp"
    set hld = `ls -1d rpts/Sort*NoWL* |sed 's/rpts\// /g' | awk '{print $1}' | grep Hld | head -n 1`
    set file_list = "$file_list $hld"
else if ("$stage" == "place") then
    set n_place = `ls rpts/FxPixPlace/FuncTT0p*v_${clk}_max.rpt.gz | head -n 1 | wc -w`
    if ($n_place > 0) then
        set file_list = "FxPixPlace"
    endif
else if ("$stage" == "route") then
    #set file_list = ("SortFuncTT0p65vRouteStpGrp" "SortFuncTT0p9vRouteStpGrp")
    set n_route = `ls rpts/Sort*StpRoute*/S.INTERNAL.sorted.gz | wc -w`
    if ($n_route > 0) then
        set file_list = ("SortFuncStpRouteGrp")    
    else
        set file_list = ("SortFuncRouteStpGrp")
    endif
else if ("$stage" == "reroute") then
    #set file_list = ("SortFuncTT0p65vReRouteStpGrp" "SortFuncTT0p9vReRouteStpGrp")
    set n_reroute = `ls rpts/Sort*StpReRoute*/S.INTERNAL.sorted.gz | wc -w`
    if ($n_reroute > 0) then
        set file_list = ("SortFuncStpReRouteSxGrp")
    else
        set file_list = ("SortFuncReRouteStpGrp")
    endif

endif
echo $file_list
set tile = `grep TILES_TO_RUN override.params | grep -v "#" | awk '{print $3}' | sort -u`
foreach file ($file_list)
    if ( "$file":q =~ *Stp* ) then
        set full_file = rpts/${file}/S.INTERNAL.sorted.gz
        set type = "S"
    else if ( "$file":q =~ *Hld* ) then
        set full_file = rpts/${file}/H.INTERNAL.sorted.gz
        set type = "H"
    else 
        set full_file = `ls rpts/FxPixPlace/FuncTT0p*v_${clk}_max.rpt.gz | head -n 1`
        set type = "S"
    endif
    #echo "Start to check $tile_dir/$full_file" >> path_classification_simplified/llm.spec
    set n = 1 
    set n_viol = `zgrep "No violating" $full_file | wc -w` 
    if ($n_viol > 0) then
        continue
    endif
    echo "# check $tile_dir/$full_file"
    while(1)
        #chmod 755 path_classification_simplified/contextFile
        python3 $source_dir/script/extract_path.py --rpt $full_file --n $n --o path_classification_simplified/${stage}_${type}_${n}_path.log
        set issue_list = `cat timing_issue.list`
        set n_path_size = `cat path_classification_simplified/${stage}_${type}_${n}_path.log | wc -w`
        if ($n_path_size < 10) then
            set n = `expr $n + 1`
            if ($n > $n_path) then
                break
            endif
            continue
        endif
        cp -rf $source_dir/script/path_classification_simplified.prompt path_classification_simplified/contextFile
        cat  path_classification_simplified/${stage}_${type}_${n}_path.log >> path_classification_simplified/contextFile
        touch none.csv
        source /tools/aticad/1.0/src/sysadmin/cpd.cshrc
        setenv AMDLSFCLUSTER atl02
        source /tool/pandora/etc/lsf/cshrc.lsf
        module load calibre/2021.3_15.9

        #set analysis = `python3 $source_dir/script/llm.py --key $llmKey --question "###" --contextFile path_classification_simplified/contextFile | egrep -v "Read context|Read basic PD knowledge" | tail -n 1 | sed 's/,/\./g'`
        echo "$tile,$tile_dir/path_classification_simplified/${stage}_${type}_${n}_path.log,$issue_list" >> path_classification_simplified/llm.spec
        set n_issue = `echo $issue_list | sed 's/;/\n/g' | grep "\S" | wc -l`
        set n_line_slide = `expr $n_line_slide + $n_issue`
        set n_current_line_slide = $n_issue
        endif
        if ($n_line_slide > 14) then
            set n_line_slide = $n_current_line_slide
            echo "#table end#" >> $source_dir/data/${tag}/pptx.spec
            echo "#title#" >> $source_dir/data/${tag}/pptx.spec
            echo "Timing Issue" >> $source_dir/data/${tag}/pptx.spec
            echo "#table#" >> $source_dir/data/${tag}/pptx.spec
            echo "Tile|Timing_path|Analysis" >> $source_dir/data/${tag}/pptx.spec
        endif
        echo "$tile|$tile_dir/path_classification_simplified/${stage}_${type}_${n}_path.log|$issue_list" >> $source_dir/data/${tag}/pptx.spec
        set n = `expr $n + 1`
        if ($n > $n_path) then
            break
        endif
    end
end
