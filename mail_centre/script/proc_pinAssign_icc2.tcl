proc fastPlacePin {pin_name bbox layer} {
if {[sizeof_collection [get_shapes -quiet -of_objects [get_ports $pin_name]]] > 0} {
    puts "# WARNING, $pin_name is exists"
    return 0
}
set shape [create_shape -shape_type rect -boundary $bbox -layer $layer]
set terminal [create_terminal -port $pin_name -object $shape -direction all]
set_attribute [get_ports $pin_name] physical_status fixed
#set term [get_terminals -filter {port.full_name == $pin_name}]
#set_attribute $term shape.bbox $bbox
}

proc fastDupPlacePin {pin_name bbox layer} {
set shape [create_shape -shape_type rect -boundary $bbox -layer $layer]
set terminal [create_terminal -port $pin_name -object $shape -direction all]
set_attribute [get_ports $pin_name] physical_status fixed
}

proc fastRePlacePin {pin_name bbox layer} {
unplacePort $pin_name
set shape [create_shape -shape_type rect -boundary $bbox -layer $layer]
set terminal [create_terminal -port $pin_name -object $shape -direction all]
set_attribute [get_ports $pin_name] physical_status fixed
}

proc genEdgeInfo {suffix} {
set int_factor 160000
set f [open edges_${suffix}.info w]
set tiles [get_cells * -filter "hierarchy_type == block"]
#set tiles [get_cells {athub_rpb_t compute_array0 compute_array1 compute_array2 compute_array3 dce_aux_t dce_dc0_t dce_dc1_t0 dce_dc1_t1 dce_dc1_t2 dce_dc1_t3 dce_dc1_t4 dce_dc1_t5 dce_dca_t dce_dci_t dce_phy_t df_cake_t0 df_cake_t1 df_cs_umc_t0 df_cs_umc_t1 df_cs_umc_t10 df_cs_umc_t11 df_cs_umc_t12 df_cs_umc_t13 df_cs_umc_t14 df_cs_umc_t15 df_cs_umc_t16 df_cs_umc_t17 df_cs_umc_t18 df_cs_umc_t19 df_cs_umc_t2 df_cs_umc_t20 df_cs_umc_t21 df_cs_umc_t22 df_cs_umc_t23 df_cs_umc_t24 df_cs_umc_t25 df_cs_umc_t26 df_cs_umc_t27 df_cs_umc_t28 df_cs_umc_t29 df_cs_umc_t3 df_cs_umc_t30 df_cs_umc_t31 df_cs_umc_t4 df_cs_umc_t5 df_cs_umc_t6 df_cs_umc_t7 df_cs_umc_t8 df_cs_umc_t9 df_gc_tcdx_t0 df_gc_tcdx_t1 df_gc_tcdx_t10 df_gc_tcdx_t11 df_gc_tcdx_t12 df_gc_tcdx_t13 df_gc_tcdx_t14 df_gc_tcdx_t15 df_gc_tcdx_t2 df_gc_tcdx_t3 df_gc_tcdx_t4 df_gc_tcdx_t5 df_gc_tcdx_t6 df_gc_tcdx_t7 df_gc_tcdx_t8 df_gc_tcdx_t9 df_tcdx16_t df_tcdx17_t df_tcdx18_t df_tcdx19_t df_tcdx20_t df_tcdx21_t df_tcdx22_t df_tcdx23_t df_tcdx24_t df_tcdx25_t df_tcdx26_m0_t df_tcdx27_a0_t df_tcdx28_m1_t df_tcdx29_pie_d0_t df_tcdx30_t df_tcdx_ch0_t_bl df_tcdx_ch0_t_br df_tcdx_ch0_t_tl df_tcdx_ch0_t_tr df_tcdx_ch1_t_l df_tcdx_ch1_t_r df_tcdx_ch2_t_l df_tcdx_ch2_t_r df_tcdx_ch3_t_top0 df_tcdx_ch3_t_top1 df_tcdx_ch3_t_top2 df_tcdx_ch3_t_top3 dfx_dft_t dfx_dftcnr0_t dfx_dftcnr1_t dfx_dftcnr2_t dfx_dftcnr3_t dxio_pcie_cphy_t dxio_pcie_pcs1x16_t dxio_wafl_cphy_t dxio_xgmi_cphy_t0 dxio_xgmi_cphy_t1 dxio_xgmi_pcs1x16_t0 dxio_xgmi_pcs1x16_t1 gc_cb_t000 gc_cb_t001 gc_cb_t002 gc_cb_t003 gc_cb_t100 gc_cb_t101 gc_cb_t102 gc_cb_t103 gc_cb_t200 gc_cb_t201 gc_cb_t202 gc_cb_t203 gc_cb_t300 gc_cb_t301 gc_cb_t302 gc_cb_t303 gc_cb_tr0 gc_cb_tr1 gc_cpaxi_t gc_cpc_t gc_cpf_t gc_cpg_t gc_db_t000 gc_db_t001 gc_db_t002 gc_db_t003 gc_db_t100 gc_db_t101 gc_db_t102 gc_db_t103 gc_db_t200 gc_db_t201 gc_db_t202 gc_db_t203 gc_db_t300 gc_db_t301 gc_db_t302 gc_db_t303 gc_db_tr0 gc_db_tr1 gc_dsa_t gc_dso_t gc_ea_t0 gc_ea_t1 gc_ea_t10 gc_ea_t11 gc_ea_t12 gc_ea_t13 gc_ea_t14 gc_ea_t15 gc_ea_t16 gc_ea_t17 gc_ea_t18 gc_ea_t19 gc_ea_t2 gc_ea_t20 gc_ea_t21 gc_ea_t22 gc_ea_t23 gc_ea_t24 gc_ea_t25 gc_ea_t26 gc_ea_t27 gc_ea_t28 gc_ea_t29 gc_ea_t3 gc_ea_t30 gc_ea_t31 gc_ea_t4 gc_ea_t5 gc_ea_t6 gc_ea_t7 gc_ea_t8 gc_ea_t9 gc_iwgr_t gc_pa2_t0 gc_pa2_t1 gc_rmi_t00 gc_rmi_t01 gc_rmi_t10 gc_rmi_t11 gc_rmi_t20 gc_rmi_t21 gc_rmi_t30 gc_rmi_t31 gc_scb_t0 gc_scb_t1 gc_scb_t2 gc_scb_t3 gc_sct_t0 gc_sct_t1 gc_sct_t2 gc_sct_t3 gc_spim_t0 gc_spim_t1 gc_spim_t2 gc_spim_t3 gc_spisb_t0 gc_spisb_t1 gc_spisb_t2 gc_spisb_t3 gc_sx_t00 gc_sx_t10 gc_sx_t20 gc_sx_t30 gc_tca_t0 gc_tca_t1 gc_tcc_t0 gc_tcc_t1 gc_tcc_t10 gc_tcc_t11 gc_tcc_t12 gc_tcc_t13 gc_tcc_t14 gc_tcc_t15 gc_tcc_t2 gc_tcc_t3 gc_tcc_t4 gc_tcc_t5 gc_tcc_t6 gc_tcc_t7 gc_tcc_t8 gc_tcc_t9 gc_utcl2_atcl2_t gc_utcl2_misc_t gc_utcl2_vml2_t gc_vgt_t0 gc_vgt_t1 gc_vgt_t2 gc_vgt_t3 hubs_ea_t0 hubs_ea_t1 mmhub_utcl2_t nbio_nbif_t nbio_pcie_lc_t nbio_pcie_txrx_t nbio_shub_t oss_osssys_t oss_sdma_t smu_ccp_t smu_clka_t smu_clkb_t smu_clkc2_t0 smu_clkc2_t1 smu_clkc2_t2 smu_clkc3_t0 smu_clkc3_t1 smu_fuse_smuio_pwr_t smu_mp0_t smu_mp1_t smu_thm_t smu_tmon_t0p smu_tmon_t1p smu_wafl_t umc_hbm_phya_rep_t umc_hbm_phyb_rep_t umc_hbm_phyc_rep_t umc_hbm_phyd_rep_t umc_umc_t0 umc_umc_t1 umc_umc_t2 umc_umc_t3 umc_umc_t4 umc_umc_t5 umc_umc_t6 umc_umc_t7 umc_umcch_t00 umc_umcch_t01 umc_umcch_t02 umc_umcch_t03 umc_umcch_t10 umc_umcch_t11 umc_umcch_t12 umc_umcch_t13 umc_umcch_t20 umc_umcch_t21 umc_umcch_t22 umc_umcch_t23 umc_umcch_t30 umc_umcch_t31 umc_umcch_t32 umc_umcch_t33 umc_umcch_t40 umc_umcch_t41 umc_umcch_t42 umc_umcch_t43 umc_umcch_t50 umc_umcch_t51 umc_umcch_t52 umc_umcch_t53 umc_umcch_t60 umc_umcch_t61 umc_umcch_t62 umc_umcch_t63 umc_umcch_t70 umc_umcch_t71 umc_umcch_t72 umc_umcch_t73 uvd_uvdbe_t0 uvd_uvdbe_t1 uvd_uvdcf_t0 uvd_uvdcf_t1 uvd_uvdi_t0 uvd_uvdi_t1 uvd_uvdm_t0 uvd_uvdm_t1 uvd_uvdt_t0 uvd_uvdt_t1 uvd_uvdu_t0 uvd_uvdu_t1 vce_vcea_t vce_vcebc_t vdci_dce_aux_t vdci_df2crest_t vdci_gc2athub_t vdci_gc2df_t1 vdci_gc2df_t10 vdci_gc2df_t11 vdci_gc2df_t12 vdci_gc2df_t13 vdci_gc2df_t14 vdci_gc2df_t15 vdci_gc2df_t2 vdci_gc2df_t3 vdci_gc2df_t4 vdci_gc2df_t5 vdci_gc2df_t6 vdci_gc2df_t7 vdci_gc2df_t8 vdci_gc2df_t9 vdci_gc2soc_left_t vdci_gc2soc_right_t vdci_nbio_right_t vdci_nbio_top_t}]
#set tile_list [list umc_hbm_phya_rep_t gc_utcl2_atcl2_t gc_utcl2_misc_t gc_iwgr_t]
foreach_in_collection tile $tiles {
    set tile [get_cell $tile]
    set tile_name [get_attribute $tile full_name]
    set ref [get_attribute $tile ref_name]
    set inst_boundary_bboxes [get_attribute $tile boundary]
    set ori [get_attribute $tile orientation]
    set x [lindex [lindex [get_attribute $tile bbox] 0] 0]
    set y [lindex [lindex [get_attribute $tile bbox] 0] 1]
    for { set i 0 } { $i < [llength $inst_boundary_bboxes] } {incr i} {
        set llx [lindex [lindex $inst_boundary_bboxes $i] 0]
        set lly [lindex [lindex $inst_boundary_bboxes $i] 1]
        set j [expr $i + 1]
        set urx [lindex [lindex $inst_boundary_bboxes $j] 0]
        set ury [lindex [lindex $inst_boundary_bboxes $j] 1]
        if {$i == [expr [llength $inst_boundary_bboxes] - 1]} {
            set urx [lindex [lindex $inst_boundary_bboxes 0] 0]
            set ury [lindex [lindex $inst_boundary_bboxes 0] 1]
        }
        puts $f "$tile_name $ref $x $y $ori $llx $lly $urx $ury"
    }
}
close $f
}

