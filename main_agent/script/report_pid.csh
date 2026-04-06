set keyword = $1
foreach pid (`ps -h | grep $keyword | awk '{print $1}'`)
    ls -l /proc/$pid/cwd
end
