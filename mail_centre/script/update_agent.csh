set lists = $1
set lists = "/home/simchen/aigc/update_agent.list"
cd /proj/cmb_pnr_vol21/simchen/aticad/depot/tools/aticad/1.0/src/zoo/PD_agent/tile
foreach f (`cat $lists`)
    echo "$f"
    set nf = `echo $f | sed 's@/home/simchen/aigc/@@g'`
    if (-e $nf) then
        rm -rf $nf
        p4 sync $nf
        cp -rf $f $nf
        p4 edit $nf
        p4 submit -d "update script"
        aticad sync $nf
    else
        set file_name = `echo $nf | sed 's/\// /g' | awk '{print $NF}'`
        set dir = `echo $nf | sed "s@$file_name@@g"`
        set n_dir = `echo $dir | wc -w`
        if ($n_dir > 0) then
            if (-e $dir) then
            else
                echo "# Create $dir"
                mkdir -p $dir
            endif
        endif
        echo "# Add $nf"
        cp -rf $f $nf
        p4 add $nf
        p4 submit -d "update script"
        aticad sync $nf
    endif
    #p4 edit $list
    #p4 submit -d "NLD fcfp pure run"
end
cd -