proc dumpNonFeedPins {} {
foreach_in_collection net [get_nets *] {
    set FEED_flag 0
    set n_terms [sizeof_collection [all_connected $net]]
    if {$n_terms != 2} {
        continue
    }
    foreach term [all_connected $net] {
        set term_name [get_attribute $term full_name]
        #puts "$term_name $n_terms"
        if {[regexp {FEED} $term_name]} {
            set FEED_flag 1
            break
        }

    } 
    if {$FEED_flag == 1} {
        continue
    }
    set term_names ""
    foreach term [all_connected $net] {
        set term_names "$term_names [get_attribute $term full_name]"
    }
    puts "$term_names"
}
}

proc unplacePort {ports} {
foreach_in_collection port [get_ports $ports] {
    if {[regexp VSS [get_attribute $port full_name]] && [regexp FE_FEED [get_attribute $port full_name]] == 0 && [get_attribute [get_ports $port] layer_name] == "M11"} {
        continue
    }
    if {[regexp VDD [get_attribute $port full_name]] && [regexp FE_FEED [get_attribute $port full_name]] == 0 && [get_attribute [get_ports $port] layer_name] == "M11"} {
        continue
    }
    if {[sizeof_collection [get_shapes -quiet -of_objects [get_terminals -quiet -of_objects [get_ports $port]]]] != 0} {
        #puts "# unplace [get_object_name $port]"
        remove_shapes [get_shapes -of_objects [get_terminals -of_objects [get_ports $port]]]
        set_attribute [get_ports $port] physical_status unplaced 
    }
}
}

proc unplaceAllPort {} {
unplacePort *
puts "# Unplace [sizeof_collection [get_ports *]]"
}


proc placeRemainPin {pin_info} {
set PI [open $pin_info r]
set pins_placed ""
while {[gets $PI line] >= 0} {
    if {[regexp {^(\S+)\s+(\S+)\s+} $line inst pin_placed]} {
        set pins_placed [add_to_collection $pins_placed $pin_placed]
    }    
}
set all_pins [get_pins */*]
}

proc collectFeedPair {} {
global feed_net_array
global feed_tile_h
set feedRpt "rpts/OaFcCHIPReportCollapseConnectivity/feedthru_connectivity.CHIP.rpt.gz"
#set feedRpt "./test.rpt.gz"
set rpt [open "|gunzip -c $feedRpt" r]
puts "# Start parse $feedRpt ."
while {[gets $rpt line] >= 0} {
    if {[regexp {^net:(\S+)} $line match net_src]} {
        set pin_flag 1
        set pair ""
        set feed_net_array($net_src) ""
    }
    if {[regexp {[driv|load]:(\S+)\s*net:} $line match htermName] && $pin_flag == 1} {
        set feed_net_array($net_src) "$feed_net_array($net_src) $htermName"
    }
}
puts "# End parse $feedRpt. "
close $rpt
}

proc sortFeedPair {} {
global feed_tile_h
global feed_internal_pair_h
global feed_abut_pair_h
global feed_net_array
global feed_net_h

puts "# Start sort interal and abut feeds."
foreach net [array names feed_net_array] {
    for {set i 0} {$i < [llength $feed_net_array($net)]} {incr i} {
        set feed_net_h([lindex $feed_net_array($net) $i]) $net
        if {[regexp {(\S+)/FE_FEED} [lindex $feed_net_array($net) $i] match tile]} {
            if {[info exist feed_tile_h($tile)]} {
                set feed_tile_h($tile) "$feed_tile_h($tile) [lindex $feed_net_array($net) $i]"
            } else {
                set feed_tile_h($tile) "[lindex $feed_net_array($net) $i]"
            }
        }
        if {[expr ($i%2)]== 0 && $i > 1} {
            set feed_internal_pair_h([lindex $feed_net_array($net) $i]) [lindex $feed_net_array($net) [expr $i - 1]]
            set feed_internal_pair_h([lindex $feed_net_array($net) [expr $i - 1]]) [lindex $feed_net_array($net) $i]
            #puts "[lindex $feed_net_array($net) $i] $feed_internal_pair_h([lindex $feed_net_array($net) $i])"

        }
        if {[expr ($i%2)]== 1 && $i > 0} {
            set feed_abut_pair_h([lindex $feed_net_array($net) $i]) [lindex $feed_net_array($net) [expr $i - 1]]
            set feed_abut_pair_h([lindex $feed_net_array($net) [expr $i - 1]]) [lindex $feed_net_array($net) $i]
        }
    }
}
puts "# Finish sort interal and abut feeds."
}

proc checkInternalAlignment {tile} {
global feed_tile_h
global feed_internal_pair_h
global feed_abut_pair_h
global feed_net_array

if {[info exist feed_net_array] == 0} {
    puts "# No infor for feed_net_array, start collectFeedPair"
    collectFeedPair
    sortFeedPair
}

set o [open ${tile}.interMisalign.rpt w]
set th 200

foreach startHTermName $feed_tile_h($tile) {
    if {[info exist checked_h($startHTermName)]} {
        continue
    }
    # North South West East
    set startHTermPt0   [get_pins $startHTermName]
    set startHTermStatus [get_attribute $startHTermPt0 physical_status]
    if {[string equal $startHTermStatus "unplaced"]} {puts "location not found for $startHTermName"; continue}
    set term0 $startHTermName
    set hterm_loc [get_attribute $startHTermPt0 bbox]
    set llx0 [lindex [lindex $hterm_loc 0] 0]
    set lly0 [lindex [lindex $hterm_loc 0] 1]
    set urx0 [lindex [lindex $hterm_loc 1] 0]
    set ury0 [lindex [lindex $hterm_loc 1] 1]
    if {[expr $urx0 - $llx0] > [expr $ury0 - $lly0]} {
        set side0 "h"
    } else  {
        set side0 "v"
    }

    set startHTermPt1   [get_pins $feed_internal_pair_h($startHTermName)]
    set startHTermStatus [get_attribute startHTermPt1 physical_status]
    if {[string equal $startHTermStatus "unplaced"]} {puts "location not found for $startHTermName"; continue}
    set term1 $feed_internal_pair_h($startHTermName)
    set checked_h($term1) 1
    set hterm_loc [get_attribute $startHTermPt1 bbox]
    set llx1 [lindex [lindex $hterm_loc 0] 0]
    set lly1 [lindex [lindex $hterm_loc 0] 1]
    set urx1 [lindex [lindex $hterm_loc 1] 0]
    set ury1 [lindex [lindex $hterm_loc 1] 1]
    if {[expr $urx1 - $llx1] > [expr $ury1 - $lly1]} {
        set side1 "h"
    } else  {
        set side1 "v"
    }

    if {[string equal $side0 $side1] == 0} {
        continue
    }
    set side_pair "$side0 $side1"
    if {string equal $side0 "h"} {
        #puts "# hor: $y0 $y1 [expr abs($y0 - $y1)]"
        if {$llx0 == $llx1} {
            puts "## ERROR: $term0 $term1 are same side"
            continue
        }
        if {[expr abs($y0 - $y1)] > $th} {
            change_selection [get_nets -of_objects $startHTermPt0]
            change_selection [get_nets -of_objects $startHTermPt1]
            puts $o "$term0 $term1 [expr abs($lly0 - $lly1)]"
        }
    }
    if {string equal $side0 "v"} {
        #puts "# ver: $x0 $x1 [expr abs($x0 - $x1)]"
        if {$lly0 == $lly1} {
            puts "## ERROR: $term0 $term1 are same side"
            continue
        }

        if {[expr abs($x0 - $x1)] > $th} {
            change_selection [get_nets -of_objects $startHTermPt0]
            change_selection [get_nets -of_objects $startHTermPt1]
            puts $o "$term0 $term1 [expr abs($x0 - $x1)]"
        }
    }
}
close $o
}

proc dumpPreAssignPinLoc {} {
set v [open preAssignPins.drc w]
set pitch_h(M3) 0.044
set pitch_h(M4) 0.08
set pitch_h(M5) 0.076
set pitch_h(M6) 0.08
set pitch_h(M7) 0.076
set pitch_h(M8) 0.08
set pitch_h(M9) 0.076
set pitch_h(M10) 0.126
set pitch_h(M11) 0.126
set is_h(M3) 0
set is_h(M4) 1
set is_h(M5) 0
set is_h(M6) 1
set is_h(M7) 0
set is_h(M8) 1
set is_h(M9) 0
set is_h(M10) 1
set is_h(M11) 0

set reg_layer(M4) 1
set reg_layer(M5) 1
set reg_layer(M6) 1
set reg_layer(M7) 1
set reg_layer(M8) 1
set reg_layer(M9) 1

set llx_ini [lindex [get_attribute -quiet [get_tracks -filter "layer_name == M5"] start] 0]
set llx_ini 282.036
set lly_ini [lindex [get_attribute -quiet [get_tracks -filter "layer_name == M4"] start] 0]
set lly_ini -131.52


set pin_list {gc_iwgr_t/* gc_utcl2_misc_t/* compute_array*/* gc_ea_t*/* gc_dso_t/*}
set pin_list ""
foreach layer [array names pitch_h] {
    puts "# Collect pins by $layer"
    set pin_list [add_to_collection $pin_list [get_pins  */* -filter "layer_name == $layer"]]
}    
set n_pins [sizeof_collection $pin_list] 
set o [open preAssignPins.info w]
set f [open edges_reuse.info r]
while {[gets $f line] >= 0} {
    set inst [lindex $line 0]
    set ref [lindex $line 1]
    set x [lindex $line 2]
    set y [lindex $line 3]
    set ori [lindex $line 4]
    set llx [lindex $line 5]
    set lly [lindex $line 6]
    set urx [lindex $line 7]
    set ury [lindex $line 8]
    set edge "$llx $lly $urx $ury"
    set inst_ref_h($inst) $ref
    if {$llx ==$urx } {
        lappend edge_tile_h_h($inst) $edge
    } else {
        lappend edge_tile_v_h($inst) $edge
    }
}
close $f
set i_pins 0
set k_pins 0
foreach_in_collection pin [get_pins $pin_list -filter "physical_status == placed || physical_status == fixed"] { 
    incr i_pins
    incr k_pins
    if {$i_pins == 10000} {
        puts "$k_pins of $n_pins"
        set i_pins 0
    }
    set bbox [get_attribute $pin bbox]
    set llx [lindex [lindex $bbox 0] 0]
    set lly [lindex [lindex $bbox 0] 1]
    set urx [lindex [lindex $bbox 1] 0]
    set ury [lindex [lindex $bbox 1] 1]
    set pin_name [get_attribute $pin full_name]
    set layer [get_attribute $pin layer_name]
    if {[llength $layer] == 0} {
        continue
    }
    if {[info exist pitch_h($layer)] == 0} {
        continue
    }
    if {[regexp {(\S+)\/(\S+)} $pin_name match tile ref_pin]} {
    
    } else {
        puts "# no tile name for $pin_name"
        continue
    }
    #puts "$tile $llx $lly $urx $ury"
    if {$is_h($layer) == 1} {
        set is_hor 1
        set off_edge 1
        foreach edge $edge_tile_h_h($tile) {
            set llx_edge [lindex $edge 0]
            #puts "hi"
            if {$llx == $llx_edge} {
                set loc_x $llx
                set loc_y [expr ($lly + $ury) /2]
                set loc_y_orig $loc_y
                set loc_x_orig $loc_x
                if {[info exist reg_layer($layer)]} {
                    set loc_y [expr round(($loc_y - $lly_ini)/$pitch_h($layer))*$pitch_h($layer) + $lly_ini]
                }
                set off_edge 0
            }
            if {$urx == $llx_edge} {
                set loc_x $urx
                set loc_y [expr ($lly + $ury) /2]
                set loc_y_orig $loc_y
                set loc_x_orig $loc_x
                if {[info exist reg_layer($layer)]} {
                    set loc_y [expr round(($loc_y - $lly_ini)/$pitch_h($layer))*$pitch_h($layer) + $lly_ini]
                }
            set off_edge 0
            }
        }
        if {$off_edge == 1} {
            puts $v "$pin_name off edge"
            continue
        }
    } else {
        #puts "hello"
        set is_hor 0
        set off_edge 1
        foreach edge $edge_tile_v_h($tile) {
            #puts "$edge"
            set lly_edge [lindex $edge 1]
            if {$lly == $lly_edge} {
                set loc_y $lly
                set loc_x [expr ($llx + $urx) / 2]
                set loc_y_orig $loc_y
                set loc_x_orig $loc_x
                if {[info exist reg_layer($layer)]} {
                    set loc_x [expr round(($loc_x - $llx_ini)/$pitch_h($layer))*$pitch_h($layer) + $llx_ini]
                }
                set off_edge 0
            } 
            if {$ury == $lly_edge} {
                set loc_y $ury
                set loc_x [expr ($llx + $urx) / 2]
                set loc_x_orig $loc_x
                set loc_y_orig $loc_y
                if {[info exist reg_layer($layer)]} {
                    set loc_x [expr round(($loc_x - $llx_ini)/$pitch_h($layer))*$pitch_h($layer) + $llx_ini]
                }
                set off_edge 0
            }

        }
        if {$off_edge == 1} {
            puts $v "$pin_name off edge"
            continue
        }

    }
    set pitch $pitch_h($layer)
    puts $o "$pin_name $loc_x $loc_y $layer $is_hor $pitch $loc_x_orig $loc_y_orig"
}

