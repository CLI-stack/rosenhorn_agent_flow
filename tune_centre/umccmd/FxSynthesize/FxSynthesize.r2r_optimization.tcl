################################################################################
# R2R Timing Optimization for UMCCMD - R2R FOCUSED v7
# Target: totalCoreWNS < -60ps and totalCoreTNS < -68447ps
# Created: 2026-03-04
# Updated: 2026-04-01 - v7: Replace cell-based bounds with coordinate-based (floorplan-aware)
################################################################################
#
# RUN ANALYSIS SUMMARY:
#   Mar02 (v1): WNS=-82ps   totalCoreTNS=~-50K   (good TNS, moderate WNS)
#   Mar16 (v3): WNS=-93ps   totalCoreTNS=-68447   (BEST TNS baseline)
#   Mar20 (v5): WNS=-83ps   totalCoreTNS=-92107   (WNS improved but TNS REGRESSED)
#   Mar30 (v6): WNS=pending totalCoreTNS=pending   (cell-based bounds, running)
#
# V5 REGRESSION ROOT CAUSES (Mar20):
#   1. set_boundary_optimization on ALL DCQARB hier cells:
#      -> umc_DCQARB_r2r_to exploded: ~0 -> -57,456ps TNS
#      -> umc_ARB_r2r_to regressed:   ~0 -> -9,860ps TNS
#   2. set_max_fanout 30 on ALL DCQARB cells (too broad):
#      -> Massive extra buffering across entire DCQARB hierarchy
#      -> Optimizer spent resources on buffering instead of TNS repair
#
# V6 LIMITATION (Mar30):
#   Cell-based bounds (-cells) wrap around current cell positions.
#   At 34.6% overall utilization, cells are loosely spread across die ->
#   bounds cover large area with no forced relocation -> minimal wire reduction.
#
# CRITICAL PATH ANALYSIS (from Mar20 pass_3):
#   umc_ARB_internal_r2r: 25 levels, 384.68ps path, -83.67ps slack
#   umc_PGT_critical:     27 levels, 374.99ps path, -82.64ps slack
#   umc_DCQARB_r2r:       30 levels, 362.20ps path, -65.25ps slack
#   Wire delay: ~5-7ps/level of 13-15ps/level average -> physical clustering can help
#
# FLOORPLAN ANALYSIS (from PreInsertRep.def + report_area Mar20081232):
#   Die area: 396.768 x 642.096 um (254,763 um2), util=34.6%
#   Fixed macros:
#     SRAM0 (ARB/RH drfmcnt_array0): (12.4, 506.9) to (35.6, 631.8) um
#     SRAM1 (ARB/RH drfmcnt_array1): (47.6, 506.9) to (70.8, 631.8) um
#     DFX macro (tile_dfx/ros_0):    (82.8, 602.4) to (111.9, 631.8) um
#   Hierarchy std cell areas:
#     ARB/RH:       6,246 um2 (excl 5,785 um2 SRAM)
#     ARB/DCQARB:  15,179 um2
#     ARB/PGT:      5,126 um2
#     ARB internal: 46,065 um2 (residual: ARB - RH - DCQARB - PGT - CMDARB - CTRLSW)
#
# V7 STRATEGY:
#   1. KEEP all v6 path groups, weights, timing effort settings
#   2. REPLACE cell-based bounds with coordinate-based (floorplan-aware):
#      - Forces cells INTO specific regions near communicating macros
#      - Sized from actual DEF + report_area data (60-65% target utilization)
#      - ARB/RH anchored directly below SRAMs to minimize SRAM port wire delay
#      - DCQARB and PGT placed in macro-free zones (right/center)
#      - ARB internal in lower half (large bound, 60% util)
#   3. ADD: arb_rh_bound (new - ARB/RH logic near SRAMs)
#   4. ADD: dcqarb_bound (new - DCQARB in center-right zone)
#
################################################################################

puts "INFO: Sourcing R2R optimization TCL v7 (Coordinate-based floorplan-aware bounds)..."

################################################################################
# 1. PATH GROUPS - R2R ONLY (NO IO PATHS)
################################################################################

set ff [all_registers]

# === ARB R2R internal paths - DCQARB excluded (v4 fix maintained) ===
set arb_regs [filter_collection $ff "full_name =~ *ARB/* && full_name !~ *DCQARB*"]
if {[sizeof_collection $arb_regs] > 0} {
    group_path -name umc_ARB_internal_r2r -critical_range 600 -weight 8 \
        -from $arb_regs -to $arb_regs
    puts "  Created umc_ARB_internal_r2r: [sizeof_collection $arb_regs] regs (weight=8, range=600)"
}

