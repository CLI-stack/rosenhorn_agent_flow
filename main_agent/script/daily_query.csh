set source_dir = `pwd`
set current_date = `date | sed 's/:/ /g' | awk '{print int($3/1)}'`
if (-e data/record_daily_query) then
    set n_record = `cat data/record_daily_query`
    echo "# Daily query: $current_date $n_record"
    if ($current_date == $n_record) then
    else
        echo "$current_date" > data/record_daily_query
        echo "# Launch query..."
    endif
else
    echo "# Create daliy query."
    echo "$current_date" > data/record_daily_query
endif