foreach tile [array names inst_ref_h] {
   puts "# $tile bkg"
    set pin_name "$tile/VSS"
    foreach_in_collection shape [get_shapes -quiet -of_objects [get_pins $tile/VSS]] { 

        set bbox [get_attribute $shape bbox]
        set llx [lindex [lindex $bbox 0] 0]
        set lly [lindex [lindex $bbox 0] 1]
        set urx [lindex [lindex $bbox 1] 0]
        set ury [lindex [lindex $bbox 1] 1]
        #set pin_name [get_attribute $pin full_name]
        set layer [get_attribute $shape layer_name]
        if {[llength $layer] == 0} {
            continue
        }
        if {[info exist pitch_h($layer)] == 0} {
            continue
        }
        if {[regexp {(\S+)\/(\S+)} $pin_name match tile ref_pin]} {
        
        } else {
            puts "# no tile name for $pin_name"
            continue
        }
        #puts "$tile $llx $lly $urx $ury"
        if {$is_h($layer) == 1} {
            set is_hor 1
            set off_edge 1
            foreach edge $edge_tile_h_h($tile) {
                set llx_edge [lindex $edge 0]
                #puts "hi"
                if {$llx == $llx_edge} {
                    set loc_x $llx
                    set loc_y [expr ($lly + $ury) /2]
                    set loc_y_orig $loc_y
                    set loc_x_orig $loc_x
                    if {[info exist reg_layer($layer)]} {
                        set loc_y [expr round(($loc_y - $lly_ini)/$pitch_h($layer))*$pitch_h($layer) + $lly_ini]
                    }
                    set off_edge 0
                }
                if {$urx == $llx_edge} {
                    set loc_x $urx
                    set loc_y [expr ($lly + $ury) /2]
                    set loc_y_orig $loc_y
                    set loc_x_orig $loc_x
                    if {[info exist reg_layer($layer)]} {
                        set loc_y [expr round(($loc_y - $lly_ini)/$pitch_h($layer))*$pitch_h($layer) + $lly_ini]
                    }
                set off_edge 0
                }
            }
            if {$off_edge == 1} {
                puts $v "$pin_name off edge"
                continue
            }
        } else {
            #puts "hello"
            set is_hor 0
            set off_edge 1
            foreach edge $edge_tile_v_h($tile) {
                #puts "$edge"
                set lly_edge [lindex $edge 1]
                if {$lly == $lly_edge} {
                   set loc_y $lly
                    set loc_x [expr ($llx + $urx) / 2]
                    set loc_y_orig $loc_y
                    set loc_x_orig $loc_x
                    if {[info exist reg_layer($layer)]} {
                        set loc_x [expr round(($loc_x - $llx_ini)/$pitch_h($layer))*$pitch_h($layer) + $llx_ini]
                    }
                    set off_edge 0
                } 
                if {$ury == $lly_edge} {
                    set loc_y $ury
                    set loc_x [expr ($llx + $urx) / 2]
                    set loc_x_orig $loc_x
                    set loc_y_orig $loc_y
                    if {[info exist reg_layer($layer)]} {
                        set loc_x [expr round(($loc_x - $llx_ini)/$pitch_h($layer))*$pitch_h($layer) + $llx_ini]
                    }
                    set off_edge 0
                }
    
            }
            if {$off_edge == 1} {
                puts $v "$pin_name off edge"
                continue
            }

        }
        set pitch $pitch_h($layer)
        puts $o "$tile/VSS $loc_x $loc_y $layer $is_hor $pitch $loc_x_orig $loc_y_orig"
    }
}
close $v
close $o
}

proc checkPinDist {} {
set all_nets [get_nets * -filter "number_of_pins == 2"]
set i  0
set n [sizeof_collection $all_nets]
set f [open checkPinDist.rpt w]
foreach_in_collection net $all_nets {
    #puts "[get_object_name $net]"
    set invalid_net 0
    set points [get_attribute [get_net $net] pin_bbox]
    set tile_pair ""
    foreach_in_collection pin [all_connected $net] {
        set pin_name [get_object_name $pin]
        if {[regexp {/} $pin_name] == 0} {
            set invalid_net 1
            break
        }
        set  tile [get_attribute [get_cells -of_objects [get_pin $pin]] full_name]
        set tile_pair "$tile_pair $tile"
    }
    if {$invalid_net == 1} {
        continue
    }
    set x0 [lindex [lindex $points 0] 0]
    set y0 [lindex [lindex $points 0] 1]
    set x1 [lindex [lindex $points 1] 0]
    set y1 [lindex [lindex $points 1] 1]
    set net_name [get_attribute [get_net $net] full_name]
    set dis [expr abs($x1 - $x0) + abs($y1 - $y0)]
    if {$dis > 10} {
        puts $f "$net_name $dis $tile_pair"
    }
    #puts "$i of $n..."
    incr i 
    if {$i == 100} {
    }
}
close $f
}

proc dumpExcludedDfNet {} {
set  layer_dir(M3) 1
set  layer_dir(M4) 0
set  layer_dir(M5) 1
set  layer_dir(M6) 0
set  layer_dir(M7) 1
set  layer_dir(M8) 0
set  layer_dir(M9) 1
set  layer_dir(M10) 0
set  layer_dir(M11) 1
set all_nets [get_nets df_* -filter "number_of_pins == 2"]
set n [sizeof_collection $all_nets]
set f [open excludedDfNet w]
foreach_in_collection net $all_nets {
    set invalid_net 0
    set points [get_attribute -quiet [get_net $net] pin_bbox]
    set tile_pair ""
    set pin_pair ""
    foreach_in_collection pin [all_connected -leaf $net] {
        set pin_name [get_object_name $pin]
        set pin_pair "$pin_pair $pin_name"
        if {[regexp {/} $pin_name] == 0} {
            set invalid_net 1
            break
        }
        set  tile [get_attribute [get_cells -of_objects [get_pin $pin]] full_name]
        set tile_pair "$tile_pair $tile"

    }
    if {$invalid_net == 1} {
        continue
    }
    if {[regexp {FEED} $pin_pair] == 1} {
        continue
    }
    set layer0 [get_attribute -quiet [get_pins [lindex $pin_pair 0]] layer_name]
    set layer1 [get_attribute -quiet [get_pins [lindex $pin_pair 1]] layer_name]
    set points [get_attribute [get_net $net] pin_bbox]

    set x0 [lindex [lindex $points 0] 0]
    set y0 [lindex [lindex $points 0] 1]
    set x1 [lindex [lindex $points 1] 0]
    set y1 [lindex [lindex $points 1] 1]

    set dis [expr abs($x1 - $x0) + abs($y1 - $y0)]

    set net_name [get_attribute [get_net $net] full_name]
     if {[info exist layer_dir($layer0)] == 0 || [info exist layer_dir($layer1)] == 0 } {
        continue
    }
    if {$dis < 250} {
        puts $f "$net_name" 
    }

}
close $f
}

