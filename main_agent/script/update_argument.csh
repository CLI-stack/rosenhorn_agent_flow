# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tag = $1
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    Argument.csv has been updated.
EOF
echo "#list#" >> $source_dir/data/${tag}_spec
set n_run_dir = 0
set table_used = 0
echo "#table#" >> $source_dir/data/${tag}_spec
echo "concept,argument" >> $source_dir/data/${tag}_spec
# Detect table based input
if (-e data/$tag.table) then
    set n_table = `cat data/$tag.table | wc -w`
    if ($n_table > 0) then
        source csh/env.csh
        cat data/$tag.table | sed 's/^|//g' | sed 's/|$//g' | sed 's/|/,/g' >> $source_dir/data/${tag}_spec
        #cp script/arguement.csv script/arguement.$tag.csv
        chmod 740 arguement.csv
        python3 $source_dir/script/update_argument.py --tag $tag --table data/$tag.table --argument arguement.csv 
        python3 /tools/aticad/1.0/src/zoo/PD_agent/tile/read_csv.py --csv arguement.csv | awk -F ',' '{if (NF == 3) {print $1","$2","$3} else {print $1","$2","}}' | sed "s/ //g" > arguement.tmp.csv
        cp -rf arguement.tmp.csv arguement.csv
    endif

endif
echo "#table end#" >> $source_dir/data/${tag}_spec
set run_status = "finished"

cd $source_dir
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
