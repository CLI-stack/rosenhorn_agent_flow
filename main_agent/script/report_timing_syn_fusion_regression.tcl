
file mkdir rpts/rtlpd_rpts_${TARGET_NAME}

set tile [get_object_name [current_design]]
#set report_dir rpts/rtlpd_rpts_${TARGET_NAME}
#source /home/yigiskin/scripts/mem_analysis_t.tcl
#mem_analysis $report_dir/${tile}_mem_rpt.csv

set all_registers_include_icg TRUE

set tile_all_ports    [get_ports *]
set tile_input_ports  [all_inputs]
set tile_output_ports [all_outputs]
set seq_cells  [all_registers]
set all_mem    [filter_collection $seq_cells "ref_name =~ ct* || ref_name =~ t*"]
set all_mem_in [get_pins -of [get_cells $all_mem] -filter "direction==in"]
set all_mem_ck [get_pins -of [get_cells $all_mem] -filter "is_clock_pin==true"]
set all_cg     [filter_collection $seq_cells "is_integrated_clock_gating_cell==true"]
set all_cg_in  [get_pins -of [get_cells $all_cg] -filter "direction==in"]
set all_reg    [remove_from_collection $seq_cells [get_cells "$all_mem $all_cg"]]
set all_reg_in [get_pins -of [get_cells $all_reg] -filter "direction==in"]

set all_ports_and_mem [add_to_collection $tile_all_ports $all_mem]

###############################################################################
redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_reg2reg.rpt.gz {report_timing -to $all_reg_in -exclude $all_ports_and_mem -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 0 -max_paths 100000 -nworst 1}
redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_reg2reg.rpt.gz {report_timing -to $all_reg_in -exclude $all_ports_and_mem -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 300 -max_paths 200000 -nworst 1} 

if {[sizeof_collection $all_cg_in] > 0} {
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_cg.rpt.gz {report_timing -to $all_cg_in -exclude $tile_all_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 0 -max_paths 100000 -nworst 1}
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_cg.rpt.gz {report_timing -to $all_cg_in -exclude $tile_all_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 300 -max_paths 200000 -nworst 1}
} else {
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_cg.rpt.gz {echo "INFO: No clock gating in design"}
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_cg.rpt.gz {echo "INFO: No clock gating in design"}
}

if {[sizeof_collection $all_mem_in] > 0} {
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_to_mem.rpt.gz {report_timing -to $all_mem_in -exclude $tile_all_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 0 -max_paths 100000 -nworst 1} 
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_to_mem.rpt.gz {report_timing -to $all_mem_in -exclude $tile_all_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 300 -max_paths 200000 -nworst 1}
} else {
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_to_mem.rpt.gz {echo "INFO: No memory macros in design"}
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_to_mem.rpt.gz {echo "INFO: No memory macros in design"}
}


if {[sizeof_collection $all_mem_ck] > 0} {
redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_from_mem.rpt.gz {report_timing -from $all_mem_ck -exclude $tile_all_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 0 -max_paths 100000 -nworst 1}
redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_from_mem.rpt.gz {report_timing -from $all_mem_ck -exclude $tile_all_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 300 -max_paths 200000 -nworst 1}
} else {
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_from_mem.rpt.gz {echo "INFO: No memory macros in design"}
  redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_from_mem.rpt.gz {echo "INFO: No memory macros in design"}
}

redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_i2c.rpt.gz {report_timing -from $tile_input_ports -to $seq_cells -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 0 -max_paths 100000 -nworst 1}
redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_i2c.rpt.gz {report_timing -from $tile_input_ports -to $seq_cells -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 300 -max_paths 200000 -nworst 1}

redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_c2o.rpt.gz {report_timing -from $seq_cells -to $tile_output_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 0 -max_paths 100000 -nworst 1}
redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_c2o.rpt.gz {report_timing -from $seq_cells -to $tile_output_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 300 -max_paths 200000 -nworst 1}

redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_vio_i2o.rpt.gz {report_timing -from $tile_input_ports -to $tile_output_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 0 -max_paths 100000 -nworst 1}
redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/timing_all_i2o.rpt.gz {report_timing -from $tile_input_ports -to $tile_output_ports -delay_type max -nosplit -nets -include_hierarchical_pins -capacitance -transition_time -significant_digits 2 -input_pins -slack_lesser_than 300 -max_paths 200000 -nworst 1}
###############################################################################


############## Report Area #################
redirect -compress -file rpts/rtlpd_rpts_${TARGET_NAME}/report_area.rpt.gz {report_area -hier -nosplit}
############################################

source -v -e $P(ALLTILES_DIR)/tile_scripts/find_all_clock_latency.tcl
source -v -e $P(ALLTILES_DIR)/tile_scripts/find_io_clk_issues.tcl
source -v -e $P(ALLTILES_DIR)/tile_scripts/find_io_ports_info.tcl
source -v -e $P(ALLTILES_DIR)/tile_scripts/find_tile_port_metrics.tcl
source -v -e $P(ALLTILES_DIR)/tile_scripts/find_design_info.tcl
