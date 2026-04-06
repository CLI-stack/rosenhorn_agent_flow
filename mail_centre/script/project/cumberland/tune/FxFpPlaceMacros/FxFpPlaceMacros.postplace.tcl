source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_diesize.tcl
source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_dtcd_distance.tcl
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/proc_pnr.tcl
checkHalo /tools/aticad/1.0/src/zoo/PD_agent/tile/project/cumberland/macro_halo_guidelines.txt 
create_grid -x_step 0.048 -y_step 0.286 -x_offset 0.0 -y_offset 0.0 -orientations {R0 MY MX R180} testGrid1
snap_cells_to_block_grid -grid testGrid1 -cells [get_cells -hierarchical -filter "is_hard_macro"]
snapMacro 0.048 4.272 0.026 3.796
if {[get_attribute [current_design] name] == "cf_secclk_mid_t"} {
    remove_placement_blockages -all
    addMacroBkg [get_cells -hierarchical * -filter "design_type == macro"] 0.624 0.9425 0.048 0 0.286 0.0845
}

if {[get_attribute [current_design] name] == "io_dfx_gpio1p8_pcc_i2c_mid_t"} {
    remove_placement_blockages -all
    addMacroBkg [get_cells -hierarchical * -filter "design_type == macro"] 0.624 0.9425 0.048 0 0.286 0.0845
}

if {[get_attribute [current_design] name] == "io_dfx_gpio1p8_smuio_mid_t"} {
    remove_placement_blockages -all
    addMacroBkg [get_cells -hierarchical * -filter "design_type == macro"] 0.624 0.9425 0.048 0 0.286 0.0845
}

if {[get_attribute [current_design] name] == "cf_thm_pa_gpio_mid_t"} {
    remove_placement_blockages -all
    addMacroBkg [get_cells -hierarchical * -filter "design_type == macro"] 0.624 0.9425 0.048 0 0.286 0.0845
}

if {[get_attribute [current_design] name] == "cf_clkc2_mid_t"} {
    remove_placement_blockages -all
    addMacroBkg [get_cells -hierarchical * -filter "design_type == macro"] 0.624 0.9425 0.048 0 0.286 0.0845
}

if {[get_attribute [current_design] name] == "io_dfx_misc_dualdftio0_mid_t"} {
    remove_placement_blockages -all
    addMacroBkg [get_cells -hierarchical * -filter "design_type == macro"] 0.624 0.9425 0.048 0 0.286 0.0845
}

