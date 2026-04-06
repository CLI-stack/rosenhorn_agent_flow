set tag = $1
set task = $2
set run_status = "finished"
set target_run_dir = ":"
set source_dir = `pwd`
source csh/env.csh
echo "# Ignore $task"
set task = `echo $task | sed 's/integr://g'`
echo $task >> ignoreTag.list
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The task has been ignored:
#list#
EOF
echo $task >> $source_dir/data/${tag}_spec
