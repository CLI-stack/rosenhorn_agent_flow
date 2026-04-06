while(1)
    set current_date = `date`
    echo "-------------------------------------------------------------------------------     $current_date"
    grep "Description" mailConfig.txt 
    chmod 700 mailConfig.txt 
    set source_dir = `pwd`
    source script/env.csh
    python3 script/read_azure_mail.py
    set n_llmFormatter = `grep llmFormatter mailConfig.txt | awk '{print $2}' | sed 's/\r//g' | wc -w`
    set llmFormatter = `grep llmFormatter mailConfig.txt | awk '{print $2}' | sed 's/\r//g'`
    if ($n_llmFormatter > 0) then
        if ($llmFormatter == 1) then
            echo "## User llmFormatter." 
            source script/llm_formatter.csh
        endif
    endif
    echo "# sleep 10s"
    sleep 10
end

