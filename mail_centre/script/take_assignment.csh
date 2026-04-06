# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tag = $1
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    assignemnt.csv has been updated:
EOF
echo "#list#" >> $source_dir/data/${tag}_spec
set n_run_dir = 0
set table_used = 0
# Detect table based input
if (-e data/$tag.table) then
    set n_table = `cat data/$tag.table | wc -w`
    if ($n_table > 0) then
        source csh/env.csh
        python3 $source_dir/script/take_assignment.py --tag $tag --table data/$tag.table --argument assignment.csv 
    endif

endif
    
set run_status = "finished"

cd $source_dir
sed -i 's/ //g' assignment.csv
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
