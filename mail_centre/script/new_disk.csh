# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set refDir = $1
set tag = $2
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    New disk has been added:
EOF
echo "#list#" >> $source_dir/data/${tag}_spec
set n_run_dir = 0
set table_used = 0
set refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`
set n_refDir = `echo $refDir | wc -w`
# Detect table based input
if ($n_refDir > 0) then
        python3 $source_dir/script/take_assignment.py --tag $tag --table data/$tag.table --argument assignment.csv 
endif
    
set run_status = "finished"

cd $source_dir
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