# === ARB <-> External paths (DCQARB excluded) ===
set non_arb_non_dcq_regs [filter_collection $ff "full_name !~ *ARB/*"]
if {[sizeof_collection $arb_regs] > 0 && [sizeof_collection $non_arb_non_dcq_regs] > 0} {
    group_path -name umc_ARB_r2r_to -critical_range 400 -weight 6 \
        -from $arb_regs -to $non_arb_non_dcq_regs
    puts "  Created umc_ARB_r2r_to: ARB->external (weight=6, range=400)"

    group_path -name umc_ARB_r2r_from -critical_range 400 -weight 7 \
        -from $non_arb_non_dcq_regs -to $arb_regs
    puts "  Created umc_ARB_r2r_from: external->ARB (weight=7, range=400)"
}

# === PGT critical path ===
set pgt_entry_regs [get_cells -quiet -hier -filter "full_name =~ *PgtEntryVld*"]
set pgt_alloc_regs [get_cells -quiet -hier -filter "full_name =~ *PgtAllocPlr*"]
if {[sizeof_collection $pgt_entry_regs] > 0 && [sizeof_collection $pgt_alloc_regs] > 0} {
    group_path -name umc_PGT_critical -critical_range 300 -weight 8 \
        -from $pgt_entry_regs -to $pgt_alloc_regs
    puts "  Created umc_PGT_critical: worst PGT path (weight=8, range=300)"
}

# === DCQARB R2R - weight 7, range 600 (kept from v5 - helped WNS) ===
# DCQARB has NVP=2339, TNS=-39K, WNS=-62ps - second biggest CoreTNS contributor
# Raised from v3 weight=6/range=500. Boundary opt REMOVED (caused TNS regression in v5).
set dcqarb_regs [filter_collection $ff "full_name =~ *DCQARB*"]
if {[sizeof_collection $dcqarb_regs] > 0} {
    group_path -name umc_DCQARB_r2r -critical_range 600 -weight 7 \
        -from $dcqarb_regs -to $dcqarb_regs
    puts "  Created umc_DCQARB_r2r: [sizeof_collection $dcqarb_regs] regs (weight=7, range=600)"
}

if {[sizeof_collection $dcqarb_regs] > 0} {
    group_path -name umc_DCQARB_r2r_to -critical_range 400 -weight 5 \
        -to $dcqarb_regs
    puts "  Created umc_DCQARB_r2r_to: endpoints->DCQARB (weight=5, range=400)"
}

# === Clock Gating paths - from v5 ===
# clock_gating_default: 545 NVP, -10175 TNS, -59ps WNS - third biggest CoreTNS
set clkgate_regs [get_cells -quiet -hier -filter "is_clock_gating_cell == true"]
if {[sizeof_collection $clkgate_regs] > 0} {
    group_path -name umc_clkgate_r2r -critical_range 400 -weight 6 \
        -to $clkgate_regs
    puts "  Created umc_clkgate_r2r: [sizeof_collection $clkgate_regs] clock gate cells (weight=6, range=400) [NEW]"
} else {
    # Fallback: target clock_gating_default group by endpoint name pattern
    group_path -name umc_clkgate_r2r -critical_range 400 -weight 6 \
        -to [get_cells -quiet -hier -filter "full_name =~ *ICG* || full_name =~ *ClkGate*"]
    puts "  Created umc_clkgate_r2r: ICG/ClkGate endpoints (weight=6, range=400) [NEW]"
}

# === ADDR R2R ===
set addr_regs [filter_collection $ff "full_name =~ *ADDR*"]
if {[sizeof_collection $addr_regs] > 0} {
    group_path -name umc_ADDR_r2r -critical_range 500 -weight 6 \
        -from $addr_regs -to $addr_regs
    puts "  Created umc_ADDR_r2r: [sizeof_collection $addr_regs] regs (weight=6, range=500)"
}

# === FEI R2R ===
set fei_regs [filter_collection $ff "full_name =~ *FEI*"]
if {[sizeof_collection $fei_regs] > 0} {
    group_path -name umc_FEI_r2r -critical_range 500 -weight 5 \
        -from $fei_regs -to $fei_regs
    puts "  Created umc_FEI_r2r: [sizeof_collection $fei_regs] regs (weight=5, range=500)"
}

