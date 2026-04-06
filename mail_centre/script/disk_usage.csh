set refDir = $1
set file = $2
set tag = $3
source csh/env.csh

set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec

cat >> $source_dir/data/${tag}_spec << EOF
#text#
The disk usage as following: 
EOF
cd $source_dir
set files = `echo $refDir | sed 's/:/ /g' | awk '{$1="";print $0}'`
foreach f (`echo $files`)
    if (-e $f) then
        echo "check $f"
        echo "#list#" >> $source_dir/data/${tag}_spec
        echo $f >> $source_dir/data/${tag}_spec
        echo "#text#"  >> $source_dir/data/${tag}_spec
        du -sh $f >> $source_dir/data/${tag}_spec
        du -sh $f/* | sort -k 1 -g -r | head -n 20 >> $source_dir/data/${tag}_spec
    else
        echo "NOT exists: $f" >> $source_dir/data/${tag}_spec
    endif
end

set files = `echo $file | sed 's/:/ /g' | awk '{$1="";print $0}'`
foreach f (`echo $files`)
    if (-e $f) then
        echo "check $f"
        echo "#list#" >> $source_dir/data/${tag}_spec
        echo $f >> $source_dir/data/${tag}_spec
        echo "#text#" >> $source_dir/data/${tag}_spec
        du -sh $f >> $source_dir/data/${tag}_spec
    else
        echo "NOT exists: $f" >> $source_dir/data/${tag}_spec
    endif
end
set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
if ($n_file == 0 && $n_refDir == 0) then
    foreach disk (`python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "^disk," | awk -F "," '{print $2}' | sed 's/\r//g'`)
       df $disk >> $source_dir/data/${tag}_spec 
    end
endif
set run_status = "finished"
source csh/updateTask.csh
