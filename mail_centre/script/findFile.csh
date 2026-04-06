set file = $1
# Check def or v
if (-e data/$file) then
    echo "# Found file data/$file"
endif
# Check cmd
if (-e cmds/$file) then
    echo "# Found file cmds/$file"
endif
# check tune
foreach tune (`ls -1d tune/*`)
    if (-e $tune/$file) then
        echo "# Found $tune/$file"
    endif
end
# Check sdc
if (-e data/sdc/$file) then
    echo "# Found data/sdc/$file"
endif