proc checkPinAlignment {th} {
set layer_dir {}

dict set layer_dir M2 0
dict set layer_dir M3 1
dict set layer_dir M4 0
dict set layer_dir M5 1
dict set layer_dir M6 0
dict set layer_dir M7 1
dict set layer_dir M8 0
dict set layer_dir M9 1
dict set layer_dir M10 0
dict set layer_dir M11 1

set all_nets [get_nets *umc* -filter "number_of_pins == 2"]
#set all_nets [get_nets df_* -filter "number_of_pins == 2"]
set all_nets [get_nets * -filter "number_of_pins == 2"]
set i  0
set n [sizeof_collection $all_nets]
if {[file exists excludedDfNet]} {
    set e [open excludedDfNet r]
    while {[gets $e line] >= 0} {
        set exclude_net [lindex $line 0]
        set exclude_net_h($exclude_net) 1
    }
    close $e
}

set f [open checkPinAlignment_$th.rpt w]
set mi [open checkPinAlignment.miss.rpt w]
set n_misalign 0
set j 0
foreach_in_collection net $all_nets {
    set invalid_net 0
    set points [get_attribute [get_net $net] pin_bbox]
    set tile_pair ""
    set pin_pair ""
    foreach_in_collection pin [all_connected $net -leaf] {
        set pin_name [get_object_name $pin]
        set pin_pair "$pin_pair $pin_name"
        if {[regexp {/} $pin_name] == 0} {
            set invalid_net 1
            break
        }
        set  tile [get_attribute [get_cells -of_objects [get_pin $pin]] full_name]
        set tile_pair "$tile_pair $tile"

    }
    if {$invalid_net == 1} {
        continue
    }
    set layer0 [get_attribute [get_pins -quiet [lindex $pin_pair 0]] layer_name]
    set layer1 [get_attribute [get_pins -quiet [lindex $pin_pair 1]] layer_name]
    set net_name [get_attribute [get_net $net] full_name]
    if {[info exist exclude_net_h($net_name)] == 1 } {
        continue
    }
    if {[info exist layer_dir($layer0)] == 0 || [info exist layer_dir($layer1)] == 0 } {
        puts $mi "$net_name $pin_pair"
        continue
    }
    
    set x0 [lindex [lindex $points 0] 0]
    set y0 [lindex [lindex $points 0] 1]
    set x1 [lindex [lindex $points 1] 0]
    set y1 [lindex [lindex $points 1] 1]
        
    set dis [expr abs($x1 - $x0) + abs($y1 - $y0)]
    if {$j == 10000} {
        puts "$i of $n checked..."
        set j 0
    }
    incr i
    incr j
    if {$layer_dir($layer0) == $layer_dir($layer1) && $layer_dir($layer0) == 0} {
        if {[expr abs($y0 - $y1)] > 5 || $dis > $th} {
            puts $f "$net_name $dis $tile_pair $pin_pair"
            if {[info exist n_tile_pair($tile_pair)]} {
                set n_tile_pair($tile_pair) [expr $n_tile_pair($tile_pair) + 1]
            } else {
                set n_tile_pair($tile_pair) 1
            }
            dict incr n_tile_pair 1
            incr n_misalign
            continue
        }
    }
    if {$layer_dir($layer0) == $layer_dir($layer1) && $layer_dir($layer0) == 1} {
        if {[expr abs($x0 - $x1)] > 5 || $dis > $th} {
            if {[info exist n_tile_pair($tile_pair)]} {
                set n_tile_pair($tile_pair) [expr $n_tile_pair($tile_pair) + 1]
            }  else {
                set n_tile_pair($tile_pair) 1
            }

            puts $f "$net_name $dis $tile_pair $pin_pair"
            incr n_misalign
            continue
        }
    }
    if {$layer_dir($layer0) != $layer_dir($layer1)} {
        puts $f "$net_name $dis $tile_pair $pin_pair"
        if {[info exist n_tile_pair($tile_pair)]} {
            set n_tile_pair($tile_pair) [expr $n_tile_pair($tile_pair) + 1]
        }  else {
            set n_tile_pair($tile_pair) 1
        }

        incr n_misalign
        continue
    }
    if {$dis > 900} {
        if {[info exist n_tile_pair($tile_pair)]} {
            set n_tile_pair($tile_pair) [expr $n_tile_pair($tile_pair) + 1]
        }  else {
            set n_tile_pair($tile_pair) 1
        }

        incr n_misalign
        puts $f "$net_name $dis $tile_pair $pin_pair"
    }
}
close $f
set o [open checkPinAlignment.sort.rpt w]
puts $o "$n_misalign TOTAL"
foreach tile_pair [array names n_tile_pair] {
    puts $o "$n_tile_pair($tile_pair) $tile_pair"
}
close $o
close $mi
}

proc showMisalignment {tile0 tile1} {
set f [open checkPinAlignment_250.rpt r]
set nets_h ""
while {[gets $f line] >= 0} {
    set tile0_r [lindex $line 2]
    set tile1_r [lindex $line 3]
    set net [lindex $line 0]
    if {[string equal $tile0_r $tile0] && [string equal $tile1_r  $tile1]} {
        set nets_h "$nets_h $net"
    }
}
change_selection [get_nets $nets_h]
}


proc fixZeroSize {} {
set ports_fix ""
foreach_in_collection port [get_ports *] {
    set llx [lindex [lindex [get_attribute [get_ports $port] bbox] 0] 0]
    set urx [lindex [lindex [get_attribute [get_ports $port] bbox] 1] 0]
    set lly [lindex [lindex [get_attribute [get_ports $port] bbox] 0] 1]
    set ury [lindex [lindex [get_attribute [get_ports $port] bbox] 1] 1]
    if {$llx == $urx || $lly == $ury} {
        unplacePort $port
        puts "# fix [get_object_name $port]"
        set ports_fix [add_to_collection $ports_fix $port]
    }
}
if {[sizeof_collection $ports_fix] > 0} {
    place_pins -ports $ports_fix
}
} 

