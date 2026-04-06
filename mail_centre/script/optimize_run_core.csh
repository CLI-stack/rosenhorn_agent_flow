echo "# Start optimization core"
set base_dir = `grep BRANCHED_FROMDIR tile.params | grep -v "#" | awk '{print $3}'`
set n_place = `echo $target | grep -i place | wc -w`
set n_integer = `echo $integer | sed 's/^integer//g' | sed 's/:/ /g' | wc -w`
if ($n_place > 0) then
    set group_tcl = `wc -l $base_dir/group.*.$tag.tcl | sort -k 1 -g | grep -v "total" | tail -n 1 | awk '{print $2}'`
    set n_group_tcl = `echo $group_tcl | wc -w`
    if ($n_group_tcl > 0) then
        if ($n_integer > 0) then
            set n_group = `echo $integer | sed 's/^integer//g' | sed 's/:/ /g' `
            set n_group = `expr $n_group + 1`
            chmod 744 tune/FxPlace/FxPlace.pre_opt.tcl
            cat $group_tcl | head -n $n_group >> tune/FxPlace/FxPlace.pre_opt.tcl
            cat $group_tcl | head -n $n_group > group_${n_group}_tcl.$tag.log
        else
            set n_group = 0
            chmod 744 tune/FxPlace/FxPlace.pre_opt.tcl
            cat $group_tcl >> tune/FxPlace/FxPlace.pre_opt.tcl
            cat $group_tcl > group_${n_group}_tcl.$tag.log
        endif
        set group_log = `resolve group_${n_group}_tcl.$tag.log`
        echo "$t,$run_dir,Optimize FxPlace;$group_log" >> $source_dir/data/${tag}_spec
    else
        echo "$t,$run_dir,group.tcl not generated."
    endif
endif
echo "# End optimization core"

