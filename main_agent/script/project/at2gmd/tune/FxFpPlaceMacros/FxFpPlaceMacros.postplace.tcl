source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_diesize.tcl
source /tool/aticad/1.0/src/zoo/PD_agent/tile/debug/check_dtcd_distance.tcl
source /tool/aticad/1.0/src/zoo/PD_agent/tile/optimizer/proc_pnr.tcl
checkHalo /tools/aticad/1.0/src/zoo/PD_agent/tile/project/cumberland/macro_halo_guidelines.txt 
set stage "NLC"
if {$stage == "NLC"} {
} else {
    create_grid -x_step 0.048 -y_step 0.273 -x_offset 0.0 -y_offset 0.0 -orientations {R0 MY MX R180} testGrid1
    rotate_objects [get_cells tile_dfx/ros_0/genblk2_perfro_macro] -orient R0
    snap_cells_to_block_grid -grid testGrid1 -cells [get_cells -hierarchical -filter "is_hard_macro"]
    snapMacro 0.048 4.272 0.026 3.796
    if {[get_attribute [current_design] name] == "cf_clk_dfs4_t" || [get_attribute [current_design] name] == "io_refclkiobuf_t" || [get_attribute [current_design] name] == "io_xvmin_t" || [get_attribute [current_design] name] == "secip_fuse_t" || [get_attribute [current_design] name] == "cf_clk_dfs2_t" || [get_attribute [current_design] name] == "cf_ctsen_1_t" || [get_attribute [current_design] name] == "cf_ucieclk_t" || [get_attribute [current_design] name] == "vdci_ats_df_t" || [get_attribute [current_design] name] == "vdci_cake_ucis_t" || [get_attribute [current_design] name] == "vdci_twix_ssbdci_t" || [get_attribute [current_design] name] == "df_spf_t" } {
        remove_placement_blockages -all
        addMacroBkg [get_cells -hierarchical * -filter "design_type == macro"] 0.624 0.897 0.048 0 0.273 0.195
    }
}

