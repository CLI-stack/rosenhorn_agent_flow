set project = $1
set tile = $2
set disk = $3
set refDir = $4
set params = $5
set tag = $6
set refDir = `echo $refDir | sed 's/://g'`
set diskUsage = 0
set diskUsed = ""
set source_dir = `pwd`
if ($tile == "tile") then
    source csh/env.csh
    exit
endif

foreach t (`echo $tile | sed 's/:/ /g' | sed 's/tile //g'`)
    foreach d (`echo $disk | sed 's/:/ /g'`)
        set temp = `df $d | grep -v Filesystem | awk '{print $4}'`
        if ($temp > $diskUsage) then
            set diskUsage = $temp
            set diskUsed = $d
        endif
    end
    set username = `whoami`
    if (-e $diskUsed/$username) then
        cd $diskUsed/$username 
        if (-e $t) then
            cd $t
        else
            mkdir -p $t
            cd $t
        endif
    else
        cd $diskUsed
        mkdir -p $diskUsed/$username/$t
        cd $diskUsed/$username/$t
    endif
    set dir = `date | sed 's/ /_/g' | sed 's/:/_/g'`
    mkdir $dir
    cd $dir
    echo "NICKNAME = $tag" > override.params
    echo "TILES_TO_RUN = $t" >> override.params
    cat $refDir/override.params | egrep -v "NICKNAME|TILES_TO_RUN" >> override.params
    cat $refDir/override.controls > override.controls
    echo "TILEBUILDERCHECKLOGS_STOPFLOW   = 0" >> override.controls
    setprj $project 
    TileBuilderStart --params override.params --controls override.controls
    set run_dir = `ls -1dlar main/pd/tiles/${t}_${tag}_TileBuilder* | tail -n 1 | awk '{print $9}'`
    set target_run_dir = `resolve $run_dir`
    source csh/env.csh
end
source csh/updateTask.csh
