# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tag = $1
set source_dir = `pwd`
touch $source_dir/data/${tag}_spec
set vto = `cat assignment.csv | grep "vto," | head -n 1 | awk -F ',' '{print $2}' | sed 's/\r//g'`
set llmKey = `python3 $source_dir/script/read_csv.py --csv assignment.csv | grep "^llmKey," | awk -F "," '{print $2}'`
set n_llmKey = `echo $llmKey | wc -w`

cat >> $source_dir/data/${tag}_spec << EOF
#text#
    Sorry,I don't understand the instruction. You can use following instruction to get assistance:
    Hi $vto,
        could you list the instructions?
    Or:
    Hi $vto,
        use llm
        What instruction should I use if I want ...?
EOF

echo "" >> $source_dir/data/${tag}_spec
echo "" >> $source_dir/data/${tag}_spec

if ($n_llmKey > 0) then
    echo "# LLM recommendations:" >> $source_dir/data/${tag}_spec
    source $source_dir/script/env.csh
    deactivate
    source /tools/aticad/1.0/src/sysadmin/cpd.cshrc
    setenv AMDLSFCLUSTER atl02
    source /tool/pandora/etc/lsf/cshrc.lsf
    module load calibre/2021.3_15.9
    echo "If I want to do below operation, which instructions should I use?" > $source_dir/data/$tag/llm.txt
    egrep -v "Subject" data/$tag/$tag.log >> data/$tag/llm.txt
    python3 $source_dir/script//use_llm.py --source_dir $source_dir --contextFile $source_dir/data/$tag/llm.txt --key $llmKey --tag $tag >> $source_dir/data/${tag}_spec
endif

set run_status = "finished"
source csh/env.csh
source csh/updateTask.csh
