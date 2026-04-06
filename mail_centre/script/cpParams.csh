set release = "NLC"
set source_dir = `pwd`
foreach t (`python3 $source_dir/script/read_csv.py --csv assignment.csv | grep "tile," | awk -F "," '{print $2}'`)
    echo "# create params for $t"
    mkdir -p params/$t
    cp params/secip_mp1_mid_t/* params/$t 
end
