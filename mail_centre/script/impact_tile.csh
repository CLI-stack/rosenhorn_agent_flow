set tile = $1
set runDir = $2
set refDir = $3
set edatool = $4
set tag = $5
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec
echo "set tile = $tile" > $source_dir/data/${tag}/set_tile.csh
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
