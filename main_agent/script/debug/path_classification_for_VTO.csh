
set model = "/home/xinyucao/ML/ML_tile/train_merged/MI350_AID_balanced_stacked_filtered_clean.DATASET.RandomForestClassifier.model"
set tile_dir = `pwd`
set stage = $argv[1]

###define file list to catch timing report
if ("$stage" == "pretiming") then
    set file_list = ("SortFuncFFG1p05vNoWLHldGrp" "SortFuncTT0p65vNoWLStpGrp" "SortFuncTT0p9vNoWLStpGrp" "SortScanShiftFFG1p05vNoWLHldGrp" "SortScanShiftSSG0p6vNoWLStpGrp")
else if ("$stage" == "route") then
    set file_list = ("SortFuncTT0p65vRouteStpGrp" "SortFuncTT0p9vRouteStpGrp")
else if ("$stage" == "reroute") then
    set file_list = ("SortFuncTT0p65vReRouteStpGrp" "SortFuncTT0p9vReRouteStpGrp")
endif

foreach file ($file_list)
    if ( "$file":q =~ *Stp* ) then
        set full_file = ${tile_dir}/rpts/${file}/S.INTERNAL.sorted.gz
    else if ( "$file":q =~ *Hld* ) then
        set full_file = ${tile_dir}/rpts/${file}/H.INTERNAL.sorted.gz
    endif
    python2.7 /home/xinyucao/ML/ML_tile/for_MI350_AID/feature_extract.py $full_file $file
    echo "Finish feature extract for $file target"  
end


###merge pt needed features into dataset
foreach file ($file_list)
    set corner = `echo $file | sed -e "s/Sort//g" | sed -e "s/StpGrp//g" | sed -e "s/HldGrp//g"`
    set rpt_dir = `find rpts/PtTim*$corner* -maxdepth 0 -type d | grep -v Si`
    if (-r $tile_dir/$rpt_dir/ptsession) then
        echo $tile_dir/$rpt_dir/ptsession
        echo "kickoff ptsession to get more information, please wait..."
        cd $tile_dir/$rpt_dir
        module unload primetime
        module load primetime/2022.03-SP5-T-20221201
        bsub -Ip -P mi350-pd -q regr_high -R 'select[(type==RHEL7_64||type==RHEL6_64)] rusage[mem=24000]' -R 'select[(type==RHEL7_64||type==RHEL6_64)&&(csbatch||gb64||gb128||gb512||gb1024)]' 'pt_shell -f /home/xinyucao/ML/ML_tile/for_MI350_AID/pt_calculation.tcl'
        set wait_file = "margin_info_$file.csv"
        echo "Start at: margin_info_$file.csv"
        cd -
        while (!( -e $wait_file))
            sleep 10
            echo "waiting..."
        end
        echo "start post calculation..."
        python3 /home/xinyucao/ML/ML_tile/for_MI350_AID/merge_csv.py $file
        python2.7 /home/xinyucao/ML/ML_tile/for_MI350_AID/post_cal.py $file
        cat merge_post_${file}.csv  | sed "s/^,start/No,start/g" | sed "s/,,/,0,/g" > feature_extract_issue_category_${file}.csv
    else
        ##touch pt related features
        python3.7 /home/xinyucao/ML/ML_tile/for_MI350_AID/touch_features.py $file
        python3 /home/xinyucao/ML/ML_tile/for_MI350_AID/merge_csv.py $file
        cat merge_${file}.csv  | sed "s/^,start/No,start/g" | sed "s/,,/,0,/g" > feature_extract_issue_category_${file}.csv
    endif
end

###start inference
echo "start inferrence for csv file..."
foreach file ($file_list)

    set dataset = "feature_extract_issue_category_${file}.csv"
    source /home/xinyucao/ML/ML_tile/scripts/start_infer.csh $dataset $model
end
