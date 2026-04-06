echo "# Start prepare optimization tune"
set clk = `echo $clk | sed 's/:/ /g' | sed 's/clk//g'`
set n_clk = `echo $clk | wc -w`
set regu = `echo $regu | sed 's/:/ /g' | sed 's/regu//g'`
set n_regu = `echo $regu | wc -w`
if ($n_clk == 0) then
else
endif
touch group.start.$tag.tcl
touch group.end.$tag.tcl
if ($n_clk > 0 && $n_regu == 0) then
    foreach ck (`echo $clk`)
        echo "# Optimize $ck"
        set pt_rpt = `ls -l rpts/PtTimFuncTT*ReRouteTyprc*/${ck}_max.rpt.gz |  sort -k 5 -g | head -n 1 | awk '{print $9}'`
        set n_pt_rpt = `echo $pt_rpt | wc -w`
        if ($n_pt_rpt == 0) then
            echo "$t,$run_dir, rpts/PtTimFuncTT*ReRouteTyprc*/${ck}_max.rpt.gz not exist." >> $source_dir/data/${tag}_spec
            continue
        endif
        perl $source_dir/script/create_group_path.pl -file $pt_rpt
        cp $ck.info $ck.start.info
        echo "# optimize $ck" >> group.start.$tag.tcl
        cat  group.tcl >> group.start.$tag.tcl
        perl $source_dir/script/create_group_path.pl -file $pt_rpt -end
        cp $ck.info $ck.end.info
         echo "# optimize $ck" >> group.end.$tag.tcl
        cat group.tcl >> group.end.$tag.tcl
    end
endif

if ($n_regu > 0) then
    set n = 0
    foreach grp (`echo $regu`)
        set weight = `expr 20 - $n`
        echo "group_path -priority 5 -critical_range 150 -weight $weight -name ${grp}_$n -to [get_pins $grp]"
        set n = `expr $n + 1`
    end
endif
echo "# End prepare optimization tune"
