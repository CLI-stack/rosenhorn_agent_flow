if (-e tile_status_temp) then
    rm -rf tile_status_temp
    mkdir tile_status_temp
else
    mkdir tile_status_temp
endif
cd tile_status_temp
echo "NickName,run_dir" > nickname_dir.list
set n_runDir = `grep "/proj" $source_dir/runDir.list | wc -l`
if ($n_runDir > 0) then
    foreach lk (` cat  $source_dir/runDir.list | sort -u | sort -k 1 | awk '{print $1}' `)
        set nickname = `echo $lk | awk -F "/" '{print $NF}'`
        echo "$nickname,$lk" >> nickname_dir.list
        set lk = `resolve $lk`
        echo "# link $lk"
        ln -s $lk
    end
    deactivate
    if (-e $source_dir/script/project/$project/config.pm) then
        cp -rf $source_dir/script/project/$project/config.pm ./
    endif

    perl /tools/aticad/1.0/src/zoo/safeng/SARA/gen_data.pl
    cd $source_dir
    if (-e tile_status) then
        rm -rf tile_status
        cp -rf tile_status_temp tile_status
    else
        cp -rf tile_status_temp tile_status
    endif
    echo "### use tasksModelFile to extract purpose, extract status for LLM."
    source script/env.csh
    python3 $source_dir/script/gen_run_status.py --tasksModelFile tasksModel.csv --statusFile tile_status/run_status.csv
endif
cd $source_dir
if (-e tile_status/index.html) then
    if (-e tile_status.html) then
    else
        ln -s tile_status/index.html tile_status.html
    endif
endif
