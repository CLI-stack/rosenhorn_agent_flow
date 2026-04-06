# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set integer = $4
set tag = $5
set source_dir = `pwd`
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    following jobs have been killed:
EOF
echo "#table#" >> $source_dir/data/${tag}_spec
bjobs -w | head -n 1 | awk '{print $1,","$2,","$3,","$4,","$5,","$6,","$7,","$8,$9,$10}' >> $source_dir/data/${tag}_spec
set n_integer = `echo $integer | sed 's/:/ /g' | sed 's/integer//g' | wc -w`
if ($n_integer > 0) then
    foreach job (`echo $integer | sed 's/:/ /g' | sed 's/integer//g'`)
        foreach id (`bjobs -w | awk '{print $1}' | grep $job `)
            echo "# check job $job $id"
            if ($id == $job) then
                echo "Found job $id to kill"
                bjobs -w $id | grep -v JOBID  | awk '{print $1,","$2,","$3,","$4,","$5,","$6,","$7,","$8,$9,$10}' >>  $source_dir/data/${tag}_spec
                bkill $job
            endif
        end
    end
endif
echo "#table end#" >> $source_dir/data/${tag}_spec
set run_status = "finished"
source csh/env.csh
source csh/updateTask.csh
