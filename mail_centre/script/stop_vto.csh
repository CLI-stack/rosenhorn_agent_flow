set tag = $1
set run_status = "finished"
set target_run_dir = ":"
set source_dir = `pwd`
touch run.stop
#xterm -hold -T "vto_$tag" -e "source $source_dir/script/run.csh > run.log" 
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The virtual tile owner has been stopped.
EOF
source csh/env.csh
set run_status = "started"
source csh/updateTask.csh
