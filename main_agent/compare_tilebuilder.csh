#!/bin/tcsh
# Compare TileBuilder scripts between OSS and UMC

cd /proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/script/rtg_oss_feint

echo "Comparing TileBuilder scripts between OSS and UMC..."
echo ""

foreach script (oss/*tilebuilder*.csh oss/*tilebuilder*.pl)
    set base = `basename $script`
    
    if (-f umc/$base) then
        diff -q $script umc/$base >& /dev/null
        if ($status == 0) then
            echo "IDENTICAL: $base"
        else
            echo "DIFFERENT: $base"
        endif
    else
        echo "MISSING in UMC: $base"
    endif
end

echo ""
echo "Checking for UMC-only scripts..."
foreach script (umc/*tilebuilder*.csh umc/*tilebuilder*.pl)
    set base = `basename $script`
    if (! -f oss/$base) then
        echo "MISSING in OSS: $base"
    endif
end
