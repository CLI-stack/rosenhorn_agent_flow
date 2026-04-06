echo "#table#" > extract_all_path.spec 
echo "corner,high_delay_cell_issue,max_fanout_issue,lol_issue,skew_issue,different_clock_issue,half_edge_issue,ls_pin,cpsel_pin" >> extract_all_path.spec
if (-e extract_all_path) then
else
    mkdir extract_all_path
endif
set corner_list = ""
foreach rpt (`ls rpts/Sort*ReRoute*/*.INTERNAL.sorted.gz`)
    echo "## Checking $rpt"
    set n = 0
    set tot = `zgrep Startpoint: $rpt | wc -l`
    echo "$tot path in $rpt"
    if ($tot > 1000) then
        set tot = 1000
    endif
    set corner = `echo $rpt | awk -F "/" '{print $(NF-1)}'`
    set corner_list = "$corner_list $corner"
    if (-e extract_all_path/$corner.finished) then
        rm -rf extract_all_path/$corner.finished
    endif
    python3 $source_dir/script/extract_all_path.py --rpt $rpt --o extract_all_path/$corner.spec;touch  extract_all_path/$corner.finished &
    #python3 $source_dir/script/spec2Html.py --spec extract_all_path/$corner.spec --html extract_all_path/$corner.html
end
foreach corner (`echo $corner_list`)
    source $source_dir/script/wait_file_finish.csh extract_all_path/$corner.finished
    echo "# found extract_all_path/$corner.finished"
    python3 $source_dir/script/spec2Html.py --spec extract_all_path/$corner.spec --html extract_all_path/$corner.html
    #set n_max_fanout_issue = `cat extract_all_path/$corner.spec | awk -F "," '{print $3}' | sort -u | egrep "\S" | wc -l`
    set n_high_delay_cell_issue = `cat extract_all_path/$corner.spec | grep -v "high_delay_cell_issue" | awk -F "," '{print $2}' | sort -u | egrep "\S" | wc -l`
    set n_max_fanout_issue = `cat extract_all_path/$corner.spec | grep -v "high_delay_cell_issue" | awk -F "," '{print $3}' | sort -u | egrep "\S" | wc -l`
    set n_lol_issue = `cat extract_all_path/$corner.spec | grep -v "high_delay_cell_issue" | awk -F "," '{print $4}' | sort -u | egrep "\S" | wc -l`
    set n_skew_issue = `cat extract_all_path/$corner.spec | grep -v "high_delay_cell_issue" | awk -F "," '{print $5}' | sort -u | egrep "\S" | wc -l`
    set n_different_clock_issue = `cat extract_all_path/$corner.spec| grep -v "high_delay_cell_issue" | awk -F "," '{print $6}' | sort -u | egrep "\S" | wc -l`
    set n_half_edge_issue = `cat extract_all_path/$corner.spec | grep -v "high_delay_cell_issue" | awk -F "," '{print $7}' | sort -u | egrep "\S" | wc -l`
    set n_ls_pin = `cat extract_all_path/$corner.spec | grep -v "high_delay_cell_issue" | awk -F "," '{print $8}' | sort -u | egrep "\S" | wc -l`
    set n_cpsel_pin = `cat extract_all_path/$corner.spec | grep -v "high_delay_cell_issue" | awk -F "," '{print $9}' | sort -u | egrep "\S" | wc -l`
    set corner_path = `resolve extract_all_path/$corner.html` 
    echo "$corner_path,$n_high_delay_cell_issue,$n_max_fanout_issue,$n_lol_issue,$n_skew_issue,$n_different_clock_issue,$n_half_edge_issue,$n_ls_pin,$n_cpsel_pin" >> extract_all_path.spec
end
echo "#table end#" >> extract_all_path.spec
python3 $source_dir/script/spec2Html.py --spec extract_all_path.spec --html extract_all_path.html

