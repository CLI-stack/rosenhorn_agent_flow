set runDir = $1
set tag = $2
#set disk = `echo $disk | sed 's/:/ /g'`
set source_dir = `pwd`
set targets = "FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower FxPostFloorPlan FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxOptCts FxIncrProuteOptCts FxRoute FxOptRoute FxReRoute FxStreamOut" 
source csh/env.csh
set activeRunDir = ""
foreach rd (`cat $runDir`)
    #echo "$rd_tile $tile"
    cd $rd
    set n = 0 
    set finishedTarget = "" 
    set latestTarget = ""
    set runningTarget = ""
    foreach target (`echo $targets`) 
        #echo "$target $rd"
        TileBuilderShow | grep FxPlace
        set length = `echo $finishedTarget | wc -w`
        if (-e logs/${target}.log.gz) then 
            set n = `expr $n + 1` 
            set finishedTarget = $target 
            #echo "$length $target $rd"
            set latestTarget = $finishedTarget
        endif
        if (-e logs/${target}.log) then
            set runningTarget = $target
            #echo "# Running target is $runningTarget"
            set activeRunDir = $rd
        endif
    end 
    set length_running = `echo $runningTarget | wc -w`
    if ($length_running == 0) then
        set runningTarget = "NA"
    endif
end
cd -
echo "# Finished target is $finishedTarget"
echo "# Running target is $runningTarget"
source csh/updateTask.csh
