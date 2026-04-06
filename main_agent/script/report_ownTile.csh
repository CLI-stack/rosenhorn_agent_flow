# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set tag = $2
set source_dir = `pwd`
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    My owned tiles are:
EOF
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,description" >> $source_dir/data/${tag}_spec
foreach t (`echo $tile | sed 's/:/ /g'`)
    echo "$t," >> $source_dir/data/${tag}_spec
end
echo "#table end#" >> $source_dir/data/${tag}_spec
set run_status = "finished"
source csh/env.csh
source csh/updateTask.csh
