set tile = $1
set runDir = $2
set refDir = $3
set tag = $4
set source_dir = `pwd`
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#lis#
    Current jobs status:
EOF
echo "#table#" >> $source_dir/data/${tag}_spec
bjobs -w | awk '{print $1,","$2,","$3,","$4,","$5,","$6,","$7,","$8,$9,$10}' >>  $source_dir/data/${tag}_spec
echo "#table end#" >> $source_dir/data/${tag}_spec
set run_status = "finished"
source csh/env.csh
source csh/updateTask.csh
