set CKCells [get_cells -hier * -filter "ref_name=~*LVT08*CK*||ref_name=~*CK*LVT"]
set LibCells [get_lib_cells -of_objects $CKCells]
foreach_in_collection mylibcell  $LibCells {
  set FullNameLibCell [get_attribute $mylibcell full_name]
  set NameLibCell [get_attribute $mylibcell name]
  set tList [get_cells $CKCells -quiet -filter @ref_name==$NameLibCell]
  regsub -all {LVT08_} $FullNameLibCell ULT08_ sub1
  regsub -all {ts06ncpllogl08udl057f} $sub1 ts06ncpvlogl08udl057f sub2
  regsub -all {08lvt} $sub2 08ulvt sub3
  regsub -all {CNODLVT} $sub3 CNODULVT sub4
  regsub -all {cstmlvt} $sub4 cstmulvt sub5
  regsub -all {cnodmrklvt} $sub5 cnodmrkulvt sub6
  if { [sizeof_collection [get_lib_cells -quiet $sub6]] == 0 } {continue }
  size_cell $tList $sub6
}

set CKCells [get_cells -hier * -filter "ref_name=~*ULVTLL08*CK*||ref_name=~*CK*ULVTLL"]
set LibCells [get_lib_cells -of_objects $CKCells]
foreach_in_collection mylibcell  $LibCells {
  set FullNameLibCell [get_attribute $mylibcell full_name]
  set NameLibCell [get_attribute $mylibcell name]
  set tList [get_cells $CKCells -quiet -filter @ref_name==$NameLibCell]
  regsub -all {ULVTLL08_} $FullNameLibCell ULT08_ sub1
  regsub -all {ts06ncpllogl08udl057f} $sub1 ts06ncpvlogl08udl057f sub2
  regsub -all {08ulvtll} $sub2 08ulvt sub3
  regsub -all {CNODULVTLL} $sub3 CNODULVT sub4
  regsub -all {cstmulvtll} $sub4 cstmulvt sub5
  regsub -all {cnodmrkulvtll} $sub5 cnodmrkulvt sub6
  regsub -all {cnodbaseulvtll} $sub6 cnodbaseulvt sub7
  if { [sizeof_collection [get_lib_cells -quiet $sub7]] == 0 } {continue }
  size_cell $tList $sub7
}

#####
set root_buffers [get_cells Cpl_SOCCLK_MESH_CTS_ROOT*]
foreach_in_collection root_buffer $root_buffers { 
    set pin [get_pins -of $root_buffer -f "lib_pin_name== Z"]
    set cells [get_cells [all_fanout -flat -only_cells -from $pin -levels 3 ] -filter " full_name=~*d0nt_clk_gate_cell* || full_name=~ *d0nt_mux* || full_name=~ *MPCTS_SPLIT* "]
    puts "Magnet Root:[get_object_name $root_buffer ] has [sizeof_collection $cells] cells \n [get_object_name $cells]"
    if {[sizeof_collection $cells] > 100} {
        puts "Mangnet Warring: Root [get_object_name $root_buffer ] gating cells great than 100 , skip magnet for this root" 
        continue
    }
    if {[sizeof_collection $cells]} {
        magnet_placement -move_fixed $pin -cells $cells
    }
}

set move_cell [get_cells [get_cells [all_fanout -flat -only_cells -from Cpl_SOCCLK_MESH_CTS_ROOT/Z -levels 3 ] -filter " full_name=~*d0nt_clk_gate_cell* || full_name=~ *d0nt_mux* || full_name=~ *MPCTS_SPLIT* "]  -filter "bbox_lly > -269"]
set_cell_location -coordinates {-0.2280 -269.5500} [get_cells $move_cell] -ignore_fixed
set_fixed_objects [get_cells $move_cell] -unfix
legalize_placement
set_fixed_objects [get_cells [all_fanout -flat -only_cells -from Cpl_SOCCLK_MESH_CTS_ROOT/Z -levels 3 ] -filter " full_name=~*d0nt_clk_gate_cell* || full_name=~ *d0nt_mux* || full_name=~ *MPCTS_SPLIT* "] -fix


save_lib -as data/Cts.Pre_cts.nlib

#shorten SOCCLK_IO
set befor_sc [current_scenario]
current_scenario setup_tt0p9v100c_typrc100c_FuncTT0p9v
set IN_FLOPS_CP [filter_collection [get_pins -of [filter_collection [all_fanout -from [all_inputs -exclude_clock_ports] -flat -endpoints_only -only_cells] "is_integrated_clock_gating_cell!=true"]] is_clock_pin]
set OUT_FLOPS_CP [filter_collection [get_pins -of [filter_collection [all_fanin -to [all_outputs] -flat -startpoints_only -only_cells ] "is_integrated_clock_gating_cell!=true"]] is_clock_pin]
append_to_collection OUT_FLOPS_CP $IN_FLOPS_CP
set IO_flops [get_pins $OUT_FLOPS_CP]

set_clock_balance_points -clock [get_clocks {SOCCLK}] -balance_points [get_pins $IO_flops] -consider_for_balancing true -rise -early -delay 0 -offset 40
set_clock_balance_points -clock [get_clocks {SOCCLK}] -balance_points [get_pins $IO_flops] -consider_for_balancing true -rise -late -delay 0 -offset 40
current_scenario $befor_sc

set_clock_balance_points -scenarios setup_tt0p9v100c_typrc100c_FuncTT0p9v -balance_points mmhub_sub/dagb/s7_dagb_cg/dagb_cg_wrreq/inst_new_CGTT_u_cgtt_local_dclk/ls_assert_delay_counter_reg_7__MB_ls_assert_delay_counter_reg_6__MB_ls_assert_delay_counter_reg_5__MB_ls_assert_delay_counter_reg_4__MB_ls_assert_delay_counter_reg_3__MB_ls_assert_delay_counter_reg_2__MB_ls_assert_delay_counter_reg_1__MB_ls_assert_delay_counter_reg_0_ -delay 100 -clock SOCCLK

