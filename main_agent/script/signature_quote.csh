
# Copyright (c) 2024 Chen, Simon ; simon1.chen@amd.com;  Advanced Micro Devices, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#set tag = $1
#set source_dir = $2
#set target_run_dir = $3
#set run_status = $4
#set reply_full = $5
echo "# Record: $tag | $source_dir | $run_status | ${target_run_dir}"
source csh/env.csh
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
if (-e data/${tag}_csv.html) then
    touch $source_dir/data/${tag}_end_spec
    rm $source_dir/data/${tag}_end_spec
    echo " " >> $source_dir/data/${tag}_end_spec
    echo "Thanks," >> $source_dir/data/${tag}_end_spec
    echo "$vto(PD Agent)" >> $source_dir/data/${tag}_end_spec
    echo " " >> $source_dir/data/${tag}_end_spec
    echo "#line#" >> $source_dir/data/${tag}_end_spec
    echo "#text#" >> $source_dir/data/${tag}_end_spec
    python $source_dir/py/readTask.py --tasksModelFile $tasksModelFile --tag $tag --item mailBody >> $source_dir/data/${tag}_end_spec
    python $source_dir/py/spec2Html.py --spec $source_dir/data/${tag}_end_spec --html $source_dir/data/${tag}_end_spec.html   
    cat $source_dir/data/${tag}_end_spec.html >> $source_dir/data/${tag}_spec.html
    python $source_dir/py/sendMail.py --tag $tag --status $run_status --reply "replied"  --source_dir "$source_dir" --html $source_dir/data/${tag}_spec.html  --tasksModelFile $tasksModelFile --extraMailAddress $extraMailAddress
else
    touch $source_dir/data/${tag}_end_spec
    rm $source_dir/data/${tag}_end_spec
    echo " " >> $source_dir/data/${tag}_spec
    echo "Thanks," >> $source_dir/data/${tag}_spec
    echo "$vto(PD Agent)" >> $source_dir/data/${tag}_spec
    echo " " >> $source_dir/data/${tag}_spec
    echo "#line#" >> $source_dir/data/${tag}_spec
    echo "#text#" >> $source_dir/data/${tag}_spec 
    python $source_dir/py/readTask.py --tasksModelFile $tasksModelFile --tag $tag --item mailBody >> $source_dir/data/${tag}_spec
    python $source_dir/py/spec2Html.py --spec $source_dir/data/${tag}_spec --html $source_dir/data/${tag}_spec.html
    python $source_dir/py/sendMail.py --tag $tag --status $run_status --reply "replied"  --source_dir "$source_dir" --html $source_dir/data/${tag}_spec.html  --tasksModelFile $tasksModelFile --extraMailAddress $extraMailAddress
endif
#python $source_dir/script/updateTask.py --tag $tag --status $run_status --reply "$reply_full" --target_run_dir "${target_run_dir}" --source_dir "$source_dir" --html $source_dir/data/${tag}_spec.html  --tasksModelFile $tasksModelFile
source $source_dir/script/record_usage.csh
