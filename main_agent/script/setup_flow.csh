#set called = ($_)
#if ("$called" != " ") then
#    set script_dir = `readlink -f $called[2]`
#else
#    set script_dir = `readlink -f $0`
#endif
#set flow_dir = `dirname $script_dir`
set flow_dir = $1
echo "# create link from $flow_dir"
#set flow_dir = `echo $flow_dir | sed 's/\/$//g'`
set n_flow_dir = `echo $flow_dir | wc -w`
if ($n_flow_dir == 0) then
    echo "# Need specify flow dir."
    exit
endif
if (-e $flow_dir) then
    echo "# Use $flow_dir"
    if (-e script) then
        rm -rf script
        mkdir script
        cp -rf $flow_dir/* script/
    else
        mkdir script
        cp -rf $flow_dir/* script/
    endif
    if (-e csh) then
        unlink csh
        ln -s script csh
    else
        ln -s script csh
    endif
    if (-e py) then
        unlink py
        ln -s script py
    else
        ln -s script py
    endif
else
    echo "# flow_dir not exists."
endif
set csvs = "instruction.csv keyword.csv command.csv patterns.csv"
foreach csv (`echo $csvs`)
    if (-e $csv) then
        #echo "# Warning: $csv existed, pleae remove it if need updated."
        unlink $csv
        cp -rf $flow_dir/$csv ./
    else
        cp -rf $flow_dir/$csv ./
    endif
end
if (-e assignment.csv) then
else
    cp $flow_dir/assignment.csv ./
endif

if (-e arguement.csv) then
    echo "# Warning: arguement.csv existed, pleae remove it if need updated."
else
    cp $flow_dir/arguement.csv ./
endif
set project = `python3 script/read_csv.py --csv assignment.csv | grep "project," | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_project = `echo $project | wc -w`
if ($n_project > 0) then
    if (-e script/project/$project/debug.csv) then
        cat script/project/$project/debug.csv >> script/debug/debug.csv
    endif
endif

if (-e data) then
else
    mkdir data
endif
if (-e squid/bin/activate.csh) then
    echo "# use local python env."
    set local_activate = `resolve squid/bin/activate.csh`     
    chmod 766 script/env.csh
    echo "source $local_activate" > script/env.csh
endif
echo "# use following script to start Agent"
echo "# Detail assignment.csv settting, please check https://amd.atlassian.net/wiki/spaces/CDCPD/pages/637703729/PD+AI+Agent"
echo "source script/start_vto_man_sep.csh"
