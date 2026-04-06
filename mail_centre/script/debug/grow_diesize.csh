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

set team = $1
set n_team = `echo $team | wc -w`
set curr_dir = `pwd`
echo "# Report $target at $curr_dir to $team"
set n_debuggers =  `egrep flowLead $source_dir/assignment.csv | awk -F "," '{print $2}' | wc -l`
set vto = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "vto,"  | awk -F "," '{print $2}'`
set debuggers = ""
set name = ""
foreach debugger (`python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "flowLead|debugger" | awk -F "," '{print $2}'`)
    set debuggers = "$debuggers,$debugger"
    set name = `echo $debugger | sed 's/\@/ /g' | sed 's/\./ /g' | sed 's/[0-9]\+//g'  | awk '{print $1}'`
end
if ($n_team > 0) then
    foreach tm (`echo $team | sed 's/:/ /g'`)
        set tme = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "$tm," | awk -F ',' '{print $2}' | sed 's/\r//g' | head -n 1`
        echo "# add team to list $debuggers $tme"
        set n_tme = `echo $tme | wc -w`
        if ($n_tme == 0) then
            continue
        endif
        set n_tme = `echo $debuggers | grep $tme | wc -w`
        echo "added"
        # remove duplicate address
        if ($n_tme > 0) then
        else
            set debuggers = "$debuggers,$tme"
        endif
    end
endif

set mgr = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "manager," |  awk -F ',' '{print $2}' | sed 's/\r//g'`
set n_mgr = `echo $debuggers | grep $mgr | wc -w`
# remove duplicate address
if ($n_mgr > 0) then
else
    set debuggers = "$debuggers,$mgr"
endif
set today = `date | awk '{print $3}'`
if (-e $target.error.log) then
    set log_center = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "log," | awk -F "," '{print $2}'`
    if (-e $log_center/$target.reported && $team != "debugger") then
        set reported_date = `ls -l $log_center/$target.reported | awk '{print $7}'`
        echo "# check date $reported_date $today"
        if ($reported_date > $today) then
            set reported_date = `expr $reported_date - 30`
        endif
        if ($today - $reported_date > 3) then
            rm -rf $log_center/${target}.*
        endif

    else
        python $source_dir/script/spec2Html.py --spec $target.error.log --html $target.error.html
        cat $target.error.html | formail -I "To:$debuggers" -I "From: $vto" -I "MIME-Version:1.0" -I "Content-type:text/html;charset=utf-8" -I "Subject:$target Failed" | sendmail -oi $debuggers
        touch $target.reported
        cp $target.reported $log_center/
        cp $target.error.log $log_center/
    endif
endif

if (-e $target.error.log) then 
    echo "# Found $target.error.log, start generate diesize"
    set h_grid = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "hGrid," | awk -F "," '{print $2}'`
    set h_offset = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv"  | grep "hOffset," | awk -F "," '{print $2}'`
    set v_grid = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "vGrid," | awk -F "," '{print $2}'`
    set v_offset = `python3 $source_dir/script/read_csv.py --csv "$source_dir/assignment.csv" | grep "vOffset," | awk -F "," '{print $2}'`
    set new_diesize = `python3 $source_dir/script/debug/grow_diesize.py --log $target.error.log --hGrid $h_grid --hOffset $h_offset --vGrid $v_grid --vOffset $v_offset | grep "new die size" | awk '{print $4,$5}'`
    set n_new_diesize = `echo $new_diesize | wc -w`
    if ($n_new_diesize > 0) then
        echo "CHOSEN_COLDSTART = 1" >>  override.params 
        echo "COLDSTART_CORE_SIDE_LENGTH = $new_diesize" >>  override.params
        if (-e tune/FxFpPlaceMacros/FxFpPlaceMacros.pre_opt.tcl) then
            chmod 744 tune/FxFpPlaceMacros/FxFpPlaceMacros.pre_opt.tcl
            echo "source /tools/aticad/1.0/src/zoo/PD_agent/tile/debug/set_center_orign.tcl" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.pre_opt.tcl
        else
            echo "source /tools/aticad/1.0/src/zoo/PD_agent/tile/debug/set_center_orign.tcl" > tune/FxFpPlaceMacros/FxFpPlaceMacros.pre_opt.tcl
        endif
        if (-e TileBuilderGenParams_grow_diesize) then
            rm TileBuilderGenParams_grow_diesize
        endif
        TileBuilderTerm -x "TileBuilderGenParams;TileBuilderOverwriteCommand cmds/$target.cmd;touch TileBuilderGenParams_grow_diesize"
        set n_wait = 0
        while(1)
            if (-e TileBuilderGenParams_grow_diesize) then
                touch TileBuilderGenParams_grow_diesize.pass
                break
            endif
            set n_wait = `expr $n_wait + 1`
            if ($n_wait > 1800) then
                touch TileBuilderGenParams_grow_diesize.overtime
                break
            endif
            sleep 1
        end
        source $source_dir/script/rerun_target_core.csh $target
        echo "Hi Expert," > $target.outofboundray.error.log
        echo "# Error: record diesize too small, change to $new_diesize" >> $target.outofboundray.error.log
    endif
endif
