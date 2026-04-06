# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set file = $1
set tag = $2
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
touch $source_dir/data/${tag}_spec
set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`
set file = `echo $file | sed 's/:/ /g' | sed 's/file//g'`
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    Following module has been installed:
EOF
if ($n_file > 0) then
    if (-e $file) then
        source /proj/rtg-soc-pd-nobackup/user/simchen/env/squid/bin/activate.csh 
        foreach f (`cat $file`)
            pip install $f
            echo "pip install $f" >> $source_dir/data/${tag}_spec
        end
    else
        echo "File not exist." >> $source_dir/data/${tag}_spec
    endif
    echo "#text#" >> $source_dir/data/${tag}_spec
    # cd /proj/rtg-soc-pd-nobackup/pd_agent
    # chgrp -hR asic squid/
endif
source csh/env.csh
source csh/updateTask.csh
