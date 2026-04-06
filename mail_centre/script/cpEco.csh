set fceco = $1
set tile = `grep TILES_TO_RUN $BASE_DIR/override.params | grep -v "#" | awk '{print $3}' | sort -u`
touch $BASE_DIR/data/GetEcoNewCmd.eco
rm -rf $BASE_DIR/data/GetEcoNewCmd.eco
foreach eco (`grep ECO_NEWCMD $BASE_DIR/override.params | tail -n 1 | awk '{print $3}'`)
    set n_eco = `echo $eco | grep ".eco" | wc -w`
    if ($n_eco > 0) then
        echo "# copy $eco for $tile"
        echo "source $eco" >> $BASE_DIR/data/GetEcoNewCmd.eco
    endif
endif
