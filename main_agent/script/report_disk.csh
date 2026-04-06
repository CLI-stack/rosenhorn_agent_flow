# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set disk = $1
set tag = $2
echo $disk
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    The disk is $disk
EOF
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
