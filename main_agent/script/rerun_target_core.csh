
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

set target = $1
set n_target = `echo $target | sed 's/:/ /g' | sed 's/target//g' | wc -w`
set curr_dir = `pwd | sed 's/\// /g' | awk '{print $NF}'`
TileBuilderTerm -x "serascmd -find_jobs "dir=~$curr_dir" --action stop;"
sleep 20
rm TileBuilderOverwriteCommand_${target}.started
if (-e cmds/$target.cmd) then
    TileBuilderTerm -x "TileBuilderOverwriteCommand cmds/$target.cmd ;touch TileBuilderOverwriteCommand_${target}.started"
    source $source_dir/script/wait_file_finish.csh TileBuilderOverwriteCommand_${target}.started
else
    TileBuilderTerm -x "TileBuilderOverwriteCommand cmds/$target.cmd"
endif
set rerun_flag = 0
set unskip_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action unskip;"
TileBuilderTerm -x $unskip_cmd
set reset_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --action reset"
TileBuilderTerm -x $reset_cmd
set cmd = ""
if (-e logs/$target.log.gz) then
    rm logs/$target.log.gz
endif
if (-e $target.reported) then
    rm $target.reported
endif
if (-e $target.failed) then
    rm $target.failed
endif
if (-e $target.error.log) then
    rm $target.error.log
endif
touch rerun.$target.analyze_target.log
rm *.$target.analyze_target.log
touch $target.rerun
rm $target.rerun

set unskip_cmd = ""
set reset_cmd = ""
source $source_dir/script/env.csh
set unskip_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --report 'downstream_jobs' | xargs serascmd --action unskip --jobs"
set reset_cmd = "serascmd -find_jobs 'name=~$target dir=~$curr_dir' --report 'downstream_jobs' | xargs serascmd --action reset --jobs"

foreach tg (` python $source_dir/script/parseFlowXml.py --xml data/flow.xml --direction downcone --target $target`)
    echo "# Reset $tg"
    if (-e logs/$tg.log.gz) then
        rm logs/$tg.log.gz
        echo "# remove logs/$tg.log.gz due to rerun."
    endif
    if (-e logs/$tg.log) then
        rm logs/$tg.log
    endif
    if (-e $tg.reported) then
        rm $tg.reported
    endif
    if (-e $tg.failed) then
        rm $tg.failed*
    endif
    if (-e $tg.error.log) then
        rm $tg.error.log*
    endif
    touch rerun.$tg.analyze_target.log
    rm *.$tg.analyze_target.log
    touch $tg.rerun
    rm $tg.rerun

end
TileBuilderTerm -x "$unskip_cmd"
echo "# sleep 30s for unskip."
sleep 60
TileBuilderTerm -x "$reset_cmd"
sleep 30
TileBuilderTerm -x "serascmd -find_jobs "dir=~$curr_dir" --action run"
