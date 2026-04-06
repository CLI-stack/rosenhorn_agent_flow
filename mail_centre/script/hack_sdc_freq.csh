set sdc = $1
set clk = $2
set frq = $3
set tag = $4
set sdc = `ls data/sdc/setup.Func*.sdc | grep -i $sdc | head -n 1`
set n_sdc = `echo $sdc | wc -w`
if (-e ${sdc}_{$clk}.finished) then
else
    if ($n_sdc > 0) then
        echo "# start hacking sdc."
        echo "$source_dir/py/hack_sdc_freq.py --sdc $sdc --clk $clk --frq $frq"
        python3 $source_dir/py/hack_sdc_freq.py --sdc $sdc --clk $clk --frq $frq
        cp -rf hack.sdc $sdc
        touch ${sdc}_{$clk}.finished
    else
        echo "# Sdc not found."
    endif
endif
