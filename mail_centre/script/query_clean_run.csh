# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set source_dir = `pwd`
set tiles = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "^tile," | awk -F "," '{print $2}' | sed 's/\r//g'`
echo "Hi Manager," > data/query_clean_run.spec
echo "#list#" >> data/query_clean_run.spec
echo "# Below are the run dir reports:" >> data/query_clean_run.spec
echo "#table#" >> data/query_clean_run.spec
echo "tile,runDir,tag,n days ago" >> data/query_clean_run.spec
set current_date = `date +%D | awk -F '/' '{print $3$2$1}'`
set current_year = `date +%D | awk -F '/' '{print $3}'`
set current_month = `date +%D | awk -F '/' '{print $1}' | sed 's/^0//g'`
set current_day = `date +%D | awk -F '/' '{print $2}' | sed 's/^0//g'`
set current_date = `echo $current_year $current_month $current_day | awk '{print $1*360+$2*30+$3}'`

set current_secode = `date | awk '{print $4}' | awk -F ":" '{print $1$2$3}'`
set current_time = "${current_date}${current_secode}"
echo $current_time
foreach rd (`cat $source_dir/runDir.list`)
    if (-e $rd/tile.params) then
    else
        continue
    endif
    set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set n_task = `ls  $rd/*.task | wc -w`
    if ($n_task > 0) then
        set tag = `ls  $rd/*.task | sort -k 1 | head -n 1 | sed 's/\// /g' | awk '{print $NF}' | sed 's/\./ /g' | awk '{print $1}'`
        set tag_year = `echo $tag | cut -b 1-2`
        set tag_month = `echo $tag | cut -b 3-4 | sed 's/^0//g'`
        set tag_day = `echo $tag | cut -b 5-6 |  sed 's/^0//g'`
        set tag_date = `echo $tag_year $tag_month $tag_day | awk '{print $1*360+$2*30+$3}'`
        set age = `echo $current_date $tag_date | awk '{print $1-$2}'`
        echo "$curr_tile,$rd,$tag,$age" >> data/query_clean_run.spec
    endif
end
echo "#table end#" >> data/query_clean_run.spec
echo "#list#" >> data/query_clean_run.spec
echo "Below are the recommedation(keep only one run and delete the old runs):" >> data/query_clean_run.spec
echo "#text#" >> data/query_clean_run.spec
set vto = `python3 $source_dir/script/read_csv.py --csv $source_dir/assignment.csv | grep "^vto," | head -n 1 | awk -F "," '{print $2}' | sed 's/\r//g'`
echo "Hi $vto" >> data/query_clean_run.spec
echo "could you clean run?" >> data/query_clean_run.spec
foreach t (`echo $tiles`)
    set n_dir = `cat data/query_clean_run.spec | grep "$t" | wc -l` 
    if ($n_dir > 1) then
        # only keep the latest run dir.
        cat data/query_clean_run.spec | grep "$t" | sed 's/,/ /g' | sort -k 3 -g -r | sed -n '2,$p' | awk '{print $2}' >> data/query_clean_run.spec
    endif
end
source $source_dir/script/env.csh
python $source_dir/script/spec2Html.py --spec data/query_clean_run.spec --html data/query_clean_run.html

