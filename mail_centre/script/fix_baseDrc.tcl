set_app_options -name place.coarse.fix_hard_macros -value false; fix_floorplan_rules
write_def -objects [get_placement_blockages *] data/fix_baseDrc.def
exit