proc getTilesConn {tile0 tile1} {
set s_pins [get_pins $tile0/*] 
set i 0
foreach_in_collection pin $s_pins {
    set e_pin [pin2Pin4check $pin]
    if {$e_pin == 0} {
        continue
    }
    set tile1_pin [get_attribute [get_cells -of_objects [get_pins $e_pin]] full_name]
    if {[string equal "$tile1" $tile1_pin] == 0} {
        continue
    }
    incr i
    puts "[get_attribute $pin full_name] $e_pin"
}
puts "# total $i"
}

proc pin2Pin4check {s_pin} {
set net [get_nets -quiet -of_objects [get_pins $s_pin]]
if {[sizeof_collection $net] == 0} {
    puts "[get_attribute $s_pin full_name] NA"
    return 0
}
set e_pin ""
set n 0
set n [sizeof_collection [all_connected $net]]
set net_name [get_attribute $net full_name]
if {[regexp {Logic} $net_name]} {
    puts "[get_attribute $s_pin full_name] TIE"
    return 0
}
if {$n != 2} {
    puts "[get_attribute $s_pin full_name] LA"
    return 0
}
set return_pin 0
set e_pin [get_attribute [remove_from_collection [all_connected $net] [get_pins $s_pin]] full_name]
if {[sizeof_collection [get_pins $e_pin]] != 0} {
    set return_pin $e_pin
}
puts "[get_attribute $s_pin full_name] $e_pin"
return $return_pin
}

proc pin2Pin {pin} {
set net [get_nets -quiet -of_objects [get_pins $pin]]
if {[sizeof_collection $net] == 0} {
     puts "[get_object_name $pin] NA"
    return 0
}
set n [sizeof_collection [all_connected $net]]
if {$n == 0} {
    puts "[get_object_name $pin] NA"
    return 0
}
if {$n >10} {
    return 10
}
puts "[get_object_name [all_connected -leaf [get_nets -of_objects [get_pins $pin]]]]"
}

proc forceOnTrack {} {
set f [open placePins.tcl w]
source /home/simchen/vega20/pinAssign/proc_pinAssign_icc2.tcl
set lly_ini [get_attribute -quiet [get_tracks -filter "layer_name == M4"] start]
set ports [get_ports * -filter "layer_name == M4 || layer_name == M6 || layer_name == M8"]
foreach_in_collection port $ports {
    set bbox [get_attribute $port bbox]
    set layer [get_attribute $port layer_name]
    set lly [lindex [lindex $bbox 0] 1]
    set ury [lindex [lindex $bbox 1] 1]
    set llx [lindex [lindex $bbox 0] 0]
    set urx [lindex [lindex $bbox 1] 0]
    set y [expr ($lly + $ury)/2]
    set y_tracked [expr int(($y - $lly_ini)/0.08)*0.08 + $lly_ini]
    set lly [expr $y_tracked - 0.02]
    set ury [expr $y_tracked + 0.02]
    set name [get_attribute $port full_name]
    unplacePort $name
    #fastPlacePin $name {{$llx $lly} {$urx $ury}} $layer
    puts $f "fastPlacePin $name {{$llx $lly} {$urx $ury}} $layer"
}
close $f
source placePins.tcl
}

proc fixShortPort {} {
source /home/simchen/vega20/pinAssign/proc_pinAssign_icc2.tcl
set ports_fix ""
if {[regsub {\.nlib} [get_attribute [current_design] full_name] { } top]} {
    set top [lindex $top 0]
}
check_pin_placement -self -filename $top.short.rpt
puts "# Fix short for $top"

set f [open $top.short.rpt r]
while {[gets $f line] >= 0} {
    if {[regexp {^Pin\s+(\S+)\s+on\s+cell\s+\S+\s+is\s+short\s+with\s+pin\s+(\S+)\s+on\s+\S+} $line match port0 port1]} {
        if {[info exist fix_h($port0)]} {
            continue
        }
        set fix_h($port0) 1
        puts "# fix short $port0 with $port1"    
        set ports_fix [add_to_collection $ports_fix [get_ports $port0]]
        unplacePort $port0
    }
}
set_individual_pin_constraints -ports * -length 0.4
set_block_pin_constraints -allowed_layers {M4 M5 M6 M7 M8 M9 M10} -self

if {[sizeof_collection $ports_fix] > 0} {
    place_pins -ports $ports_fix
}
#check_pin_placement -self -filename $top.short.rpt
}

proc checkCAPins {} {
set all_nets ""
set all_nets [get_nets * -filter "number_of_pins == 2"]
set i  0
set n [sizeof_collection $all_nets]
set f [open checkCAPins.rpt w]
foreach_in_collection net $all_nets {
    set invalid_net 1
    set tile_pair ""
    set ca_flag 0
    set invalid_pin 0
    foreach_in_collection pin [all_connected $net] {
        set pin_name [get_object_name $pin]
        
        if {[regexp {/} $pin_name] == 0} {
            set invalid_net 1
            break
        }
        if {[regexp {io_t} $pin_name] == 1} {
            set invalid_net 1
            break
        }

        #set  tile [get_attribute [get_cells -of_objects [get_pin $pin]] full_name]
        if {[regexp {compute_array} $pin_name] == 1} {
            incr ca_flag
            set pin_ca $pin_name
            set tile_ca [get_attribute [get_cells -of_objects [get_pin $pin]] full_name]
            set invalid_net 0
            if {[get_attribute [get_pins $pin_name] physical_status] == "unplaced"} {
                set invalid_pin 1
                break
            } else {
                set bbox [get_attribute [get_pins $pin_name] bbox]
                set x_ca_pin [lindex [lindex $bbox 0] 0]
                set y_ca_pin [lindex [lindex $bbox 0] 1]
                #puts "$pin_name $x_ca_pin $y_ca_pin"
            }
        } else {
            set pin_nonca $pin_name
            set tile_nonca [get_attribute [get_cells -of_objects [get_pin $pin]] full_name]
            set bbox [get_attribute [get_pins $pin_name] bbox]
            set x0 [lindex [lindex $bbox 0] 0]
            set y0 [lindex [lindex $bbox 0] 1]
            set x1 [lindex [lindex $bbox 1] 0]
            set y1 [lindex [lindex $bbox 1] 1]
            set x_noncan_tile [expr ($x0 + $x1)/2]
            set y_noncan_tile [expr ($y0 + $y1)/2]
            #puts "$tile_nonca $x_noncan_tile $y_noncan_tile"
        }
    }
    if {$invalid_pin == 1} {
        continue
    }
    if {$invalid_net == 1} {
        continue
    }
    if {$ca_flag  != 1} {
        continue
    }
    set net_name [get_attribute [get_net $net] full_name]
    set dis [expr abs($x_ca_pin - $x_noncan_tile) + abs($y_ca_pin - $y_noncan_tile)]
    if {$dis > 20} {
        puts $f "$net_name $dis $tile_ca $tile_nonca"
    }
    puts "$i of $n..."
    incr i
    if {$i == 100} {
        #break
    }
}
close $f
}

proc writePortDef {def} {
set ports [get_ports * -filter "physical_status != unplaced"]
set_attribute [get_ports $ports] physical_status fixed
write_def -objects [get_ports $ports] -fixed_vias_only -compress gzip -units 2000 -version 5.7 $def
}

proc writeSelectedPortDef {def} {
write_def -objects [get_selection] -fixed_vias_only -compress gzip -units 2000 -version 5.7 $def
}


proc assignEAPins {} {
unplaceAllPort
if {[regsub {\.nlib} [get_attribute [current_design] full_name] { } top]} {
    set top [lindex $top 0]
}
set ports [get_ports *EA*TCC*]
set ports [add_to_collection $ports [get_ports *TCC*EA*]]
set i 0
set skip 0
set offset_ini 216.48
#set offset_ini 353.28

set layer_array(0) M4
set layer_array(1) M6
set layer_array(2) M8
set i_layer 0
set f [open $top.tcl w]
set_individual_pin_constraints -ports * -length 0.4
foreach_in_collection port $ports {
    if {[expr $skip * 0.64] > 80} {
        set offset_ini [expr $offset_ini + 23.04]
        set skip 0
    }
    if {[string equal $layer_array($i_layer) "M4"]} {
        incr i
        incr skip
    }
    set offset [expr $offset_ini + $i*0.64]
    puts $f "set_individual_pin_constraints -ports [get_object_name $port] -allowed_layers $layer_array($i_layer) -side 1 -offset $offset"
    incr i_layer
    if {$i_layer > 2} {
        set i_layer 0
    }
}
close $f
source $top.tcl
place_pins -ports $ports
write_def -fixed_vias_only -compress gzip -units 2000 -version 5.7 -objects [get_ports *] $top.pin.def.gz

}

proc spn {pin} {
set net [filter_collection [get_nets -of_objects [get_pin $pin]] "full_name !~ *Logic*"]
set net [filter_collection $net "number_of_pins == 2"]
change_selection $net
}

proc sn {net} {
change_selection [get_nets  $net]
}

proc sp {pin} {
change_selection [get_pins $pin]
}

proc slp {pin layer} {
change_selection [get_pins $pin -filter "layer_name == $layer"]
}

proc stp {ports} {
change_selection [get_ports $ports]
}

proc si {inst} {
change_selection [get_cells $inst]
}

proc pp {} {
set f [open pp w]
foreach_in_collection pin [get_selection] {
    if {[regexp {Logic} [get_attribute [get_nets -of_objects $pin] full_name]] == 1} {
        puts $f "[get_attribute $pin full_name] [get_attribute $pin direction] TIE"
        continue
    }
    if {[get_attribute [get_nets -of_objects $pin] number_of_pins] != 2} {
        puts $f "[get_attribute $pin full_name] [get_attribute $pin direction] HFN"
        continue
    }

    #puts $f [get_attribute $pin full_name]
    puts [get_attribute $pin full_name]
    puts $f "[get_attribute $pin full_name] [get_attribute $pin direction] 1"
}
set net [filter_collection [get_nets -of_objects [get_selection]] "full_name !~ *Logic*"]
set net [filter_collection $net "number_of_pins == 2"]
change_selection $net

close $f
}

proc replaceSelectedPorts {llx lly urx ury} {
set ports [get_selection]
foreach_in_collection port $ports {
    unplacePort [get_attribute $port full_name]
}
set_individual_pin_constraints -ports * -length 0.4  -pin_spacing 2
remove_pin_guides -all
eval "create_pin_guide -name temp_pin_guide -layers {M4 M5 M6 M7 M8 M9 M10 M11} -boundary {{$llx $lly} {$urx $ury}} $ports -pin_spacing 2"
place_pins -ports $ports
}

proc overridePreAssign {preAssign_def} {
if {[regsub {\.nlib} [get_attribute [current_design] full_name] { } top]} {
    set top [lindex $top 0]
}
write_def -objects $func_ports -fixed_vias_only -compress gzip -units 2000 -version 5.7 ${top}_preoverride.def.gz
unplaceAllPort
read_def $preAssign_def
set override_ports [get_ports * -filter "physical_status == placed || physical_status == fixed"]
unplaceAllPort
read_def ${top}_preoverride.def.gz
foreach_in_collection port $override_ports {
    unplacePort [$port]
}
read_def $preAssign_def
}

proc checkTileFeedMisalign {} {
set  layer_dir(M3) 1
set  layer_dir(M4) 0
set  layer_dir(M5) 1
set  layer_dir(M6) 0
set  layer_dir(M7) 1
set  layer_dir(M8) 0
set  layer_dir(M9) 1
set  layer_dir(M10) 0
set  layer_dir(M11) 1

set all_feeds [get_ports *FEED*]
set n_all_feeds [sizeof_collection $all_feeds]
foreach_in_collection port $all_feeds {
    #puts "[get_object_name $port]"
    incr j
    set port_name [get_attribute $port full_name]
    set segment [regsub -all "__" $port_name "  "]
    set n_segment [llength $segment]
    set bundle ""
    for {set i 0} {$i < $n_segment} {incr i} {
        if {$i > 3 && $i < [expr $n_segment - 1]} {
            set element [lindex $segment $i]
            set bundle "${bundle}_${element}"
        }
    }
    puts "$bundle [get_object_name $port]"
    if {[info exist port_pair($bundle)]} {
        set port_pair($bundle) "$port_pair($bundle) $port_name"
    } else {
        set port_pair($bundle) $port_name
    }

}
set i 0
foreach bundle [array names port_pair] {
    set port0 [lindex $port_pair($bundle) 0]
    
    set port1 [lindex $port_pair($bundle) 1]
    #puts "# $port0 $port1"
    set layer0 [get_attribute [get_ports $port0] layer_name]
    set layer1 [get_attribute [get_ports $port1] layer_name]
    if {[info exist layer_dir($layer0)] == 0 || [info exist layer_dir($layer1)] == 0 } {
        puts  " # illegal layer for $layer0 $layer1"
        continue
    }
    if {$layer_dir($layer0) == 1 && $layer_dir($layer1) == 1} {
        set bbox_port0 [get_attribute $port0 bbox]
        set llx0 [lindex [lindex $bbox_port0 0] 0]
        set bbox_port1 [get_attribute $port1 bbox]
        set llx1 [lindex [lindex $bbox_port1 0] 0]
        set bbox_port0 [get_attribute $port0 bbox]
        set lly0 [lindex [lindex $bbox_port0 0] 1]
        set bbox_port1 [get_attribute $port1 bbox]
        set lly1 [lindex [lindex $bbox_port1 0] 1]

        #puts "$llx0 $llx1"
        set dis [expr $llx1 - $llx0]
        puts "$port0 $port1 $dis"
        if {[expr abs($lly0 - $lly1)] < 2} {
            puts "# T-T or B-B $port0 $port1"
        }
    }
    if {$layer_dir($layer0) == 0 && $layer_dir($layer1) == 0} {
        set bbox_port0 [get_attribute $port0 bbox]
        set lly0 [lindex [lindex $bbox_port0 0] 1]
        set bbox_port1 [get_attribute $port1 bbox]
        set lly1 [lindex [lindex $bbox_port1 0] 1]
        set bbox_port0 [get_attribute $port0 bbox]
        set llx0 [lindex [lindex $bbox_port0 0] 0]
        set bbox_port1 [get_attribute $port1 bbox]
        set llx1 [lindex [lindex $bbox_port1 0] 0]

        #puts "$lly0 $lly1"
        set dis [expr $lly1 - $lly0]
        puts "$port0 $port1 $dis"
        if {[expr abs($llx0 - $llx1)] < 2} {
            puts "# L-L or R-R $port0 $port1"
        }
    }
}
puts "# $i misalign"
}

proc dumpPinBlockage {} {
set i 0
foreach_in_collection bkg [get_pin_blockages -design [current_design ]] {
    set bbox [get_attribute $bkg bbox]
    set name tune_bkg_$i
    puts "create_pin_blockage -boundary {$bbox} -name $name"
    incr i
}
}
    
proc createVDD {} {
if {[sizeof_collection [get_nets VDD]] > 0} {
    fastPlacePin VDD {{0 0} {0.062 0.4}} M11
}
}

proc removeNetShape {} {
foreach_in_collection net [get_nets *] {
    if {[sizeof_collection [get_shapes -quiet -of_objects $net]] == 0} {
        continue
    }
     remove_shapes [get_shapes -of_objects $net]
}
remove_vias *
}


proc extractSSB {} {
if {[regsub {\.nlib} [get_attribute [current_design] full_name] { } top]} {
    set top [lindex $top 0]
}
set ssb_list "/proj/vega20-pdfcfp3-nobackup/NLD_run1/main/pd/tiles/CHIP_nldp0_run1_0522_TileBuilder_May22_1120_3534_nldp0_run1_0522/kai/ssb_pin_list"
set f [open $ssb_list r]
set ssb_ports ""
while {[gets $f line] >= 0} {
    if {[regexp {(\S+)\/(\S+)} $line match inst port] == 1 } {
        if  {[sizeof_collection [get_ports -quiet $port]] > 0} {
            set ssb_ports [add_to_collection $ssb_ports [get_ports $port]]
        }
    }
}
if {[sizeof_collection [get_ports -quiet FCFP_SSB*]] > 0} {
    set ssb_ports [add_to_collection $ssb_ports [get_ports FCFP_SSB*]]
    set ssb_ports [remove_from_collection $ssb_ports [get_ports FCFP_SSB_SHIELD*]] 
}
if {[sizeof_collection $ssb_ports] > 0} {
    set non_ssb [remove_from_collection [get_ports *] $ssb_ports]
    unplacePort $non_ssb
} else {
    set non_ssb [get_ports *]
    unplacePort $non_ssb
}
if {[sizeof_collection $ssb_ports] > 0} {
    puts "[sizeof_collection $ssb_ports] are written."
    write_def -objects [get_ports $ssb_ports] -compress gzip -units 2000 -version 5.7 genpreCommitPartition/${top}.ssb.def.gz
}
}

proc cleanSSB {} {
set ssb_list "/proj/vega20-pdfcfp3-nobackup/NLD_run1/main/pd/tiles/CHIP_nldp0_run1_0522_TileBuilder_May22_1120_3534_nldp0_run1_0522/kai/ssb_pin_list"
set f [open $ssb_list r]
set ssb_ports ""
while {[gets $f line] >= 0} {
    if {[regexp {(\S+)\/(\S+)} $line match inst port] == 1 } {
        if  {[sizeof_collection [get_ports -quiet $port]] > 0} {
            puts "# clean SSB $port"
            set ssb_ports [add_to_collection $ssb_ports [get_ports $port]]
        }
    }
}
if {[sizeof_collection [get_ports -quiet FCFP_SSB*]] > 0} {
    set ssb_ports [add_to_collection $ssb_ports [get_ports FCFP_SSB*]]
    set ssb_ports [remove_from_collection $ssb_ports [get_ports FCFP_SSB_SHIELD*]]
}
if {[sizeof_collection $ssb_ports] > 0} {
    unplacePort $ssb_ports
} 
}

proc alignCAFeed {} {
if {[regsub {\.nlib} [get_attribute [current_design] full_name] { } top]} {
    set top [lindex $top 0]
}
source /home/simchen/vega20/pinAssign/proc_pinAssign_icc2.tcl
set all_feeds [get_ports *FEED*]
set n_all_feeds [sizeof_collection $all_feeds]
set j 0

foreach_in_collection port $all_feeds {
    incr j
    set port_name [get_attribute $port full_name]
    set segment [regsub -all "__" $port_name "  "]
    set n_segment [llength $segment]
    set bundle ""
    for {set i 0} {$i < $n_segment} {incr i} {
        if {$i > 3 && $i < [expr $n_segment - 1]} {
            set element [lindex $segment $i]
            set bundle "${bundle}_${element}"
        }
    }
    if {[info exist port_pair($bundle)]} {
        set port_pair($bundle) "$port_pair($bundle) $port_name"
    } else {
        set port_pair($bundle) $port_name
    }

}
set f [open setPinCons.tcl w]
set b [open feed_bundle.list w]
foreach bundle [array names port_pair] {
    puts $b "$bundle | $port_pair($bundle)"
    puts "$bundle | $port_pair($bundle)"
    set port0 [lindex $port_pair($bundle) 0]
    set port1 [lindex $port_pair($bundle) 1]
    set llx0 [lindex [lindex [get_attribute [get_ports $port0] bbox] 0 ] 0]
    set lly0 [lindex [lindex [get_attribute [get_ports $port0] bbox] 0 ] 1]
    set urx0 [lindex [lindex [get_attribute [get_ports $port0] bbox] 1 ] 0]
    set ury0 [lindex [lindex [get_attribute [get_ports $port0] bbox] 1 ] 1]
    set layer0 [get_attribute [get_ports $port0] layer_name]
    set llx1 [lindex [lindex [get_attribute [get_ports $port1] bbox] 0 ] 0]
    set lly1 [lindex [lindex [get_attribute [get_ports $port1] bbox] 0 ] 1]
    set urx1 [lindex [lindex [get_attribute [get_ports $port1] bbox] 0 ] 0]
    set ury1 [lindex [lindex [get_attribute [get_ports $port1] bbox] 0 ] 1]

    set layer1 [get_attribute [get_ports $port1] layer_name]
    if {$lly0 > 0} {
        set pair "$port1 $port0"
        puts $b "# $pair"
        set x [expr ($llx1 + $urx1)/2]
        set port_name [get_attribute $port0 full_name]
        puts $f "set_individual_pin_constraints -port $port_name -location {$x $ury0} -allowed_layers $layer1"
        puts $f "unplacePort $port0"
        puts $f "set_attribute \[get_ports $port1\] physical_status fixed"
    } else {
        set pair "$port0 $port1"
        puts $b "# $pair"
        set x [expr ($llx0 + $urx0)/2]
        set port_name [get_attribute $port1 full_name]
        puts $f "set_individual_pin_constraints -port $port_name -location {$x $ury1} -allowed_layers $layer0"
        puts $f "unplacePort $port1"
        puts $f "set_attribute \[get_ports $port0\] physical_status fixed"
    }  
}
close $b
close $f
source setPinCons.tcl
set func_ports [remove_from_collection [get_ports *] [get_ports *FEED*]]
unplacePort $func_ports
place_pins -ports [get_ports *FEED*]
write_def -objects [get_ports *FEED*] -fixed_vias_only -compress gzip -units 2000 -version 5.7 ${top}.alignedFeed.def.gz
}

proc highlightNetList {net_list} {
set f [open $net_list r]
set nets ""
while {[gets $f line] >= 0} {
    set nets [add_to_collection $nets [get_nets [lindex $line 0]]]
}
close $f
change_selection $nets 
}

proc highlightPinList {pin_list} {
set f [open $pin_list r]
set pins ""
while {[gets $f line] >= 0} {
    set pins [add_to_collection $pins [get_pins [lindex $line 0]]]
    set port [get_pins [lindex $line 0]]
    set layer [get_attribute $port layer_name]
    set llx [lindex [lindex [get_attribute [get_pins $port] bbox] 0 ] 0]
    set lly [lindex [lindex [get_attribute [get_pins $port] bbox] 0 ] 1]
    puts "[get_object_name $port] $llx $lly $layer"

}
close $f
change_selection $pins
}

proc highlightPortList {port_list} {
set f [open $port_list r]
set ports ""
while {[gets $f line] >= 0} {
    set port [get_ports [lindex $line 0]]
    set layer [get_attribute $port layer_name]
    set llx [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 0]
    set lly [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 1]
    puts "[get_object_name $port] $llx $lly $layer"
    set ports [add_to_collection $ports [get_ports [lindex $line 0]]]
}

close $f
change_selection $ports
}


proc highlightInstList {port_list} {
set f [open $port_list r]
set ports ""
while {[gets $f line] >= 0} {
    set ports [add_to_collection $ports [get_cells [lindex $line 0]]]
}

close $f
change_selection $ports
}


proc unplaceSSB {} {
set ssb_list "/proj/vega20-pdfcfp3-nobackup/NLCp5/run0/main/pd/tiles/CHIP_NLCp5_run0_0421_TileBuilder_Apr21_0020_1062_NLCp5_run0_0421/kai/ssb_pin"
set f [open $ssb_list r]
while {[gets $f line] >= 0} {
    if {[regexp {(\S+)\/(\S+)} $line match tile ref_pin] == 1} {
        puts "# Unplace SSB port $ref_pin"
        if {[sizeof_collection [get_ports -quiet $ref_pin]]>0} {
            unplacePort $ref_pin
        }
    }
}
close $f
}
   
proc net2Pin {net} {
set pins [all_connected $net]
set pin_list ""
foreach_in_collection pin $pins {
    set name [get_attribute $pin full_name]
    set pin_list "$pin_list $name"
}
puts "$net $pin_list"
}

proc checkTopTie {pins} {
foreach_in_collection pin [get_pins $pins] {
    puts "[get_object_name $pin] [get_object_name [all_connected $pin]]"
}
}

proc deleteVSSBkg {} {
set VSS_shapes [get_shapes -of_objects [get_port VSS] -filter "layer_name == M4 || layer_name == M5 || layer_name == M6 || layer_name == M7 || layer_name == M8 || layer_name == M9"]
remove_shapes $VSS_shapes
}


proc unplaceSSB {} {
if {[regsub {\.nlib} [get_attribute [current_design] full_name] { } top]} {
    set top [lindex $top 0]
}
set ssb_list "/proj/vega20-pdfcfp5-nobackup/NLD/main/pd/tiles/CHIP_nldp0_run0_0517_TileBuilder_May16_1957_32488_nldp0_run0_0517/kai/ssb_pin_list"
set f [open $ssb_list r]
set ssb_ports ""
while {[gets $f line] >= 0} {
    if {[regexp {(\S+)\/(\S+)} $line match inst port] == 1 } {
        if  {[sizeof_collection [get_ports -quiet $port]] > 0} {
            unplacePort $port 
            puts "# unplace $port"
        }
    }
}
}


proc removeNonSSBPG {} {
remove_shapes [filter_collection [get_shapes -of_objects [get_nets VSS]] "layer_name == M11 || layer_name == M2 || layer_name == M1 || layer_name == M0"]
remove_shapes [filter_collection [get_shapes -of_objects [get_nets VDDCR_SOC]] "layer_name == M11 || layer_name == M2 || layer_name == M1 || layer_name == M0"]
remove_shapes [filter_collection [get_shapes -of_objects [get_nets VDDCR_GFX]] "layer_name == M11 || layer_name == M2 || layer_name == M1 || layer_name == M0"]
remove_vias  [get_vias -of_objects [get_nets VSS]] 
remove_vias  [get_vias -of_objects [get_nets VDDCR_SOC]]
remove_vias  [get_vias -of_objects [get_nets VDDCR_GFX]]
}

proc assignNPIO {} {
set macros [get_cell -hierarchical * -filter "is_hard_macro == true || is_io == true"]
foreach_in_collection macro $macros {
    puts "[get_object_name $macro]"
    set x [lindex [lindex [get_attribute $macro bbox ] 0] 0]
    set y [lindex [lindex [get_attribute $macro bbox ] 0] 1]
    puts "[get_object_name $macro] $x $y"
}

foreach_in_collection port [get_ports *] {
    set module [get_pins -of_objects [all_connected $port]]
    puts "port [get_object_name $port] "
    puts "module  [get_object_name  $module]"

}
}

proc showDftClk {} {
set pins [get_pins {*/BC1500_Wrck */CORE_DFTG_ACCLK1 */Cpl_FCLK */Dfx_SCAN_SHIFT_CLK */SCF_PHYGSKT0_Stac_Wrck */Stac_Wrck */vdci_gc2soc_left_t_xover_vddc_DFX_TARG_Shift_Clk */vdci_gc2soc_left_t_xover_vddc_Stac_Wrck}]
set pins [get_pins $pins -filter "physical_status != unplaced"]
change_selection $pins
}

