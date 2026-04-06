#!/bin/csh

###usage: source /proj/cmb_pnr_vol21/leonz/timing_classification_450_update/path_classification_for_VTO_update.csh route "/proj/cmb_pnr_vol21/leonz/timing_classification_450/ML/ML_tile/train_merged/MI350_AID_balanced_stacked_filtered_clean.DATASET.RandomForestClassifier.model" csv_file mi400-pd primetime/2022.03-SP5-T-20221201 

#set model = "/proj/cmb_pnr_vol21/leonz/timing_classification_450/ML/ML_tile/train_merged/MI350_AID_balanced_stacked_filtered_clean.DATASET.RandomForestClassifier.model"
set tile_dir = `pwd`
set stage = $argv[1]
set model = $argv[2]
set csv_path = $argv[3]
set lsf = $argv[4]
set pt_module = $argv[5]

mkdir $csv_path
###define file list to catch timing report
if ("$stage" == "pretiming") then
    set file_list = ("SortFuncFFG1p05vNoWLHldGrp" "SortFuncTT0p65vNoWLStpGrp" "SortFuncTT0p9vNoWLStpGrp" "SortScanShiftFFG1p05vNoWLHldGrp" "SortScanShiftSSG0p6vNoWLStpGrp")
else if ("$stage" == "route") then
    #set file_list = ("SortFuncTT0p65vRouteStpGrp" "SortFuncTT0p9vRouteStpGrp")
    set file_list = ("SortFuncStpRouteGrp")    
else if ("$stage" == "reroute") then
    #set file_list = ("SortFuncTT0p65vReRouteStpGrp" "SortFuncTT0p9vReRouteStpGrp")
    set file_list = ("SortFuncStpReRouteSxGrp")

endif
foreach file ($file_list)
    echo "Start feature extract for $file target"
    if ( "$file":q =~ *Stp* ) then
        set full_file = ${tile_dir}/rpts/${file}/S.INTERNAL.sorted.gz
    else if ( "$file":q =~ *Hld* ) then
        set full_file = ${tile_dir}/rpts/${file}/H.INTERNAL.sorted.gz
    endif
    python2.7 $source_dir/script/feature_extract.py $full_file $file $csv_path
    echo "Finish feature extract for $file target"
end


###merge pt needed features into dataset
foreach file ($file_list)
    set corner = `echo $file | sed -e "s/Sort//g" | sed -e "s/StpGrp//g" | sed -e "s/HldGrp//g"`
    #set rpt_dir = `find rpts/PtTim*$corner* -maxdepth 0 -type d | grep -v Si`
    set rpt_dir = `find rpts/PtTim*$corner* -maxdepth 0 -type d | grep -v Sx`
    echo $rpt_dir

    if (-r $tile_dir/$rpt_dir/ptsession) then
        echo $tile_dir/$rpt_dir/ptsession
        echo "kickoff ptsession to get more information, please wait..."
        cd $tile_dir/$rpt_dir
        #module load primetime/2022.03-SP5-T-20221201
        set pt_cmd = "module load $pt_module"
        eval $pt_cmd
        #bsub -P mi350-pd -q regr_high -R 'select[(type==RHEL7_64||type==RHEL6_64)] rusage[mem=24000]' -R 'select[(type==RHEL7_64||type==RHEL6_64)&&(csbatch||gb64||gb128||gb512||gb1024)]' 'pt_shell -f /proj/cmb_pnr_vol21/leonz/timing_classification_450/ML/ML_tile/for_MI350_AID/pt_calculation.tcl'
        set queue_cmd = "bsub -P $lsf -q regr_high -R 'select[(type==RHEL7_64||type==RHEL6_64)] rusage[mem=24000]' -R 'select[(type==RHEL7_64||type==RHEL6_64)&&(csbatch||gb64||gb128||gb512||gb1024)]' 'pt_shell -f /proj/cmb_pnr_vol21/leonz/timing_classification_450/ML/ML_tile/for_MI350_AID/pt_calculation.tcl'"
        eval $queue_cmd
        set wait_file = "margin_info_$file.csv"
        echo "Start at: margin_info_$file.csv"
        cd -
        while (!( -e $wait_file))
            sleep 10
            echo "waiting..."
        end
        echo "start post calculation..."
        python3 $source_dir/script/merge_csv.py $file $csv_path
        python2.7 $source_dir/script/post_cal.py $file $csv_path 
        #cat /proj/cmb_pnr_vol21/leonz/timing_classification_450/merge_post_${file}.csv  | sed "s/^,start/No,start/g" | sed "s/,,/,0,/g" > $tile_dir/feature_extract_issue_category_${file}.csv
        cat $csv_path/merge_post_${file}.csv  | sed "s/^,start/No,start/g" | sed "s/,,/,0,/g" > $tile_dir/feature_extract_issue_category_${file}.csv

    else
        ##touch pt related features
        python3.7 $source_dir/script/touch_features.py $file $csv_path
        python3 $source_dir/script/merge_csv.py $file $csv_path
        cat $csv_path/merge_${file}.csv  | sed "s/^,start/No,start/g" | sed "s/,,/,0,/g" > $tile_dir/feature_extract_issue_category_${file}.csv
    endif
end

###start inference
echo "start inferrence for csv file..."
foreach file ($file_list)
    set dataset = "$tile_dir/feature_extract_issue_category_${file}.csv"
    echo "source $source_dir/script/start_infer.csh $dataset $model"
    source $source_dir/script/start_infer.csh $dataset $model
end
