source script/env.csh
foreach csv (`ls *.csv`)
    python3 $source_dir/script/check_csv.py --csv $csv
end
