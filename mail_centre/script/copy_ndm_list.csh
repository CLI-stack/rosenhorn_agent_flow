# /proj/cmb_fcfp_vol1/a0/RAMPLACE/CHIP_MID/NLB_FCNL_0000/CHIP_MID_SEP_24
set fcfp_dir = $1
echo "# Start to copy ndm and list for $fcfp_dir"
cp -rf $fcfp_dir/tech/ndm/* tech/ndm/
foreach ndm (`cat data/allmacros.list`)
    if (-e tech/ndm/${ndm}.ndm) then
        cat data/allmacros.list | awk '{print "tech/ndm/"$1".ndm"}' >> tech/lists/ndm.list
    else
        sed -i "/$ndm/d" data/allmacros.list 
        sed -i "/$ndm/d" tech/lists/ndm.list
        sed -i "/$ndm/d" data/srams.list
        sed -i "/$ndm/d" data/analogs.list
    endif
end
cat tech/lists/ndm.list | sort -u > ndm.list 
cp ndm.list tech/lists/ndm.list
echo "source /tool/aticad/1.0/src/zoo/PD_agent/tile/stop_target.tcl" > tune/FxFpGenInternalPowerGrid/FxFpGenInternalPowerGrid.userprocs.tcl 
