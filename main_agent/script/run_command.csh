set tile = $1
set runDir = $2
set refDir = $3
set file = $4
set tag = $5
set source_dir = `pwd`
set target_run_dir = ":"
set reply = ""
touch $source_dir/data/${tag}_spec

echo "#list#" >> $source_dir/data/${tag}_spec
set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    set tile_owned = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
    set n_rd_tile = `echo $tile_owned | grep $t | wc -l`
    if ($n_rd_tile == 0) then
        echo "I don't own $t or you may spell the tile wrongly." >> $source_dir/data/${tag}_spec
    endif
end


set n_tile = `echo $tile | sed 's/^tile//g' | sed 's/:/ /g' | wc -w`
if ($n_tile == 0) then
    set tile = `grep "tile," $source_dir/assignment.csv | awk -F "," '{print $2}' | sed 's/\r/ /g'`
endif
set n_er = `groups | grep "\.er" | wc -w`
if ($n_er > 0) then
    set note = "This is er account:only support ls|ln|rm|mv|cd|mkdir|touch|kill|sort|uniq, need run at dir with tile.params."
else
    set note = "This is non-er account, only support ls|ln|rm|mv|cd|mkdir|touch|kill|zcat|cat|grep|zgrep|egrep|zegrep|awk|sort|uniq,need run at dir with tile.params."
endif
cat >> $source_dir/data/${tag}_spec << EOF
#list#
    For er account, only support ls|ln|rm|mv|cd|mkdir|touch|kill|sort|uniq.
    For non-er acount, only support ls|ln|rm|mv|cd|mkdir|touch|kill|zcat|cat|grep|zgrep|egrep|zegrep|awk|sort|uniq.
    Need run at dir with tile.params.
    "|" or ";" or "source xx" is not allowed
    The command has been run:
#table#
EOF
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
echo "Tile,runDir,Comment" >> $source_dir/data/${tag}_spec
set eff_rd = ""
set n_refDir = `echo $refDir | sed 's/:/ /g' | sed 's/refDir//g' | wc -w`
set eff_rd = ""
if ($n_refDir > 0) then
    foreach rd (`echo $refDir | sed 's/:/ /g' | sed 's/refDir//g'`)
        set eff_rd = "$eff_rd $rd"
    end
endif

foreach t (`echo $tile | sed 's/^tile//g' | sed 's/:/ /g'`)
    if ($n_refDir > 0) then
        break
    endif
    foreach rd (`cat $runDir`)
        if (-e $rd) then
        else
            continue
        endif
        if (-e $rd/tile.params) then
        else
            continue
        endif
        set curr_tile = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
        if ($t == $curr_tile) then
            set eff_rd = "$eff_rd $rd"
            cd $rd
        endif
    end
    cd $source_dir
end

foreach rd (`echo $eff_rd`)
    cd $rd
    touch $tag.task
    set t = `grep TILES_TO_RUN $rd/tile.params | grep -v "#" | awk '{print $3}'`
    touch $tag.csh.log
    rm $tag.csh.log
    if (-e $source_dir/data/$tag/$tag.csh) then
        echo "# source $source_dir/data/$tag/$tag.csh"
        if ($n_er > 0) then
            set csh = `egrep "^p4 |^ls |^ln |^rm |^mv |^cd |^mkdir |^touch |^kill |^sort |^uniq " $source_dir/data/$tag/$tag.csh | sed 's/\n/;/g'`
            egrep "^p4 |^ls |^ln |^rm |^mv |^cd |^mkdir |^touch |^kill |^sort |^uniq " $source_dir/data/$tag/$tag.csh > $source_dir/data/$tag/$tag.filter.csh
        else
            set csh = `egrep "^p4 |^ls |^ln |^rm |^mv |^cd |^mkdir |^touch |^kill |^sort |^uniq |^cat |^grep |^zgrep |^egrep |^zegrep |^awk |^sort |^uniq " $source_dir/data/$tag/$tag.csh | sed 's/\n/;/g'`
            egrep "^p4 |^ls |^ln |^rm |^mv |^cd |^mkdir |^touch |^kill |^sort |^uniq |^cat |^grep |^zgrep |^egrep |^zegrep |^awk " $source_dir/data/$tag/$tag.csh > $source_dir/data/$tag/$tag.filter.csh
        endif
        echo "$tile,$rd,$csh"
        source $source_dir/data/$tag/$tag.csh >> $tag.csh.log 
        echo "$t,$rd,http://logviewer-atl.amd.com/$rd/$tag.csh.log" >> $source_dir/data/${tag}_spec
    endif
    set n_wait = 0
end
cd $source_dir
echo "#table end#" >> $source_dir/data/${tag}_spec
echo " " >> $source_dir/data/${tag}_spec
set run_status = "finished"
cd $source_dir
source csh/env.csh
echo "#text#" >> $source_dir/data/${tag}_spec
source csh/updateTask.csh
