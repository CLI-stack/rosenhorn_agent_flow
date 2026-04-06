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

set target = $1
set source_dir = $2
# fail 1 here means if the failure is show stop, no matter key word can be match in log, the $target.failed will be generated and send mail; 0 means if no match error, no action
set fail = $3
source $source_dir/csh/env.csh
echo "# fix issue" > debug.$target.log
touch fix_error.$target.csh
#echo "# Analyze $target"
set run_dir = `pwd`
set flowLead = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep flowLead  | awk -F "," '{print $2}'`
python3 $source_dir/script/debug/analyze_target.py --tag 111 --source_dir $source_dir --status "finished" --reply "replied" --html "debug.$target.log" --debugFile debug.csv --target $target --run_dir "$run_dir" --sender "simon1.chen@amd.com" --fail $fail
set n_fix_error = `cat fix_error.$target.csh | wc -w`
if ($n_fix_error > 0) then
    cat fix_error.$target.csh
    source fix_error.$target.csh &
    if (-e $target.error.log) then
        python $source_dir/script/spec2Html.py --spec $target.error.log --html $target.error.html
    endif
    #cat $target.error.html | formail -I "To:$debuggers" -I "From: $vto" -I "MIME-Version:1.0" -I "Content-type:text/html;charset=utf-8" -I "Subject:$target Failed" | sendmail -oi $debuggers
else
    rm fix_error.$target.csh 
endif
if (-e debug.$target.log) then
    set n_debug_log = `wc -l debug.$target.log | awk '{print $1}'`
    if ($n_debug_log == 1) then
        rm debug.$target.log
    endif
endif
set today = `date | awk '{print $3}'`
set log_center = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "log," | awk -F "," '{print $2}'`
set n_log_center = `echo $log_center | wc -w`
if (-e $target.failed && $n_log_center > 0) then
    if (-e $log_center/$target.reported  && -e $log_center) then
        echo "# check reported"
        set reported_date = `ls -l $log_center/$target.reported | awk '{print $7}'`
        if ($reported_date > $today) then
            set reported_date = `expr $reported_date - 30`
        endif
        if ($today - $reported_date > 3) then
            rm -rf $log_center/${target}.*
        endif
        #echo "# report error"
    else
        echo "Hi Expert," > $target.failed
        echo "http://logviewer-atl.amd.com/$run_dir/$target.log.gz" >> $target.failed
        echo "$target failed due to unknow reason:" >> $target.failed
        echo "$target failed due to unknow reason." >> $target.failed
        
        set run_dir = `pwd`
            
        set n_debuggers =  `echo $flowLead | wc -l`
        set vto = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "vto,"  | awk -F "," '{print $2}'`
        set debuggers = ""
        set name = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep debugger | awk -F "," '{print $2}' | head -n 1 | sed 's/\@/ /g' | sed 's/\./ /g' | sed 's/[0-9]\+//g'  | awk '{print $1}'`
        foreach debugger (`python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | egrep "debugger|flowLead"  | awk -F "," '{print $2}'`)
            set debuggers = "$debuggers,$debugger"
            set name = `echo $debugger | sed 's/\@/ /g' | sed 's/\./ /g' | sed 's/[0-9]\+//g'  | awk '{print $1}'`
        end
        python $source_dir/script/spec2Html.py --spec $target.failed --html $target.failed.html
        echo "To: $debuggers Subject: $target $name"
        cat $target.failed.html | formail -I "To:$debuggers" -I "From: $vto" -I "MIME-Version:1.0" -I "Content-type:text/html;charset=utf-8" -I "Subject:$target Failed" | sendmail -oi $debuggers
        touch $target.reported
        if (-e $log_center) then
            cp $target.failed $log_center/
            touch $log_center/$target.reported
        else
            mkdir -p $log_center
            touch $log_center/$target.reported
        endif
    endif

endif
