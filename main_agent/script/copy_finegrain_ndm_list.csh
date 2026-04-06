# /proj/cmb_fcfp_vol1/a0/RAMPLACE/CHIP_MID/NLB_FCNL_0000/CHIP_MID_SEP_24
set syn_dir = $1

echo "# Start to copy ndm and list for $syn_dir"
foreach ndm (`ls -1d $syn_dir/tech/finegrain/*/ndm/*.ndm | grep -v tech_only`)
    cp -rf $ndm tech/ndm/
end
cd $syn_dir
set ndm_list = ""
foreach ndm (`ls -1d tech/finegrain/*/ndm/*.ndm | grep -v tech_only`)
    set ndm1 = `echo $ndm | sed 's/\/ndm\// ndm\//g' | awk '{print $2}'`
    set ndm_list = "$ndm_list $ndm1"
    echo $ndm1
end
cd -
foreach ndm (`echo $ndm_list`)
    echo "tech/$ndm" >> tech/lists/ndm.list 
    echo "tech/$ndm"
end
cat tech/lists/ndm.list | sort -u > ndm.list
cp -rf ndm.list tech/lists/ndm.list

foreach db (`resolve $syn_dir/tech/finegrain/*/synopsys/*.tt0p600v0c_typical.db`)
    echo $db >> tech/lists/tt0p6v0c_ccs.list
end
#cat tech/lists/tt0p6v0c_ccs.list | sort -u > tt0p6v0c_ccs.list
#cp -rf tt0p6v0c_ccs.list tech/lists/tt0p6v0c_ccs.list
