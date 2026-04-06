# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set lk = `resolve ./`
echo "# generate tile status.."
if (-e tile_status) then
    cd tile_status
    rm -rf *
else
    mkdir tile_status
    cd tile_status
endif
if (-e $lk) then
    unlink $lk
    ln -s $lk
else
    ln -s $lk
endif
set project = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "project," | awk -F "," '{print $2}' | sed 's/\r//g'`
set qorCfg = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "qorCfg," | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_qorCfg = `echo $qorCfg | wc -w`
source $source_dir/csh/env.csh
deactivate
cp -rf $source_dir/script/project/sawatchrange/config.pm ./
if ($n_qorCfg > 0) then
    if (-e $qorCfg) then
        cp  -rf $qorCfg ./
    endif
else 
    if (-e $source_dir/script/project/$project/config.pm) then
        cp -rf $source_dir/script/project/$project/config.pm ./
    endif
else
    echo '$no_email = 1;' > config.pm
    echo '1;' >> config.pm
endif
perl /tools/aticad/1.0/src/zoo/safeng/SARA/gen_data.pl
ln -s index.html tile_status.html

awk '{print $2}' $source_dir/runDir.list > runlist
/tool/aticad/1.0/src/zoo/TileFlowScripts/tile_status/perl_module/extract_info.pl -spreadsheet extract_info.xls -runlist runlist
cd -

