set cs [current_scenario]
current_scenario setup_tt0p6v0c_typrc100c_FuncTT0p6v
set_clock_uncertainty -setup 20 [get_clocks {FCLK}]
current_scenario [get_object_name $cs]

