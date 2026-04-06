set f = $1
set limit = $2
set n_limit = `echo "$limit" | wc -w`
if ($n_limit > 0) then
else
    set limit = 1440
endif
set n_wait = 0
while(1)
    if (-e $f) then
        set n_slash = `echo $f | grep "/" | wc -w` 
        if ($n_slash == 0) then
            echo "# Found $f." > wait_file_finish.$f.finish
        else
            echo "# Found $f." 
        endif
        break
    endif
    set n_wait = `expr $n_wait + 1`
    echo "hi"
    if ($n_wait > $limit) then
        set n_slash = `echo $f | grep "/" | wc -w`
        if ($n_slash == 0) then
            echo "# Wait $f for $limit * 5s, exit" > wait_file_finish.$f.timeout
        endif
            
        break
    endif
    echo "# Continue to wait $f..."
    sleep 5
end