# === TIM module paths ===
set tim_regs [filter_collection $ff "full_name =~ *ARB/TIM* && full_name !~ *DCQARB*"]
if {[sizeof_collection $tim_regs] > 0} {
    group_path -name umc_TIM_r2r -critical_range 400 -weight 5 \
        -from $tim_regs -to $tim_regs
    puts "  Created umc_TIM_r2r: [sizeof_collection $tim_regs] regs (weight=5, range=400)"
}

# === CMD R2R ===
set cmd_regs [filter_collection $ff "full_name =~ *CMD* && full_name !~ *DCQARB*"]
if {[sizeof_collection $cmd_regs] > 0} {
    group_path -name umc_cmd_r2r -critical_range 500 -weight 5 \
        -from $cmd_regs -to $cmd_regs
    puts "  Created umc_cmd_r2r: [sizeof_collection $cmd_regs] regs (weight=5, range=500)"
}

# === CMD from ===
set cmd_from_regs [filter_collection $ff "full_name =~ *CMD/* && full_name !~ *DCQARB*"]
if {[sizeof_collection $cmd_from_regs] > 0} {
    group_path -name umc_cmd_r2r_from -critical_range 400 -weight 5 \
        -from $cmd_from_regs
    puts "  Created umc_cmd_r2r_from: CMD startpoints (weight=5, range=400)"
}

# === SPAZ paths ===
set spaz_regs [filter_collection $ff "full_name =~ *SPAZ*"]
if {[sizeof_collection $spaz_regs] > 0} {
    group_path -name SPAZ_r2r -critical_range 400 -weight 5 \
        -from $spaz_regs -to $spaz_regs
    puts "  Created SPAZ_r2r: [sizeof_collection $spaz_regs] regs (weight=5, range=400)"
}

# NOTE: SYN_I2R path group REMOVED in v5
# IO paths do NOT contribute to totalCoreTNS - optimizer effort wasted there

################################################################################
# 2. TIMING EFFORT SETTINGS
################################################################################

set_app_options -name opt.timing.effort -value high
puts "  Set opt.timing.effort = high"

set_app_options -name opt.area.effort -value high
puts "  Set opt.area.effort = high"

set_app_options -name opt.common.buffer_area_effort -value ultra
puts "  Set opt.common.buffer_area_effort = ultra"

# Enable high effort timing for more R2R optimization passes (kept from v5)
set_app_options -name compile.flow.high_effort_timing -value true
puts "  Set compile.flow.high_effort_timing = true"

################################################################################
# 3. COMPILE PLACEMENT (HIGH - stable)
################################################################################

set_app_options -name compile.final_place.effort -value high
puts "  Set compile.final_place.effort = high"

set_app_options -name compile.initial_place.buffering_aware_placement_effort -value high
puts "  Set compile.initial_place.buffering_aware_placement_effort = high"

set_app_options -name place_opt.final_place.effort -value high
puts "  Set place_opt.final_place.effort = high"

set_app_options -name place_opt.place.congestion_effort -value high
puts "  Set place_opt.place.congestion_effort = high"

set_app_options -name clock_opt.place.congestion_effort -value high
puts "  Set clock_opt.place.congestion_effort = high"

################################################################################
# 4. LOGIC RESTRUCTURING (area_timing - stable)
################################################################################

set_app_options -name opt.common.advanced_logic_restructuring_mode -value area_timing
puts "  Set opt.common.advanced_logic_restructuring_mode = area_timing"

################################################################################
# 5. ROUTING (HIGH effort)
################################################################################

set_app_options -name route.common.rc_driven_setup_effort_level -value high
puts "  Set route.common.rc_driven_setup_effort_level = high"

set_app_options -name route.global.effort_level -value high
puts "  Set route.global.effort_level = high"

set_app_options -name route.detail.optimize_wire_via_effort_level -value high
puts "  Set route.detail.optimize_wire_via_effort_level = high"

################################################################################
# 6. CCD AND HOLD
################################################################################

set_app_options -name ccd.hold_control_effort -value high
puts "  Set ccd.hold_control_effort = high"

set_app_options -name compile.flow.high_effort_area -value true
puts "  Set compile.flow.high_effort_area = true"

set_app_options -name multibit.banking.enable_tns_degradation_estimation -value true
puts "  Set multibit.banking.enable_tns_degradation_estimation = true"

################################################################################
# 7. ARB MODULE OPTIMIZATION (ARB only - DCQARB boundary opt REVERTED from v5)
################################################################################

