# Created on Fri May 25 13:30:23 2023 @author: Simon Chen simon1.chen@amd.com
set users = `whoami`
set user_path = `pwd`
set date = `date`
set n_html = `ls data/*.html | wc -l`
python3 $source_dir/script/shift.py > shift.csh
source shift.csh
sleep 3
rm shift.csh
