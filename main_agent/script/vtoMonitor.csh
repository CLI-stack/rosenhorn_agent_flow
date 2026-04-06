#!/bin/csh
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
set tasksModelFile = $1
set debug = 0
if (-e vto_stop) then
    echo "# vto_stop existed, skip monitor."
    set stop = 1
else
    set stop = 0
endif
set source_dir = `pwd`
if (-e $tasksModelFile.lock) then
    rm $tasksModelFile.lock
endif

#while(1)
    set dir_orig = `pwd`
    if (-e $tasksModelFile.lock) then
        echo "# Tasks are locked"
    else
        #touch $tasksModelFile.lock
        #python $source_dir/py/vtoMonitor.py  --tasksModelFile $tasksModelFile
        if ($debug == 0) then
            #xterm -e "source csh/exec_monitor.csh"
            if ($stop == 0) then
                if (-e vto_debug) then
                    #xterm  -e "source csh/exec_monitor.csh $tasksModelFile "
                    source csh/exec_monitor.csh $tasksModelFile | tee exec_monitor.log
                else
                    source csh/exec_monitor.csh $tasksModelFile | tee exec_monitor.log
                endif
                echo " "
                echo "### Stand by 60s ..."
                echo " "
                sleep 60
            endif
        else
            xterm -hold -e "source csh/exec_monitor.csh $tasksModelFile"
        endif
        cd $dir_orig
        #rm $tasksModelFile.lock
        cd $dir_orig
    endif
    #xterm -e "source runExecution.csh"
    cd $dir_orig
#end