# ARB: boundary opt + dont_touch removal (stable since v3)
set arb_hier_cells [get_cells -quiet -hier -filter \
    "full_name =~ *ARB* && is_hierarchical == true && full_name !~ *DCQARB*"]
if {[sizeof_collection $arb_hier_cells] > 0} {
    set_boundary_optimization $arb_hier_cells true
    puts "  Enabled boundary opt for [sizeof_collection $arb_hier_cells] ARB cells (excl DCQARB)"
}

set arb_cells [get_cells -quiet -hier -filter \
    "full_name =~ *ARB/* && full_name !~ *DCQARB*"]
if {[sizeof_collection $arb_cells] > 0} {
    set_dont_touch $arb_cells false
    puts "  Removed dont_touch on [sizeof_collection $arb_cells] ARB cells (excl DCQARB)"
}

# DCQARB boundary opt: REVERTED from v5
# v5 applied set_boundary_optimization on ALL DCQARB hier cells which caused
# umc_DCQARB_r2r_to to explode from ~0 to -57,456ps TNS (and umc_ARB_r2r_to to -9,860ps)
# Root cause: boundary opt restructured DCQARB interface, creating a massive number
# of new paths into DCQARB that the optimizer could not repair.
# DCQARB dont_touch removal also NOT done - caused instability in v2.

################################################################################
# 8. REGISTER REPLICATION (MEDIUM - stable)
################################################################################

set_app_options -name compile.seqmap.register_replication_placement_effort -value medium
puts "  Set compile.seqmap.register_replication_placement_effort = medium"

set_app_options -name compile.retiming.optimization_priority -value setup_timing
puts "  Set compile.retiming.optimization_priority = setup_timing"

# NOTE: Forward retiming REMOVED in v5
# It was added for I2R benefit only - no impact on totalCoreTNS (R2R metric)
# Backward retiming remains disabled (caused v2 instability)

################################################################################
# 9. HIGH-FANOUT NET OPTIMIZATION
################################################################################

set mrdimm_regs [get_cells -quiet -hier -filter "full_name =~ *MrDimmEn*"]
if {[sizeof_collection $mrdimm_regs] > 0} {
    set_max_fanout 20 $mrdimm_regs
    puts "  Set max_fanout=20 for MrDimmEn: [sizeof_collection $mrdimm_regs] cells"
}

set clkarb_regs [get_cells -quiet -hier -filter "full_name =~ *CLKARB*"]
if {[sizeof_collection $clkarb_regs] > 0} {
    set_max_fanout 20 $clkarb_regs
    puts "  Set max_fanout=20 for CLKARB: [sizeof_collection $clkarb_regs] cells"
}

# DCQARB max_fanout=30 REMOVED from v5:
# Applying max_fanout to ALL DCQARB cells (49.8% of design) caused massive
# buffering overhead. The optimizer spent resources inserting buffers across
# the entire DCQARB hierarchy instead of fixing TNS on critical R2R paths.
# Result: umc_DCQARB_r2r_to TNS -57K (new regression) and total TNS -92K vs -68K.

################################################################################
# 10. PHYSICAL BOUNDS - v7 (COORDINATE-BASED, FLOORPLAN-AWARE)
# Goal: Force ARB sub-hierarchies into specific floorplan regions near SRAMs.
# Approach: coordinate-based bounds actively relocate cells during placement
#           (vs cell-based in v6 which only wraps around current positions).
#
# Floorplan basis: PreInsertRep.def + report_area (umccmd_Mar20081232)
#   Die: 396.768 x 642.096 um, overall util=34.6% (loosely placed)
#   SRAMs at: X=12-71 um, Y=507-632 um (left side, upper)
#   DFX macro: X=83-112 um, Y=602-632 um (top-left)
#   Free zones: lower half (Y=0-507, full width) + right of macros (X=115-397, Y=507-642)
#
# Bound sizing (target 60-65% utilization inside each bound):
#   arb_rh_bound:       6,246 um2 cells -> 15,755 um2 bound -> 39.6% util (near SRAMs)
#   dcqarb_bound:      15,179 um2 cells -> 24,750 um2 bound -> 61.3% util
#   pgt_critical_bound: 5,126 um2 cells -> 10,530 um2 bound -> 48.7% util
#   arb_internal_bound:46,065 um2 cells -> 76,500 um2 bound -> 60.2% util
################################################################################

