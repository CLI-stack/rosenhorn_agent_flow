# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set file = $2
set p4File = $3
set cshell = $4
set perl = $5
set runDir = $6
set refDir = $7
set digit = $8
set date = $9
set integer = $10
set unit = $11
set repeat = $12
set regu = $13
set table = $14
set preposition = $15
set stage = $16
set target = $17
set cmds = $18
set snpstcl = $19
set analogip = $20
set std = $21
set params = $22
set controls = $23
set tune = $24
set edatool = $25
set tag = $26
source csh/env.csh
set source_dir = `pwd`
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The concept in mail:
EOF
echo "#table#" >> $source_dir/data/${tag}_spec
echo "word,category,description" >> $source_dir/data/${tag}_spec
while ($#argv > 0)
    echo "$argv[1]"
    set n = `echo $argv[1] | awk -F ":" '{print $2}' | wc -w`
    set word = `echo $argv[1] | awk -F ":" '{print $2}'`
    if ($n > 0) then
        python $source_dir/script/report_argument.py --argumentFile arguement.csv --item "$word"  >> $source_dir/data/${tag}_spec
    endif
    shift
end

echo "#table end#" >> $source_dir/data/${tag}_spec
set run_status = "finished"
source csh/env.csh
source csh/updateTask.csh
