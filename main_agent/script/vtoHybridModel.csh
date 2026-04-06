# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
#source csh/env.csh
set mailFile = $1
set tasksModelFile = $2
set instructionFile = $3
set source_dir = `pwd`
source csh/env.csh
touch runDir.list
rm runDir.list
touch runDir.list
foreach rd (` cat data/*/runDir.list | sed 's/:/ /g' | sort -u`)
    echo $rd >> runDir.list
end
cat runDir.list | sort -u > runDir.tmp.list
cp runDir.tmp.list runDir.list
rm runDir.tmp.list

if (-e $tasksModelFile.lock) then
    rm $tasksModelFile.lock
endif

touch $tasksModelFile.lock
perl $source_dir/script/readTaskMail.pl $mailFile 
python $source_dir/py/vtoHybridModel.py --mailFile $mailFile --tasksModelFile $tasksModelFile --instructionFile $instructionFile
sleep 5
