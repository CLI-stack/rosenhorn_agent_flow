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

set mailFile = $1
set tasksModelFile = $2
set instructionFile = $3
set preLLMFile = $4
set llmMailFile = $5
set source_dir = `pwd`
source csh/env.csh
echo "# Generate mail list"
source script/gen_mail_index.csh
if (-e $tasksModelFile.lock) then
    rm $tasksModelFile.lock
endif

touch runDir.list
rm runDir.list
touch runDir.list
foreach rd (` cat data/*/runDir.list | sed 's/:/ /g' | sort -u`)
    if (-e $rd && -e $rd/tile.params) then
        echo $rd >> runDir.list
    endif
end
cat runDir.list | sort -u > runDir.tmp.list
cp runDir.tmp.list runDir.list
rm runDir.tmp.list
set llmFormatter = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "llmFormatter,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
set n_llmFormatter = `echo $llmFormatter | wc -w`
if ($n_llmFormatter == 0) then
    set llmFormatter = 1
endif

if (-e $tasksModelFile.lock) then
    echo "# Tasks are locked."
else
    touch $tasksModelFile.lock
    #perl $source_dir/script/readTaskMail.pl $mailFile 
    python $source_dir/py/vtoHybridModel.py --mailFile $mailFile --tasksModelFile $tasksModelFile --instructionFile $instructionFile
    rm $tasksModelFile.lock
endif
echo "# Sleep 20s to wait vtoExecute.csh create spec."
sleep 20
