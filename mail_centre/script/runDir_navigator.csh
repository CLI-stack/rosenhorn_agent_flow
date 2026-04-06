source script/env.csh 
if (-e runDir.list) then
else
    echo "# No runDir.list, make sure running at agent runDir."
endif
touch runDir.spec
rm runDir.spec
foreach rd (`cat runDir.list`)
    set tile = `grep "TILES_TO_RUN" $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set running_target = `ls -lart $rd/logs/*.log.gz | grep "Fx" |tail -n 1 | awk '{print $9}' | sed 's/\// /g' | awk '{print $NF}' | sed 's/\.log\.gz//g'`
    set chip_release = `grep CHIP_RELEASE $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set fp_pointer = `grep FLOORPLAN_POINTER $rd/tile.params | grep -v "#" | awk '{print $3}'`
    set description = `egrep "^DESCRIPTION\s" $rd/override.params | tail -n 1 | grep -v "^#" `
    set description = "$chip_release $fp_pointer $description"
    #set description = "tt0p9v sss0p8v aaaaa oooooooooooooo"
    echo "$tile,$running_target,$description,$rd" >> runDir.spec
end
python3 /tools/aticad/1.0/src/zoo/PD_agent/tile/runDir_navigator.py &
