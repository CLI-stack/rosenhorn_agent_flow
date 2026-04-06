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

#  source /tools/aticad/1.0/src/zoo/PD_agent/tile/checklist/gen_checklist_check.csh /tools/aticad/1.0/src/zoo/PD_agent/tile/checklist/template.txt /tools/aticad/1.0/src/zoo/PD_agent/tile/checklist/AT2GMD_NLC_TilePnR_checklist.csv your_llm_ley
set template = $1
set checklist_csv = $2
set llm_key = $3
if (-e prompt) then
    rm -rf prompt
    mkdir prompt
else
    mkdir prompt
endif

if (-e csh) then
    rm -rf csh
    mkdir csh
else
    mkdir csh
endif


python3 /tools/aticad/1.0/src/zoo/PD_agent/tile/checklist/gen_prompt.py --t $template --c $checklist_csv

foreach pr (`ls prompt/*.prompt`)
    echo "### Generate script for $pr"
    set contextFile = "$pr"
    set question = ""
    source /tools/aticad/1.0/src/zoo/PD_agent/tile/env.csh
    deactivate
    python3 /tools/aticad/1.0/src/zoo/PD_agent/tile/llm.py --key $llm_key --question "$question" --contextFile $contextFile | tee llm.log
    set csh_name = `echo $contextFile | sed 's/\// /g' | awk '{print $2}'`
    egrep -v "Read context|Read basic PD knowledge" llm.log | sed -n '/#####/,/#####/p' > csh/$csh_name.csh
    #sed -n '/```/,/```/p' llm.log | sed '/```/d' > llm_output.py
    source /tools/aticad/1.0/src/zoo/PD_agent/tile/env.csh
    sleep 10
end

