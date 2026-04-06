set lk = `resolve ./`
echo "# generate tile status."
if (-e tile_status) then
    cd tile_status
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
source $source_dir/csh/env.csh
deactivate
if (-e $source_dir/script/project/$project/config.pm) then
    cp -rf $source_dir/script/project/$project/config.pm ./
endif
if (-e $source_dir/script/project/$project/gen_data.pl) then
    perl $source_dir/script/project/$project/gen_data.pl
else
    perl /tools/aticad/1.0/src/zoo/safeng/SARA/gen_data.pl
endif
ln -s index.html tile_status.html

