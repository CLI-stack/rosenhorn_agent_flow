set refDir = $1
set tag = $2
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set runDirReply = ""
set target_run_dir = ""
cat >> $source_dir/data/${tag}_spec << EOF
#text#
    The following run dir has been monitored:
EOF
echo "#table#" >> $source_dir/data/${tag}_spec
echo "tile,runDir,Params" >> $source_dir/data/${tag}_spec

set eff_rd = ""
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`

if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        # Identify if it is run dir
        if (-e $rd/tile.params) then
            set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
            set eff_rd = "$eff_rd $rd"
            echo "# add $rd to eff_rd"
        else
        # Identify if it is dir with all run dir link
            foreach lrd (`ls -1d $rd/*`)
                if (-e $lrd/tile.params) then
                    set curr_tile = `grep TILES_TO_RUN $lrd/tile.params | grep -v "#" | awk '{print $3}'`
                    set eff_rd = "$eff_rd $lrd"
                endif
            end
        endif
    end
endif


foreach rd (`echo $eff_rd`)
    set runDirReply = "$runDirReply \n $rd"
    if (-e $rd/tile.params) then
        set t = `egrep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    endif
    if (-e $rd/override.params) then   
        set params_part = `egrep -v "DESCRIPTION" $rd/tile.params | head -n 1`
        echo "$t,$rd,$params_part" >> $source_dir/data/${tag}_spec
        set target_run_dir = "${target_run_dir}:$rd"
        set run_status = "finished"
    else
        echo "$t,$rd,failed due to no override.params" >> $source_dir/data/${tag}_spec
    endif
end
echo "#table end#" >> $source_dir/data/${tag}_spec
source csh/env.csh
source csh/updateTask.csh
