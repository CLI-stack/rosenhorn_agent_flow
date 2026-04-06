# /proj/at2_fcfp0_nobackup/FCFP_RELEASE/to_tile/GMD_CHIP/NLB/analoglist/soc_rep_top_8_t.analog_list 
echo "source /tool/aticad/1.0/src/zoo/PD_agent/tile/stop_target.tcl" > tune/FxPlace/FxPlace.userprocs.tcl 
echo "source /tool/aticad/1.0/src/zoo/PD_agent/tile/project/at2gmd/saveRam_ICC2.tcl" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.postplace.tcl 
set tile_name = `grep "TILES_TO_RUN" tile.params | grep -v "#" | awk '{print $3}'`
echo "sh cp ${tile_name}.tcl ../../../tune/FxFpPlaceMacros/FxFpPlaceMacros.placerams.tcl -f" >> tune/FxFpPlaceMacros/FxFpPlaceMacros.postplace.tcl
