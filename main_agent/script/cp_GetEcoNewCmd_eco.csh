set eco = `grep ECO_NEWCMD tile.params | grep -v "#" | awk '{print $3}'`
set n_eco = `echo $eco | wc -w`
if ($n_eco > 0) then
    cp -rf $eco $BASE_DIR/data/GetEcoNewCmd.eco
else
    echo "# Warning: No eco specified."
endif
