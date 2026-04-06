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

# FCT_CENTER/FCT_ECO
# 10.xxx.xx.xx
set dbip = $1
source /tools/aticad/1.0/src/zoo/PD_agent/tile/env.csh
# assuming the eco is printed as following:
# source -e -v /proj/xxx/FCT_CENTER/FCT_ECO/.../$tile.eco
foreach eco (`grep "source -e -v" data/GetEcoNewCmd.eco | zgrep -w "FCT_ECO" | awk '{print $4}'`)
    if (-e $eco) then
    else
        continue
    endif
    set func = `echo $eco | sed 's/\// /g' | awk '{print $(NF-1)}'`
    python3  /tools/aticad/1.0/src/zoo/PD_agent/tile/fcteco_alert.py --eco $eco --ip $dbip --db fcteco --user fctagent --psw 111111
end

