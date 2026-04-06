set table = $1
set tag = $2
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec


cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The predicton for tile congestion as following: 
EOF
cd $source_dir
source csh/env.csh 
cp $source_dir/script/N5.txt training.txt
python $source_dir/py/RF_congestion_train.py
set n = `head -n 1 $table | sed 's/|/ /g' | awk '{print NF}'`
echo $n
if ($n < 11) then
    cat $table | sed 's/|/ /g' | awk '{print $0,0,0}' > input.txt
else
    cat $table | sed 's/|/ /g' > input.txt
endif
python $source_dir/py/evaluate_main.py > $tag.log
grep "#" $tag.log >> $source_dir/data/${tag}_spec
echo "#table#" >> $source_dir/data/${tag}_spec
grep -v "#" $tag.log >> $source_dir/data/${tag}_spec
echo "#table end#" >> $source_dir/data/${tag}_spec

source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
