
update_timing -full
hyper_route_opt

report_qor > rpts/FxOptRoute/before_move_qor.rpt
set cells_before_move [get_attribute -quiet [get_bounds] cells]
if {[sizeof_collection [get_bounds -quiet region_*]] > 0} {
    remove_bounds [get_bounds -quiet region_*]
}
dfpcommon_create_bounds_for_user_cell_list
dfpcommon_create_ls_bounds
dfpcommon_postprocess_region_bounds
set cells_after_move [get_attribute -quiet [get_bounds] cells]
set no_va_cells [remove_from_collection $cells_before_move $cells_after_move]
if {[sizeof_collection $no_va_cells] > 0} {
    place_eco_cells -cells $no_va_cells -legalize_only
}
report_qor > rpts/FxOptRoute/after_move_qor.rpt