proc genNetConn {} {
set f [open net_connectivity.icc.CHIP.rpt w]
set all_nets [get_nets * -filter "number_of_pins == 2"]
set i  0
set n [sizeof_collection $all_nets]
set j 0
foreach_in_collection net $all_nets {
    set tile_pair ""
    set pin_pair ""
    puts $f "net:[get_object_name $net] type:signal #instTerms:2 #terms:0"
    set k 0
    if {$j == 10000} {
        puts "$i of $n checked..."
        set j 0
    }
    incr i
    incr j
    foreach_in_collection pin [all_connected -leaf $net] {
        if {$k == 0} {
            puts $f "  driver:[get_object_name $pin]"
            set k 1
        } else {
            puts $f "  load:[get_object_name $pin]" 
        }
    }
}
close $f
}

proc placeListPins {pin_list} {
set f [open $pin_list r]
set o [open setPinCons.tcl w]
set ports ""
set_individual_pin_constraints -ports * -length 0.4
while {[gets $f line] >= 0} {
    set port [lindex $line 0]
    set x [lindex $line 1]
    set y [lindex $line 2]
    set layer [lindex $line 3]
    if {[sizeof_collection [get_port -quiet $port]] == 0} {
        puts "$port does not exist"
        continue
    }
    unplacePort $port
    puts $o "set_individual_pin_constraints -ports $port -location {$x $y} -allowed_layers $layer"
    set ports [add_to_collection $ports [get_ports $port]] 
}
close $o
close $f
source  setPinCons.tcl
place_pins -ports $ports
}

proc checkFuncMisalign {} {
foreach_in_collection port0 [get_selection] {
    set port0_name [get_attribute [get_ports $port0] full_name]
    if {[regsub {Targ} $port0_name {Init} port1]} {
        #puts "$port0 $port1"
        if {[sizeof_collection [get_port -quiet $port1]] == 0} {
            puts "$port1 does not exist"
            continue
        }
        set llx0 [lindex [lindex [get_attribute [get_ports $port0] bbox] 0 ] 0]
        set lly0 [lindex [lindex [get_attribute [get_ports $port0] bbox] 0 ] 1]
        set llx1 [lindex [lindex [get_attribute [get_ports $port1] bbox] 0 ] 0]
        set lly1 [lindex [lindex [get_attribute [get_ports $port1] bbox] 0 ] 1]
        set delta [expr abs($llx0 - $llx1)]
        puts "$port0_name $port1 $delta"
    }

}
}

proc placePinsBySide { pins side} {
unplacePort $pins
set_individual_pin_constraints -ports * -length 0.4
set_block_pin_constraints -allowed_layers {M4 M5 M6 M7 M8 M9 M10} -self
set_individual_pin_constraints -ports $pins -sides $side
place_pins -ports $pins
}

