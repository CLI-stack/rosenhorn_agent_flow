set a0 = $1
set a1 = $2
python3 /tools/aticad/1.0/src/zoo/PD_agent/tile/read_csv.py --csv $a0 | awk -F ',' '{if (NF == 3) {print $1","$2","$3} else {print $1","$2","}}' > merged_argument_0.csv
python3 /tools/aticad/1.0/src/zoo/PD_agent/tile/read_csv.py --csv $a1 | awk -F ',' '{if (NF == 3) {print $1","$2","$3} else {print $1","$2","}}' > merged_argument_1.csv
cat merged_argument_0.csv merged_argument_1.csv | sort -u > merged_argument.csv
rm merged_argument_0.csv
rm merged_argument_1.csv
