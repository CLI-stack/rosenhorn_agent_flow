#!/bin/csh
source script/unalias.csh
while(1)
    if (-e vto_exit) then
        echo "## Found vto_exit , exist vto."
        break
    endif
    source script/run_sep.csh 1111 | tee run_sep.log
    sleep 2
end
