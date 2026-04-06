# This is agent
#source -v -e /tool/aticad/1.0/src/zoo/mi400/mid/optimization/AutoFP.tcl
source /tools/aticad/1.0/src/zoo/PD_agent/tile/optimizer/fix_mem_orientation.tcl
create_grid -x_step 0.048 -y_step 0.273 -x_offset 0.0 -y_offset 0.0 -orientations {R0 MY MX R180} testGrid1
snap_cells_to_block_grid -grid testGrid1 -cells [get_cells -hierarchical -filter "is_hard_macro"]