proc checkInternalFeedMisalign {feeds_list} {
set f [open $feeds_list r]
set o [open ${feeds_list}.dist w]
set flag 0
set is_h(M3) 0
set is_h(M4) 1
set is_h(M5) 0
set is_h(M6) 1
set is_h(M7) 0
set is_h(M8) 1
set is_h(M9) 0
set is_h(M10) 1
set is_h(M11) 0

while {[gets $f line] >= 0} {
    if {[regexp {[driv|load]:(\S+)\s*net:} $line match htermName]} {
        if {$flag == 0} {
            set pin0 $htermName
            set flag 1
            set inst [get_cells -of_objects [get_pins $pin0]]
            set llx [lindex [lindex [get_attribute [get_cells $inst] bbox] 0 ] 0]
            set lly [lindex [lindex [get_attribute [get_cells $inst] bbox] 0 ] 1]
            set urx [lindex [lindex [get_attribute [get_cells $inst] bbox] 1 ] 0]
            set ury [lindex [lindex [get_attribute [get_cells $inst] bbox] 1 ] 1]
            set width [expr $urx - $llx]
            set height [expr $ury - $lly]
            set layer0 [get_attribute [get_pins $pin0] layer_name]
        } else {
            set pin1 $htermName
            set flag 0
            set llx0 [lindex [lindex [get_attribute [get_pins $pin0] bbox] 0 ] 0]
            set lly0 [lindex [lindex [get_attribute [get_pins $pin0] bbox] 0 ] 1]
            set llx1 [lindex [lindex [get_attribute [get_pins $pin1] bbox] 0 ] 0]
            set lly1 [lindex [lindex [get_attribute [get_pins $pin1] bbox] 0 ] 1]
            set layer1 [get_attribute [get_pins $pin1] layer_name]
            if {$is_h($layer0) == 0 && $is_h($layer1) == 0} {
                set dis [expr abs($llx1 - $llx0) + abs($lly1 - $lly0) - $height]
                puts $o "$pin0 $pin1 $dis"
            }
            if {$is_h($layer0) == 1 && $is_h($layer1) == 1} {
                set dis [expr abs($llx1 - $llx0) + abs($lly1 - $lly0) - $width]
                puts $o "$pin0 $pin1 $dis"
            }

        }
    }
    
}
close $o
close $f
}

proc movePins {ports offset_x offset_y} {
set is_h(M3) 0
set is_h(M4) 1
set is_h(M5) 0
set is_h(M6) 1
set is_h(M7) 0
set is_h(M8) 1
set is_h(M9) 0
set is_h(M10) 1
set is_h(M11) 0
set o [open movePins.tcl w]
foreach_in_collection port [get_ports $ports] {
    if {[sizeof_collection [get_shapes -of_objects [get_ports $port]]] > 1} {  
        continue
    }
    set layer [get_attribute [get_ports $port] layer_name]
    set llx [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 0]
    set lly [lindex [lindex [get_attribute [get_ports $port] bbox] 0 ] 1]
    set urx [lindex [lindex [get_attribute [get_ports $port] bbox] 1 ] 0]
    set ury [lindex [lindex [get_attribute [get_ports $port] bbox] 1 ] 1]
    set llx [expr $llx + $offset_x] 
    set urx [expr $urx + $offset_x]
    set lly [expr $lly + $offset_y]
    set ury [expr $ury + $offset_y]
    set port [get_object_name $port]
    if {$llx == $urx || $lly == $ury} {
         continue
    }
    if {[regexp {\S} $layer] == 0} {
        puts "# WARNING $port has no layer"
        continue
    }
    puts $o "fastRePlacePin $port {{$llx $lly} {$urx $ury}} $layer"
}
close $o
}

proc savePin {} {
movePins [get_selection] 0 0
}

