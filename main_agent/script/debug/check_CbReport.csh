# check M15.R.1.
set n_viols = `grep "M15.R.1." rpts/CbBaseFPDRC/drc.sum | awk '{print $8}' | grep "[1-9]" | wc -l`
if ($n_viols > 0) then
    set id_error = "id_0001" 
    if (-e M15_R_1.CbBaseFPDRC.analyze_target.log) then
        set n_id = `grep $id_error M15_R_1.CbBaseFPDRC.analyze_target.log | wc -w`
        if ($n_id == 0) then
            echo "ERROR: $id_error M15.R.1. found, use DFP_MACRO_PIN_TO_STRIPE to fix" >> M15_R_1.CbBaseFPDRC.analyze_target.log
        endif
    else
         echo "ERROR: $id_error M15.R.1. found, use DFP_MACRO_PIN_TO_STRIPE to fix" >> M15_R_1.CbBaseFPDRC.analyze_target.log
    endif
endif


