set tag = $1
set sender = $2
set name = `echo $sender | sed 's/\@/ /g' | sed 's/\./ /g' | sed 's/[0-9]\+//g'  | awk '{print $1}'`
set target_run_dir = ""
set run_status = "failed"
set extraMailAddress = "none"
#touch data/$tag
#touch data/$tag.params
#rm data/${tag}*
touch data/$tag.params
set n_instruction = 0
echo "# Execute task: $tag"
echo "Hi $name," > data/${tag}_spec
