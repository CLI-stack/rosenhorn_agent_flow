set tag = $1
set run_status = "finished"
set target_run_dir = ":"
set source_dir = `pwd`
if (-e run.stop) then
    rm run.stop
endif
#xterm -hold -T "vto_$tag" -e "source csh/run.csh > run.log" 
#xterm -hold -e "source csh/run.csh $tag | tee  run.log" &
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
xterm -hold -T "$vto" -e "source csh/run.csh $tag" &
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The virtual tile owner has been started.
EOF
source csh/env.csh
set run_status = "started"
source csh/updateTask.csh
