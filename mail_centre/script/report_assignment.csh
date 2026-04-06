# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tag = $1
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    assignment.csv is following:
EOF
echo "#list#" >> $source_dir/data/${tag}_spec
set n_run_dir = 0
set table_used = 0
# Detect table based input
echo "#table#" >> $source_dir/data/${tag}_spec
echo "item,value" >> $source_dir/data/${tag}_spec
python3 $source_dir/script/read_csv.py --csv assignment.csv >> $source_dir/data/${tag}_spec
echo "#table end#" >> $source_dir/data/${tag}_spec
    
set run_status = "finished"

cd $source_dir
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
