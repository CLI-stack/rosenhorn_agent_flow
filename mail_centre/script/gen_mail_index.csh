#set source_dir = `pwd`
echo "#table#" > data/mail_index_spec
echo "Tag,From,Subject,Link" >> data/mail_index_spec
foreach html (`ls -lat data/*_spec.html | awk '{print $9}' | grep "[0-9]" | grep -v end | head -n 8`)
    set tag = `echo $html | sed 's/\./ /g' | sed 's/\// /g'  | sed 's/_/ /g' | awk '{print $2}'` 
    set from = `grep -m1 "From:" $html | awk '{print $3}'` 
    set subject = `grep -m1 "Subject:" $html | sed 's/<span> Subject://g'` 
    set link = "$source_dir/$html"
    echo "$tag,$from,$subject,$link" >> data/mail_index_spec
end 
echo "#table end#" >> data/mail_index_spec
source csh/env.csh
python $source_dir/py/spec2Html.py --spec $source_dir/data/mail_index_spec --html $source_dir/mail_index.html

