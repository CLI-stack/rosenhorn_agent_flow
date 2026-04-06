while(1)
    set current_date = `date`
    echo "-------------------------------------------------------------------------------     $current_date"
    grep "Description" mailConfig.txt 
    chmod 750 mailConfig.txt 
    set source_dir = `pwd`
    set n_twiki = `grep twiki mailConfig.txt | wc -w`
    if ($n_twiki > 0) then
        python3 script/download_tasksMail_from_twiki.py
    else
        perl script/readTaskMail.pl "tasksMail.csv" 
    endif
    cp tasksMail.csv tasksMail.win.csv
    set n_azure = `grep tenant_id mailConfig.txt | wc -w`
    if ($n_azure > 0) then
        source script/env.csh
        python3 script/read_azure_mail.py
        cp tasksMail.csv tasksMail.azure.csv
        python3 $source_dir/script/merge_tasks.py --mailFile tasksMail.win.csv --tasksLLMFile tasksMail.csv 
    endif
    set n_llmFormatter = `grep llmFormatter mailConfig.txt | awk '{print $2}' | sed 's/\r//g' | wc -w`
    set llmFormatter = `grep llmFormatter mailConfig.txt | awk '{print $2}' | sed 's/\r//g'`
    if ($n_llmFormatter > 0) then
        if ($llmFormatter == 1) then
            echo "## User llmFormatter." 
            source script/llm_formatter.csh
        endif
    endif
    echo "# sleep 12 ..."
    sleep 12
end

