# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set refDir = $1
set file = $2
set tag = $3
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec


cat >> $source_dir/data/${tag}_spec << EOF
#text#
    # Please note, this instruction only remove the dir with tile.params or override.controls.If you want remove dir without them, you can touch one first.
    The following dir has been removed: 
#list#
EOF
cd $source_dir
set eff_rd = ""
set eff_rd_root = ""
set files = `echo $refDir | sed 's/:/ /g' | awk '{$1="";print $0}'`
set n_files = `echo $files | wc -w`
# Only support remove run dir to avoid misunderstanding the mail with "Hi All"
if (-e data/$tag.table) then
    set n_table = `cat data/$tag.table | wc -w`
    if ($n_table > 0) then
        foreach sect (`cat  $source_dir/data/$tag.table | sed 's/|/ /g'`)
            set n_run_dir = `echo $sect | egrep "main/pd/tiles" | wc -w`
            if ($n_run_dir > 0) then
                if (-e $sect/override.params) then
                    cd $sect
                    if (-e revrc.main) then
                        TileBuilderTerm -x "seras -shutdown;touch shutdown_$tag.started"
                        set eff_rd = "$eff_rd $sect"            
                    endif
                endif
            endif
        end    
    endif
endif
foreach f (`echo $files`)
    if ($n_files == 0) then
        continue
    endif
    if (-e $f) then
        if (-e $f/override.params) then
            cd $f
            if (-e revrc.main) then
                TileBuilderTerm -x "seras -shutdown;touch shutdown_$tag.started"
                set eff_rd = "$eff_rd $f"
            else
                set eff_rd_root = "$eff_rd_root $f"
            endif
            cd $source_dir
        endif
    else
        echo "$f not exists" >> $source_dir/data/${tag}_spec
    endif
end
echo "sleep 300s to close active windows"
sleep 300

cd $source_dir
set n_eff_rd = `echo $eff_rd | wc -w`
set n_eff_rd_root = `echo $eff_rd_root | wc -w`
echo "# run dir | $n_eff_rd | $n_eff_rd_root"
if ($n_eff_rd > 0) then
    foreach rd (`echo $eff_rd`)
        set n_wait = 0
        while(1)
            if (-e $rd/shutdown_$tag.started) then
                echo "$rd,TB shutdown passed,removing..." >> $source_dir/data/${tag}_spec
                rm -rf $rd &
                break
            endif
            set n_wait = `expr $n_wait + 1`
            if ($n_wait > 1800) then
                echo "$rd,TB shutdown failed in 30 mins,removing..." >> $source_dir/data/${tag}_spec
                rm -rf $rd &
                break
            endif
            sleep 1
        end
    end
endif
if ($n_eff_rd_root > 0) then
    foreach rd (`echo $eff_rd_root`)
        echo "$rd,removing..." >> $source_dir/data/${tag}_spec
        rm -rf $rd &
    end
endif


set files = `echo $file | sed 's/:/ /g' | awk '{$1="";print $0}'`
set n_files = `echo $files | wc -w`
# disable non-tb dir removal
foreach f (`ls $files`)
    continue
    if ($n_files == 0) then
        continue
    endif

    if (-e $f) then
        echo $f >> $source_dir/data/${tag}_spec
        rm -rf $f &
    else
        echo "Not exist $f" >> $source_dir/data/${tag}_spec
    endif
end

source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
