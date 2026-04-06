set llmKey = `python3 script/read_csv.py --csv assignment.csv | grep "^llmKey," | awk -F "," '{print $2}'`
set n_llmKey = `echo $llmKey | wc -w`
if ($n_llmKey == 0) then
    echo "# chatbot need llm key, please specify it in assignment.csv as below:"
    echo "llmKey,your_key"
    exit
endif
set source_dir = `pwd`
echo "AMD_API_GATEWAY_OCP_SUBSCRIPTION_KEY=$llmKey" > .env
source /tool/aticad/1.0/src/zoo/PD_AI_AGENT/LLM_FORMATTER_CHATBOT/pdAgent.csh --assignment-file $source_dir/assignment.csv --output-file $source_dir/chatbot.csv --key-file $source_dir/.env
