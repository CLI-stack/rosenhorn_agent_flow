# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tag = $1
set run_status = "finished"
set target_run_dir = ":"
set source_dir = `pwd`
echo "# ~/aigc/list_instruction.csh $tag "
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The instruction is following table:
EOF
source csh/env.csh
touch $source_dir/data/${tag}_spec.html
rm $source_dir/data/${tag}_spec.html
python $source_dir/py/spec2Html.py --spec $source_dir/data/${tag}_spec --html $source_dir/data/${tag}_spec.html
python $source_dir/py/csv2html.py --csv $source_dir/instruction.csv --html data/${tag}_csv.html
cat data/${tag}_csv.html >> $source_dir/data/${tag}_spec.html
source csh/updateTask.csh
