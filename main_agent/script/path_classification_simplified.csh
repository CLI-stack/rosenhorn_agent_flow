#!/bin/csh

###usage: source /proj/cmb_pnr_vol21/leonz/timing_classification_450_update/path_classification_for_VTO_update.csh route "/proj/cmb_pnr_vol21/leonz/timing_classification_450/ML/ML_tile/train_merged/MI350_AID_balanced_stacked_filtered_clean.DATASET.RandomForestClassifier.model" csv_file mi400-pd primetime/2022.03-SP5-T-20221201 

#set model = "/proj/cmb_pnr_vol21/leonz/timing_classification_450/ML/ML_tile/train_merged/MI350_AID_balanced_stacked_filtered_clean.DATASET.RandomForestClassifier.model"
set tile_dir = `pwd`
set stage = $argv[1]
set csv_path = "path_classification_simplified"
mkdir $csv_path
###define file list to catch timing report
if ("$stage" == "pretiming") then
    set file_list = ""
    set stp = `ls -1d rpts/Sort*NoWL* |sed 's/rpts\// /g' | awk '{print $1}' | grep Stp | head -n 1`
    set file_list = "$file_list $stp"
    set hld = `ls -1d rpts/Sort*NoWL* |sed 's/rpts\// /g' | awk '{print $1}' | grep Hld | head -n 1`
    set file_list = "$file_list $hld"
else if ("$stage" == "route") then
    #set file_list = ("SortFuncTT0p65vRouteStpGrp" "SortFuncTT0p9vRouteStpGrp")
    set file_list = ("SortFuncStpRouteGrp")    
else if ("$stage" == "reroute") then
    #set file_list = ("SortFuncTT0p65vReRouteStpGrp" "SortFuncTT0p9vReRouteStpGrp")
    set file_list = ("SortFuncStpReRouteSxGrp")
endif
echo $file_list
foreach file ($file_list)
    if ( "$file":q =~ *Stp* ) then
        set full_file = rpts/${file}/S.INTERNAL.sorted.gz
    else if ( "$file":q =~ *Hld* ) then
        set full_file = rpts/${file}/H.INTERNAL.sorted.gz
    endif
    echo "# start to check $tile_dir/$full_file"
    zgrep "Path from" $full_file | awk '{print $4}' | sed 's@rpts/@@g' | sed 's@/report_timing.rpt.gz@@g' |  sed 's@/si_report_timing.rpt.gz@@g' | sort -u > path_classification_simplified/corner.$file.$stage.list 
    python2.7 $source_dir/script/feature_extract.py $full_file $file
    mv feature_extract_$file.csv path_classification_simplified 
    echo "Finish feature extract for $file target"
end

echo "# generate pt margin extraction tcl"
foreach file ($file_list)
    foreach corner (`cat path_classification_simplified/corner.$file.$stage.list`)
        echo "set corner $file" > path_classification_simplified/$corner.tcl
        cat "$source_dir/script/feature_extract.tcl" >> path_classification_simplified/$corner.tcl
        set full_tcl = `resolve  path_classification_simplified/$corner.tcl`
        touch TileBuilderLoadTiming.finished
        rm TileBuilderLoadTiming.finished
        TileBuilderTerm -x "TileBuilderLoadTiming --nosi cmds/$corner.cmd --append $full_tcl"
        source $source_dir/script/wait_file_finish.csh TileBuilderLoadTiming.finished
        break
    end
end

echo "### merge pt needed features into dataset"
foreach file ($file_list)
    python3 $source_dir/script/merge_csv.py $file path_classification_simplified
    python2.7 $source_dir/script/post_cal.py $file path_classification_simplified
    cat path_classification_simplified/merge_post_${file}.csv  | sed "s/^,start/No,start/g" | sed "s/,,/,0,/g" > path_classification_simplified/feature_extract_issue_category_${file}.csv
    python3 $source_dir/script/remove_zero_column.py --incsv path_classification_simplified/feature_extract_issue_category_${file}.csv --outcsv path_classification_simplified/nonZero_${stage}_${file}.csv
    python3 $source_dir/script/path_classification_simplified.py --incsv path_classification_simplified/nonZero_${stage}_${file}.csv --outcsv path_classification_simplified/final_${stage}_${file}.csv
end

