# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com

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

sleep 10
# This csh is to update runDir and run status
echo "$tag | $run_status | ${target_run_dir} | $tasksModelFile"
set n_target_run_dir = `echo $target_run_dir | wc -w`
if ($n_target_run_dir > 1) then
    if (-e data/$tag/runDir.list) then
    else
       echo $target_run_dir > data/$tag/runDir.list 
    endif
    echo $target_run_dir > data/$tag/runDir.list
else
endif
python $source_dir/py/updateTask.py --tag $tag --status $run_status --reply "replied" --target_run_dir "${target_run_dir}" --source_run_dir "$source_dir" --html $source_dir/data/${tag}_spec.html  --tasksModelFile $tasksModelFile
set  n_instruction = `expr $n_instruction + 1`
