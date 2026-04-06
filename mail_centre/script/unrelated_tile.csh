set tag = $1
set source_dir = `pwd`
touch $source_dir/data/${tag}_spec
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    I don't own these tiles.
EOF
set run_status = "finished"
source csh/env.csh
source csh/updateTask.csh
