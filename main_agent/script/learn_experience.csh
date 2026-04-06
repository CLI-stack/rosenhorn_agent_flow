set table = $1
set tag = $2
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#text#
EOF
if (-e $table) then
    set n_table = `head -n 1 $table | sed 's/|/ /g' | awk '{print NF}'`
    if ($n_table > 0) then
        python3 $source_dir/py/learn_experience.py --table $table --arguement $source_dir/arguement.csv --tag $tag
        if (-e $tag.fail) then
            echo "    The format is not correct, column is not equal to 6" >> $source_dir/data/${tag}_spec
        endif
        echo "    The experience has been learned." >> $source_dir/data/${tag}_spec
    else
        echo "    No table used." >> $source_dir/data/${tag}_spec
    endif
endif
set run_status = "finished"
cd $source_dir
source csh/env.csh
source csh/updateTask.csh
