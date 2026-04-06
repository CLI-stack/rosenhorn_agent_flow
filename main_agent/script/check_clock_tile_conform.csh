# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set tag = $5
set source_dir = `pwd`
set n_file = `echo $file | sed 's/:/ /g' | sed 's/file//g' | wc -w`
set file = `echo $file | sed 's/:/ /g' | sed 's/file//g'`
touch $source_dir/data/${tag}_spec
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    Check tile clock conform:
EOF

if ($n_file == 0) then
    echo "# not specify config file" >> $source_dir/data/${tag}_spec
    exit
endif
echo Hi
if (-e $file) then
else
    echo "# config file not exist" >> $source_dir/data/${tag}_spec
    exit
endif
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,description" >> $source_dir/data/${tag}_spec
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        set eff_rd = "$eff_rd $rd"
    end
endif

/proj/rtg-soc-pd-nobackup/PDI_platform/pdi_env/bin/python /tools/aticad/1.0/src/zoo/rampage/sitour/CLOCK/flow/cmds/check/check_tile_conform.py --config $file
#echo "$t,$source_dir/check_tile_conform.rpt" >> $source_dir/data/${tag}_spec
echo "#table end#" >> $source_dir/data/${tag}_spec
set run_status = "finished"
source csh/env.csh
source csh/updateTask.csh