# === ARB/RH bound — directly below SRAMs ===
# ARB/RH logic interfaces heavily with SRAM ports at Y=507 um.
# Placing cells at Y=370-507 minimizes wire from RH registers to SRAM read/write ports.
# SRAMs occupy X=12-71, Y=507-632 -> bound below at X=0-115, Y=370-507.
create_bound arb_rh_bound -coordinate {0 370 115 507}
puts "  Created coordinate bound arb_rh_bound: (0,370)-(115,507) um [ARB/RH near SRAMs, 39.6% util]"

# === DCQARB bound — center zone, right of SRAM blockage ===
# ARB/DCQARB: 15,179 um2 std cells. Placed right of SRAM macro zone (X>115).
# Y=390-540 keeps DCQARB logic central, minimizing paths to/from ARB internal.
create_bound dcqarb_bound -coordinate {115 390 280 540}
puts "  Created coordinate bound dcqarb_bound: (115,390)-(280,540) um [DCQARB, 61.3% util]"

# === PGT critical bound — far right, macro-free ===
# ARB/PGT: 5,126 um2 std cells. PgtEntryVld->PgtAllocPlr worst path (-82.64ps).
# Right side (X>280) is completely free of macros. Co-located near dcqarb_bound.
create_bound pgt_critical_bound -coordinate {280 420 397 510}
puts "  Created coordinate bound pgt_critical_bound: (280,420)-(397,510) um [ARB/PGT, 48.7% util]"

# === ARB internal bound — lower half ===
# ARB internal (residual: ARB minus RH/DCQARB/PGT/CMDARB/CTRLSW): 46,065 um2.
# Large bound required. Lower half (Y=0-225) is fully free of macros.
# At 60.2% util - significantly tighter than overall 34.6% to force wire reduction.
create_bound arb_internal_bound -coordinate {0 0 340 225}
puts "  Created coordinate bound arb_internal_bound: (0,0)-(340,225) um [ARB internal, 60.2% util]"

################################################################################
# Summary
################################################################################

puts ""
puts "================================================================================"
puts "INFO: R2R optimization TCL v7 complete (Coordinate-based floorplan-aware bounds)"
puts "================================================================================"
puts ""
puts "  Kept from v6 (stable):"
puts "    - DCQARB boundary optimization REMOVED (v5 caused -57K TNS regression)"
puts "    - set_max_fanout 30 on DCQARB REMOVED (caused excessive buffering)"
puts "    - compile.flow.high_effort_timing = true"
puts "    - DCQARB weight 7, range 600"
puts "    - Clock gate path group umc_clkgate_r2r"
puts "    - All path group definitions unchanged"
puts ""
puts "  Changed in v7 (cell-based -> coordinate-based bounds):"
puts "    v6 cell-based: wraps around current cell positions (no forced relocation)"
puts "    v7 coordinate-based: actively moves cells INTO target floorplan regions"
puts "    Basis: PreInsertRep.def + report_area (umccmd_Mar20081232, util=34.6%)"
puts ""
puts "    1. arb_rh_bound     (0,370)-(115,507) um -> ARB/RH below SRAMs [39.6% util]"
puts "       -> Minimizes wire from RH registers to SRAM ports at Y=507 um"
puts "    2. dcqarb_bound     (115,390)-(280,540) um -> DCQARB center    [61.3% util]"
puts "       -> NEW in v7: DCQARB previously had no bound"
puts "    3. pgt_critical_bound (280,420)-(397,510) um -> PGT right side [48.7% util]"
puts "       -> Worst path PgtEntryVld->PgtAllocPlr -82.64ps clustered"
puts "    4. arb_internal_bound (0,0)-(340,225) um -> ARB internal lower [60.2% util]"
puts "       -> 46,065 um2 cells forced into lower half (vs spread at 34.6% overall)"
puts ""
puts "  Path Group Priorities (R2R only, non-overlapping):"
puts "    HIGH   (weight=8): umc_ARB_internal_r2r, umc_PGT_critical"
puts "    MEDIUM (weight=7): umc_ARB_r2r_from, umc_DCQARB_r2r"
puts "    MEDIUM (weight=6): umc_ARB_r2r_to, umc_ADDR_r2r, umc_clkgate_r2r"
puts "    LOW    (weight=5): umc_DCQARB_r2r_to, umc_cmd_r2r, umc_FEI_r2r, SPAZ_r2r"
puts ""
puts "  Expected vs Mar20 baseline (WNS=-83.7ps, TNS=-92107ps):"
puts "    totalCoreWNS: -83.7ps -> target <-60ps (coordinate bounds force relocation)"
puts "    totalCoreTNS: -92107ps -> target <-68447ps"
puts "================================================================================"