proc updateSSBXml {src_file} {
set f [open $src_file r]
set o [open ${src_file}.hack w]
while {[gets $f line] >= 0} {
    if {[regexp {FCFP_SSB} $line]} {
        puts $o "$line"
        continue
    }
    if {[regexp {\<datapin\s+driver=\"(.*)\"\s+load=\"(.*)\"\s+\/\>} $line match ports loads]} {
        regsub -all {\,} $ports { } ports_new
        regsub -all {\,} $loads { } loads_new
        for { set i 0 } { $i < [llength $ports_new] } {incr i} { 
            set ports_h($i) [lindex $ports_new $i]
            if {[sizeof_collection [get_ports -quiet $ports_h($i)]] > 0} {
                puts "$i $ports_h($i)"
                foreach_in_collection pin [all_connected [all_connected [get_ports $ports_h($i)]] -leaf] {
                    if {[sizeof_collection [get_pins -quiet $pin]] > 0} {
                        set loads_h($i) [get_object_name $pin]
                        puts "$i $ports_h($i) $loads_h($i)"
                        break
                    }
                }
                if {$i ==0} {
                    set loads_updated $loads_h($i)
                    set ports_updated $ports_h($i)
                    #puts "$ports_h($i) $loads_updated"
                
                } else {
                    set loads_updated "$loads_updated,$loads_h($i)"
                    set ports_updated "$ports_updated,$ports_h($i)"
                    #puts "$ports_h($i) $loads_updated"
                }
             } else {
                set loads_h($i) [lindex $loads_new $i]
                puts "$i $loads_h($i)"
                foreach_in_collection pin [all_connected [all_connected [get_ports $loads_h($i)]] -leaf] {
                    if {[sizeof_collection [get_pins -quiet $pin]] > 0} {
                        set ports_h($i) [get_object_name $pin]
                        break
                    }
                }
                if {$i ==0} {
                    set ports_updated $ports_h($i)
                    set loads_updated $loads_h($i)
                } else {
                    set ports_updated "$ports_updated,$ports_h($i)"
                    set loads_updated "$loads_updated,$loads_h($i)"
                }
            }
            

        }
        puts $o "      \<datapin driver=\"$ports_updated\" load=\"$loads_updated\" \/\>"
        puts "# end #"
        continue
    }
    if {[regexp {\<clockpin\s+driver=\"(.*)\"\s+load=\"(.*)\"\s+\/\>} $line match ports loads]} {
        regsub -all {\,} $ports { } ports_new
        regsub -all {\,} $loads { } loads_new
        for { set i 0 } { $i < [llength $ports_new] } {incr i} {
            set ports_h($i) [lindex $ports_new $i]
            if {[sizeof_collection [get_ports -quiet $ports_h($i)]] > 0} {
                foreach_in_collection pin [all_connected [all_connected [get_ports $ports_h($i)]] -leaf] {
                    if {[sizeof_collection [get_pins -quiet $pin]] > 0} {
                        set loads_h($i) [get_object_name $pin]
                        puts "$ports_h($i) $loads_h($i)" 
                        break
                    }   
                }   
                if {$i ==0} {
                    set loads_updated $loads_h($i)
                    set ports_updated $ports_h($i)
                    #puts "$ports_h($i) $loads_updated"
                    
                } else {
                    set loads_updated "$loads_updated,$loads_h($i)"
                    set ports_updated "$ports_updated,$ports_h($i)"
                    #puts "$ports_h($i) $loads_updated"
                }   
             } else {
                set loads_h($i) [lindex $loads_new $i]
                foreach_in_collection pin [all_connected [all_connected [get_ports $loads_h($i)]] -leaf] {
                    if {[sizeof_collection [get_pins -quiet $pin]] > 0} {
                        set ports_h($i) [get_object_name $pin]
                        break
                    }
                }
                if {$i ==0} {
                    set ports_updated $ports_h($i)
                    set loads_updated $loads_h($i)
                } else {
                    set ports_updated "$ports_updated,$ports_h($i)"
                    set loads_updated "$loads_updated,$loads_h($i)"
                }
            }
        }
        puts $o "      \<clockpin driver=\"$ports_updated\" load=\"$loads_updated\" \/\>"
        puts "# end #"
        continue
    }
    puts $o "$line"
}
close $f
close $o
exec /bin/cp -rf ${src_file}.hack $src_file 
}

proc removeUnusedUnplacedPorts {} {
set ports [get_ports -quiet * -filter "physical_status == unplaced && (port_type == power || port_type == ground)"]
if {[sizeof_collection $ports] > 0} {
    remove_ports $ports
}
}

proc convertShield {} {
foreach_in_collection net [get_nets -quiet FCFP_SSB_SHIELD*] {
    set net_name [get_object_name $net]
    puts "$net_name"
    if {[regexp {FCFP_SSB_SHIELD_POWER_NET_(\S+)} $net_name match power]} {
        puts "# convertShield $net_name to $power"
        if {[sizeof_collection [get_shapes -quiet -of_objects $net]] == 0} {
            continue
        }
       foreach_in_collection shape [get_shapes -of_objects $net] {
            set_attribute  [get_shapes $shape] owner [get_nets $power]
        }
    }
    if {[regexp {FCFP_SSB_SHIELD_GROUND_NET_(\S+)} $net_name match ground]} {
        puts "# converShiled $net_name to $ground"
        if {[sizeof_collection [get_shapes -quiet -of_objects $net]] == 0} {
            continue
        }
        foreach_in_collection shape [get_shapes -of_objects $net] {
            set_attribute  [get_shapes $shape] owner [get_nets $ground]
        }
    }
}
}

proc checkPinPlacement {} {
if {[regsub {\.nlib} [get_attribute [current_design] full_name] { } top]} {
    set top [lindex $top 0]
}

check_pin_placement -self \
    -pre_route true \
    -alignment false \
    -report_net_details false \
    -layers true \
    -sides true \
    -pin_spacing true \
    -pin_size true \
    -pin_mask_constraint true \
    -shorts true \
    -single_pin all \
    -wire_track true \
    -wide_track true \
    -offset true \
    -off_edge true \
    -corner_keep_out true \
    -missing true \
    -filename $top.check_pin_summary.rpt
}

proc changeTileView {} {
foreach_in_collection tile [get_cells * -filter "hierarchy_type == block"] {
    set tile_name [get_object_name $tile]
    if {[regexp {vdci_gc2soc_right_t} $tile_name]} {
        continue
    }
    #puts "# change_view for $tile_name"
    echo "change_view \[get_cells $tile_name\] -view frame"
}
}

proc checkTileTopConn {tile} {
set sum 0
foreach_in_collection pin [get_pins $tile/*] {
    set pin_conn [sizeof_collection [all_connected -leaf $pin ]]
    puts "[get_object_name $pin] $pin_conn"
    set sum [expr $sum + $pin_conn]
}
puts $sum
}

proc dumpNetPorts {} {
set dir 0
set o [open dumpNetPorts.tcl w]
foreach_in_collection shape [get_selection] {
    set name [get_object_name [get_attribute $shape owner]]
    set layer [get_attribute $shape layer_name]
    set llx [lindex [lindex [get_attribute [get_shapes $shape] bbox] 0 ] 0]
    set lly [lindex [lindex [get_attribute [get_shapes $shape] bbox] 0 ] 1]
    set urx [lindex [lindex [get_attribute [get_shapes $shape] bbox] 1 ] 0]
    set ury [lindex [lindex [get_attribute [get_shapes $shape] bbox] 1 ] 1]
    set x [expr ($llx + $urx)/2]
    set y [expr ($lly + $ury)/2]
    set y -590.4850
    puts $o "$name $x $y $layer"
}
close $o
}

proc alignAbutPins {pins} {
set is_h(M3) 0
set is_h(M4) 1
set is_h(M5) 0
set is_h(M6) 1
set is_h(M7) 0
set is_h(M8) 1
set is_h(M9) 0
set is_h(M10) 1
set is_h(M11) 0
set x_rotate(R0)  1
set x_rotate(MX)  1
set x_rotate(MY)  -1
set x_rotate(R180)  -1

set y_rotate(R0)  1
set y_rotate(MX)  -1
set y_rotate(MY)  1
set y_rotate(R180)  -1
set o [open abutPin.tcl w]
foreach_in_collection pin [get_pins $pins] {
    set abut_pin [pin2Pin4check $pin]
    if {[sizeof_collection [get_pins $abut_pin]] ==0} {
        continue
    }
    puts "## $abut_pin"
    set layer [get_attribute [get_pins $pin] layer_name]
    set llx_pin [lindex [lindex [get_attribute [get_pins $pin] bbox] 0 ] 0]
    set lly_pin [lindex [lindex [get_attribute [get_pins $pin] bbox] 0 ] 1]
    set urx_pin [lindex [lindex [get_attribute [get_pins $pin] bbox] 1 ] 0]
    set ury_pin [lindex [lindex [get_attribute [get_pins $pin] bbox] 1 ] 1]
    set x_pin [expr ($llx_pin + $urx_pin)/2]
    set y_pin [expr ($lly_pin + $ury_pin)/2]
    set abut_tile [get_cells -of_objects [get_pins $abut_pin]]
    set llx_tile [lindex [lindex [get_attribute [get_cells $abut_tile] bbox] 0 ] 0]
    set lly_tile [lindex [lindex [get_attribute [get_cells $abut_tile] bbox] 0 ] 1]
    set urx_tile [lindex [lindex [get_attribute [get_cells $abut_tile] bbox] 1 ] 0]
    set ury_tile [lindex [lindex [get_attribute [get_cells $abut_tile] bbox] 1 ] 1]
    set x_tile_center [expr ($llx_tile + $urx_tile)/2]
    set y_tile_center [expr ($lly_tile + $ury_tile)/2]
    set ori [get_attribute $abut_tile orientation]
    
    if {$is_h($layer) == 0} {
        set x_abut_global $x_pin
        set y_abut_global $lly_tile
        set x_abut [expr ($x_abut_global - $x_tile_center)*$x_rotate($ori)]
        set y_abut [expr ($y_abut_global - $y_tile_center)*$y_rotate($ori)]
        if {[regexp {(\S+)\/(\S+)} $abut_pin match tile ref_pin]} {
            puts $o "$ref_pin $x_abut $y_abut $layer"
        }
    } else {
        set x_abut_global $llx_tile
        set y_abut_global $y_pin
        set x_abut [expr ($x_abut_global - $x_tile_center)*$x_rotate($ori)]
        set y_abut [expr ($y_abut_global - $y_tile_center)*$y_rotate($ori)]
        if {[regexp {(\S+)\/(\S+)} $abut_pin match tile ref_pin]} {
            puts $o "$ref_pin $x_abut $y_abut $layer"
        }
    }
}
close $o        
}

proc writeLef {lef} {
if {[regsub {\.nlib} [get_attribute [current_design] full_name] { } top]} {
    set top [lindex $top 0]
    remove_cells *
    write_lef -design $top -include {cell} $lef
}
}

proc showAllSameRefPin {pin} {
set inst [get_cells -of_objects $pin]
set pin_ref [get_attribute $pin lib_pin_name]
set ref [get_attribute $inst ref_name]
set inst_ref [get_cells * -filter "ref_name == $ref"]
set pin_ref_list ""
foreach_in_collection inst $inst_ref {
    set inst_name [get_object_name $inst]
    puts "$inst_name/$pin_ref"
    set pin_ref_list [add_to_collection $pin_ref_list [get_pins $inst_name/$pin_ref]]
}
change_selection [get_pins $pin_ref_list]
}


proc tieListPin {pin_list} {
set f [open $pin_list r]
set o [open tieListPin.tcl w]
while {[gets $f line] >= 0} {
    set full_pin [lindex $line 0]   
    if {[regexp {(\S+)\/(\S+)} $full_pin match tile ref_pin]} {
        set tie_net "${tile}_${ref_pin}_simchen"
        if {[sizeof_collection [get_nets -of_objects [get_pins $full_pin]]] > 0} {
            set tie_net [get_object_name [get_nets -of_objects [get_pins $full_pin]]]
            puts "$full_pin $tie_net"
        } else {
            puts $o "create_net $tie_net"
            puts $o "connect_net -net \[get_nets $tie_net\] \[get_pins $full_pin\]"
        }
        set tie_cell ${tie_net}_inst
        set tie_cell_loc [lindex [get_attribute [get_pins $full_pin] bbox] 0]
        puts $o "# Tie $full_pin"
        puts $o "create_cell $tie_cell \[get_lib_cells */HDBSVT08_TIE0_1\]"
        puts $o "set_cell_location $tie_cell -coordinates {$tie_cell_loc}"
        puts $o "connect_net -net \[get_nets $tie_net\] \[get_pins $tie_cell/X\]"
        puts $o ""
    }

}
close $f
close $o
}

proc changeInstancesName {} {
#set all_inst [get_cells *_simchen]
set all_inst [get_cell SYNOPSYS_UNCONNECTED_*]
foreach_in_collection inst $all_inst {
    set name [get_attribute $inst full_name]
    set new_name "${name}_inst"
    puts "change_names -instance [get_cells $inst] -new_name $new_name"
    change_names -instance [get_cells $inst] -new_name $new_name
}
}

proc reconnectTieWithFloating  {} {
set dist_th 20
set floating_th 5
set tie_list "reconnect.tie.list"
set f [open $tie_list r]
while {[gets $f line] >= 0} {
    set pin [lindex $line 0]
    set tie_h($pin) 0
}
close $f
set floating_list "reconnect.floating.list"
set f [open $floating_list r]
while {[gets $f line] >= 0} {
    set pin [lindex $line 0]
    set floating_h($pin) 0
}
close $f
foreach tie_pin [array names tie_h] {
    set bbox [get_attribute $tie_pin bbox]
    set tie_llx [lindex [lindex $bbox 0] 0]
    set tie_lly [lindex [lindex $bbox 0] 1]
    foreach floating_pin [array names floating_h] {
        set bbox [get_attribute $floating_pin bbox]
        set floating_llx [lindex [lindex $bbox 0] 0]
        set floating_lly [lindex [lindex $bbox 0] 1]
        set dist [expr abs($tie_llx - $floating_llx) + abs($tie_lly - $floating_lly)] 
        #puts "$tie_pin $floating_pin $dist"
        if {$dist < $dist_th && $floating_h($floating_pin) < $floating_th} {
            set tie_h($tie_pin) $floating_pin
            incr floating_h($floating_pin)
            break
        }
    }
}
foreach tie_pin [array names tie_h] {
    puts "TIE $tie_pin $tie_h($tie_pin)"
}
foreach floating_pin [array names floating_h] {
    puts "FLOATING $floating_pin $floating_h($floating_pin)"
}
}

proc checkFloatingSource {check_list} {
set feed_list "df_tcdx_ch1_t.feeds.pair"
set f [open $feed_list r]
while {[gets $f line] >= 0} {
    set pin0 [lindex $line 0]
    if {[regexp {(\S+)\/(\S+)} $pin0 match tile ref_pin]} {
        set pin0 $ref_pin
    }
    set pin1 [lindex $line 1]
    if {[regexp {(\S+)\/(\S+)} $pin1 match tile ref_pin]} {
        set pin1 $ref_pin
    }
    set pin_pair($pin0) $pin1
    set pin_pair($pin1) $pin0
    #puts "$pin0 $pin1"
}
close $f
set f [open $check_list r]
while {[gets $f line] >= 0} {
    set pin0 [lindex $line 0]
    if {[regexp {(\S+)\/(\S+)} $pin0 match tile ref_pin]} {
        if {[info exist pin_pair($ref_pin)]} {
            set pin1 "$tile/$pin_pair($ref_pin)"
            puts "$pin0 $pin1"
            pin2Pin4check $pin1
        }
    }

}
close $f
}


proc genEco {} {
set pair_list "/proj/vega20-pdfcfp3-nobackup/NLD_run1/main/pd/tiles/CHIP_nldp0_run1_0522_TileBuilder_May22_1120_3534_nldp0_run1_0522/reconnect.tie.pair.list" 
set o [open genEco.tcl w]
set f [open $pair_list r]
while {[gets $f line] >= 0} {
    set tie_pin [lindex $line 0]
    set tie_net [get_object_name [get_nets -of_objects [get_pins $tie_pin]]]
    set floating_pin [lindex $line 1]
    set floating_net [get_object_name [get_nets -of_objects [get_pins $floating_pin]]]
    #puts $o "remove_cells \[get_cells -of_objects \[get_nets $tie_net\]\]"
    puts $o "disconnect_net -net \[get_nets $tie_net\] \[get_pins $tie_pin\]"
    puts $o "connect_net -net \[get_nets $floating_net\] \[get_pins $tie_pin\]"
}
close $f
close $o
}


proc createFeed {} {
set n 40
set s 0
set o [open createFeed.tcl w]
for {set i $s} {$i < [expr $s + $n]} {incr i} {
    puts $o "create_port FE_FEED_VSI_in_$i -direction in -port_type signal"
    puts $o "create_port FE_FEED_VSI_out_$i -direction out -port_type signal"
    puts $o "create_net FE_FEED_VSI_in_$i"
    puts $o "connect_net -net \[get_nets FE_FEED_VSI_in_$i\] \[get_ports FE_FEED_VSI_in_$i\]"
    puts $o "connect_net -net \[get_nets FE_FEED_VSI_in_$i\] \[get_ports FE_FEED_VSI_out_$i\]"
}
close $o
}

proc connectPinNet {} {
set o [open connectPinNet.tcl w]
set pins [get_pins df_tcdx_ch1_t*/FE_FEED_VSI_*]
foreach_in_collection pin $pins {
    set pin_name [get_object_name $pin]
    if {[regexp {(\S+)\/(\S+)} $pin_name match tile ref_pin]} {
        set net FE_FEED_${tile}_${ref_pin}
        puts $o "create_net $net" 
        puts $o "connect_net -net \[get_nets $net\] \[get_pins $pin_name\]"
    }
}
close $o
}


proc traceOutPin {pin} {
set level 10
set lod_pin $pin
while (1) {
    set drv_net [get_nets -of_objects [get_pins $lod_pin]]
    set drv_pin [filter_collection [get_pins -of_objects $drv_net] "direction == out"]
    set drv_cell [get_cells -of_objects $drv_pin]
    puts "[get_object_name $drv_cell]"
    #puts "[get_object_name  [filter_collection [get_pins -of_objects $drv_cell] "direction == in && is_user_pg == false"]]"
    if {[sizeof_collection [filter_collection [get_pins -of_objects $drv_cell] "direction == in && is_user_pg == false"]] ==1} {
        set lod_pin [filter_collection [get_pins -of_objects $drv_cell] "direction == in && is_user_pg == false"]
    } else {
        break
    }
}
}

proc saveCells {} {
set o [open saveCells.tcl w]
foreach_in_collection cell [get_selection] {
    set bbox [get_attribute $cell bbox]
    set x [lindex [lindex $bbox 0] 0]
    set y [lindex [lindex $bbox 0] 1]
    set cell_name [get_object_name $cell]
    puts $o "set_cell_location \[get_cells $cell_name\]  -coordinates {$x $y}"
}
close $o
}


proc placeUnplacedPins {} {
set ports [get_ports * -quiet -filter "physical_status == unplaced"]
if {[sizeof_collection $ports] > 0} {
    place_pins -ports [get_ports $ports]
}
}

proc SnapPins {} {
set all_boundary [get_attribute [current_design ] boundary]

}
