set sdc = $1
set clk = $2
set frq = $3
set tag = $4
set sdc_hacked = `ls data/sdc/setup.Func*.sdc | grep -i $sdc | head -n 1`
set n_sdc = `echo $sdc_hacked | wc -w`
if ($n_sdc > 0) then
    echo "# start hacking sdc."
    echo "$source_dir/script/hack_sdc_freq.py --sdc $sdc_hacked --clk $clk --frq $frq"
    python3 $source_dir/script/hack_sdc_freq.py --sdc $sdc_hacked --clk $clk --frq $frq
    cp -rf hack.sdc $sdc_hacked
    echo "$t,$rd,$clk $sdc_hacked hacked" >> $source_dir/data/${tag}_spec 
else
   echo "# $sdc not available."
endif

set sdc_hacked = `ls data/sdc/adjustio.Func*.sdc | grep -i $sdc | head -n 1`
set n_sdc = `echo $sdc_hacked | wc -w`
if ($n_sdc > 0) then
    echo "# start hacking sdc."
    echo "$source_dir/script/hack_sdc_freq.py --sdc $sdc_hacked --clk $clk --frq $frq"
    python3 $source_dir/script/hack_sdc_freq.py --sdc $sdc_hacked --clk $clk --frq $frq
    cp -rf hack.sdc $sdc_hacked
    echo "$t,$rd,$clk $sdc_hacked hacked" >> $source_dir/data/${tag}_spec
else
   echo "# adjustio $sdc not available."
endif


