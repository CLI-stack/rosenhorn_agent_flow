# check unplace pin
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/check_and_fix_unplaced_ports.tcl
# check offtrack pin
source /tools/aticad/1.0/src/zoo/PD_agent/tile/debug/check_fix_offtrack.tcl
# check vdci pin
source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_vdci_pin.tcl
# fix dtcd spacing issue
# source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/add_dtcd_blockage.tcl
# fix macro to boudary spacing
source /tool/aticad/1.0/src/zoo/PD_agent/tile/project/cumberland/fix_macro_boundary_spacing.tcl
# unfix mem
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/unfix_mem.tcl
# unfix macro
set macros {FTO_FIP_TSMCN3E_PERFROH143_B0 N03_DTCD_ALL_M11_220327 mapsmro_tsmc3ne17m t3tmac_ckhinvx32_overlay}
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/unfix_macro.tcl
# rotate macros whose height is not multiple of 0.286 which cause snap grid failed
rotateMacro
# check clock port distance far from center gravity of regs
source /tools/aticad/1.0/src/zoo/PD_agent/tile/debug/check_clock_port_distance.tcl 
# check if port on the opposite side of macro pins
source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_port_edge.tcl
create_grid -x_step 0.048 -y_step 0.286 -x_offset 0.0 -y_offset 0.0 -orientations {R0 MY MX R180} testGrid1
set macros [get_cells -hierarchical * -filter "design_type == macro"]
set tsv [get_cells -hierarchical * -filter "ref_name =~ *tsv*"]
set macros [remove_from_collection $macros $tsv]
rotate_objects [get_cells tile_dfx/ros_0/genblk2_perfro_macro] -orient R0
snap_cells_to_block_grid -grid testGrid1 -cells $macros
snapMacros $macros 0.048 4.272 0.026 3.796

