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

source csh/env.csh
source $source_dir/script/unalias.csh
set tasksModelFile = $1
set runCsh = $2
#cp tasksModel.bk.csv tasksModel.csv 
if (-e vto_debug) then
    set debug = 1
else
    set debug = 0
endif
set source_dir = `pwd`
if (-e $tasksModelFile.lock) then
    rm $tasksModelFile.lock
endif
if (-e runs) then
else
    mkdir runs
endif
set id = `date | sed 's/ /_/g'`
set runCsh = "runs/runExecution_${id}.csh"
set runLog = "runs/runExecution_${id}.log"

#while(1)
    set dir_orig = `pwd`
    if (-e $tasksModelFile.lock) then
        echo "# Tasks are locked."
    else
        touch $tasksModelFile.lock
        echo "# Extract csh."
        set tag = `python $source_dir/py/vtoExecution.py --tasksModelFile $tasksModelFile --runCsh $runCsh | grep "# Generate task" | sort -u | awk '{print $4}' | sed 's/\r//g'`
        set runLog = "runs/$tag.log"
        cat $runCsh
        set n_runCsh = `cat $runCsh | wc -w`
        
        if ($n_runCsh > 0) then
            cat $runCsh > runs/$tag.csh
            set runCsh = "runs/$tag.csh"
            set lsfProject = `python3 $source_dir/script/read_csv.py --csv assignment.csv | grep "lsfProject," | awk -F "," '{print $2}'`
            set n_lsfProject = `echo $lsfProject | wc -w`
            set n_noLsf = `grep noLsf  $runCsh | wc -w`
            set noXterm = `python3 $source_dir/script/read_csv.py --csv assignment.csv | grep "noXterm," | awk -F "," '{print $2}'`
            set n_noXterm = `echo $noXterm | wc -w`
            if ($debug == 1) then
                echo "# Execute csh in debug mode."
                if ($n_lsfProject > 0 && $n_noLsf == 0) then
                    if ($n_noXterm > 0) then
                        bsub -P $lsfProject -q regr_high -R 'select[type==RHEL7_64] rusage[mem=10000]' -R 'select[(type==RHEL7_64||type==RHEL8_64)&&(csbatch||gb64||gb128||tmplongforce)]' -o $runLog /bin/csh $runCsh
                    else
                        bsub -P $lsfProject -q regr_high -R 'select[type==RHEL7_64] rusage[mem=10000]' -R 'select[(type==RHEL7_64||type==RHEL8_64)&&(csbatch||gb64||gb128||tmplongforce)]' xterm -e "source $runCsh >& $runLog"
                    endif
                else
                    xterm -hold -e "source $runCsh  >& $runLog"
                endif
            else
                if ($tasksModelFile == "sysModel.csv") then
                    echo "# Execute csh"
                    #source $runCsh
                else
                    echo "# Execute csh in non-block mode."
                    if ($n_lsfProject > 0 && $n_noLsf == 0) then
                        if ($n_noXterm > 0) then
                            bsub -P $lsfProject -q regr_high -R 'select[type==RHEL7_64] rusage[mem=10000]' -R 'select[(type==RHEL7_64||type==RHEL8_64)&&(csbatch||gb64||gb128||tmplongforce)]' -o $runLog /bin/csh $runCsh
                        else
                            bsub -P $lsfProject -q regr_high -R 'select[type==RHEL7_64] rusage[mem=10000]' -R 'select[(type==RHEL7_64||type==RHEL8_64)&&(csbatch||gb64||gb128||tmplongforce)]' xterm -e "source $runCsh | tee $runLog"
                        endif
                    else
                        source $runCsh  >& $runLog
                    endif
                endif
            endif
        else
            rm $runCsh
            echo "# No tasks executed."
        endif
        cd $dir_orig
    endif
        
    #xterm -e "source runExecution.csh"
    cd $dir_orig
    sleep 20
    #break
#end

