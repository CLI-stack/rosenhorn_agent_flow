set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set tag = $5
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The log status as following:
EOF
echo "#list#" >> $source_dir/data/${tag}_spec

endif
set n_run_dir = 0
set table_used = 0
# Detect table based input
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
foreach t (`echo $tile |sed 's/^tile//g' | sed 's/:/ /g'`)
    # Specify run dir in mail
    echo "## check log" >> $source_dir/data/${tag}_spec
    cd $source_dir
end
cd $source_dir
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
