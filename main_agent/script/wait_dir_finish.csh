set dir = $1
set limit = $2
set n_limit = `echo "$limit" | wc -w`
if ($n_limit > 0) then
else
    set limit = 1440
endif
set n_wait = 0
while(1)
    if (-e $dir) then
        echo "# Found $dir." 
        touch wait_dir_finish
        break
    endif
    set n_wait = `expr $n_wait + 1`
    if ($n_wait > $limit) then
       echo "# Wait $dir for $limit * 5s, exit" 
            
        break
    endif
    echo "# Continue to wait $dir..."
    sleep 5
end

