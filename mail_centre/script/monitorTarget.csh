# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set targets = "FxUniqNetlist FxFpPlaceMacros FxFpInsertPhysicalCells FxFpGenInternalPowerGrid FxFpInsertPowerGates FxFpFinishPower \
FxPostFloorPlan FxPlace FxIncrProutePlace FxCts FxIncrProuteCts FxOptCts FxIncrProuteOptCts FxRoute FxOptRoute FxReRoute FxStreamOut"
while (1)
    set n = 0
    set latestTarget = ""
    foreach target (`echo $targets`)
        if (-e logs/${target}.log.gz) then
            set n = `expr $n + 1`
            set latestTarget = $target
        else 
            set length = `echo $latestTarget | wc -w`
            if ($length == 1 ) then
                echo "# Latest finished target is $latestTarget"
                set latestTarget = ""
            endif
        endif
        if (-e logs/${target}.log) then
            echo "# Latest running target is $target"
        endif
    end
    sleep 2 
end
