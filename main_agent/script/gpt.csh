set contextFile = $1
set question = ""
source /tools/aticad/1.0/src/zoo/PD_agent/tile/env.csh
deactivate
set llmKey = `python3 script/read_csv.py --csv assignment.csv | grep "llmKey,"  | awk -F "," '{print $2}' | sed 's/\r//g'`
python3 /tools/aticad/1.0/src/zoo/PD_agent/tile/llm.py --key $llmKey --question "$question" --contextFile $contextFile | tee llm.log
sed -n '/```/,/```/p' llm.log | sed '/```/d' > llm_output.py
source /tools/aticad/1.0/src/zoo/PD_agent/tile/env.csh 
