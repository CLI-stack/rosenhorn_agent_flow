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
set width_d = $1
set height_d = $2
set tag = $3
set h_grid = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "hGrid," | awk -F "," '{print $2}'`
set h_offset = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv"  | grep "hOffset," | awk -F "," '{print $2}'`
set v_grid = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "vGrid," | awk -F "," '{print $2}'`
set v_offset = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "vOffset," | awk -F "," '{print $2}'`
set n_tune = `ls -1d tune | wc -w`
set n_FxFpPlaceMacros = 0
set n_FxFpPreSynPlaceMacros = 0

if (-e gen_incr_width_height_tune.finished) then
else
    if (-e tbs.log) then
        set n_FxFpPlaceMacros = `grep FxFpPlaceMacros tbs.log | wc -w`
        set n_FxFpPreSynPlaceMacros = `grep FxFpPreSynPlaceMacros tbs.log | wc -w`
    endif

    if ($n_tune > 0) then
        if (-e tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl) then
            echo "# start generate incr width and height tune"
            chmod 744 tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            echo "source /tool/aticad/1.0/src/zoo/PD_agent/tile/incr_width_height.tcl" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            echo "incr_width_height $width_d $height_d $h_grid $h_offset $v_grid $v_offset" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl 
            grep "IC_TRACKPLAN_SCRIPT" tile.params | grep -v "#" | grep ".tcl" | awk '{print "source -e -v "$3}' >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            touch gen_incr_width_height_tune.finished 
            source $source_dir/script/rerun_target_core.csh FxFpPlaceMacros
        else
            mkdir -p tune/FxFpPlaceMacros 
            echo "# start generate incr width and height tune"
            echo "source /tool/aticad/1.0/src/zoo/PD_agent/tile/incr_width_height.tcl" > tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            echo "incr_width_height $width_d $height_d $h_grid $h_offset $v_grid $v_offset" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            grep trackplan cmds/FxFpPlaceMacros.cmd | grep -v put >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            grep "IC_TRACKPLAN_SCRIPT" tile.params | grep -v "#" | grep ".tcl" | awk '{print "source -e -v "$3}' >> tune/FxFpPlaceMacros/FxFpPlaceMacros.preplace.tcl
            touch gen_incr_width_height_tune.finished
            if ($n_FxFpPlaceMacros > 0) then
                source $source_dir/script/rerun_target_core.csh FxFpPlaceMacros
            else
                source $source_dir/script/rerun_target_core.csh FxFpPreSynPlaceMacros
            endif
        endif
    endif
endif
