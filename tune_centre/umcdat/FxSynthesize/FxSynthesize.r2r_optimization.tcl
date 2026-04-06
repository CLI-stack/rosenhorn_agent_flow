################################################################################
# R2R Timing Optimization for UMCDAT - v3
# Target: UCLK_R2R WNS < -50ps, totalCoreTNS improvement
# Created: 2026-03-04
# Updated: 2026-03-30 - v3: Fix DFICLK_R2R regression, add umbrella groups, create_bound
################################################################################
#
# TIMING ANALYSIS (Mar16094718 Pass3 results from v2):
#   Path Group       WNS(ps)   TNS(ps)    NVP   Levels   ps/lvl   p1->p3 delta
#   --------------------------------------------------------------------------
#   UCLK_R2R         -62.65  -142,246   6,351     24      14.7    +1.57ps (slow)
#   RDAESR2R         -64.51   -88,327   1,792     27      13.2    +3.71ps (slow)
#   XTSAESR2R        -28.23   -13,482     896     23      14.1    +6.46ps (GOOD)
#   DFICLK_R2R       -40.63      -272      32     20      13.7    -8.99ps (REGRESSED!)
#   UCLK_I2R        -314.28  -517,129   3,219      6      ---     IO path, skip
#   DFICLK_I2R      -298.03   -56,674     308     15      ---     IO path, skip
#   --------------------------------------------------------------------------
#   R2R total TNS: -244,326ps (29.8% of -818K total)
#   IO total TNS:  -574,473ps (70.2% - structural IO delay, not fixable by synthesis)
#
# V2 ROOT CAUSE ANALYSIS:
#   1. DFICLK_R2R regressed -31.64 -> -40.63ps (-8.99ps worse over 3 passes)
#      ROOT CAUSE: BEQ boundary optimization - same pattern as DCQARB in umccmd.
#      set_boundary_optimization restructures BEQ interfaces, creating new
#      cross-boundary paths into DFICLK domain that optimizer cannot repair.
#   2. UCLK_R2R only improved +1.57ps over 3 passes (too slow)
#      ROOT CAUSE: Sub-module groups (RDPIPE/SUBBYTE/MIXCOL) may miss paths
#      if hierarchy names don't match exactly. No umbrella group as safety net.
#   3. RDAESR2R has -64.51ps WNS (worse than UCLK_R2R) with no top-level group.
#      Only SUBBYTE+MIXCOL sub-module groups cover it - incomplete targeting.
#   4. Missing compile.flow.high_effort_timing (present in umccmd v5/v6, not v2).
#
# V3 FIX STRATEGY:
#   1. REMOVE: BEQ boundary optimization (caused DFICLK_R2R regression)
#   2. ADD: Umbrella UCLK_R2R group (all non-BEQ registers) as safety net
#   3. ADD: Umbrella RDAESR2R group (AES pipeline regs as a whole)
#   4. ADD: compile.flow.high_effort_timing = true (more optimization passes)
#   5. RAISE: XTSAESR2R weight 6->7 (best responder, give it more resources)
#   6. ADD: Soft bounds for AES pipeline cells (wire delay ~14ps/level,
#            clustering RDPIPE+SUBBYTE can recover 3-5 levels of wire delay)
#
################################################################################

puts "INFO: Sourcing UMCDAT R2R optimization TCL v3 (Fix DFICLK regression, umbrella groups)..."

################################################################################
# 1. UMBRELLA R2R PATH GROUPS (top-level safety nets)
################################################################################

set ff [all_registers]

# === UMBRELLA: All UCLK domain R2R (excluding BEQ which is DFICLK domain) ===
# Ensures ALL UCLK R2R paths get prioritized even if sub-module names don't match.
# Sub-module groups below take priority for named paths; this catches the rest.
set non_beq_regs [filter_collection $ff "full_name !~ *BEQ/*"]
if {[sizeof_collection $non_beq_regs] > 0} {
    group_path -name umc_UCLK_r2r_all -critical_range 600 -weight 7 \
        -from $non_beq_regs -to $non_beq_regs
    puts "  Created umc_UCLK_r2r_all: [sizeof_collection $non_beq_regs] non-BEQ regs (weight=7, range=600)"
}

# === UMBRELLA: RDAESR2R - AES read pipeline as a whole ===
# RDAESR2R has WNS=-64.51ps, worse than UCLK_R2R, but had no top-level group in v2.
# Covers RDPIPE + SUBBYTE + MIXCOL + RdDatPipe together.
set rdaes_regs [filter_collection $ff \
    "full_name =~ *UMCSEC_RDPIPE* || full_name =~ *SUBBYTE* || \
     full_name =~ *MIXCOL* || full_name =~ *RdDatPipe*"]
if {[sizeof_collection $rdaes_regs] > 0} {
    group_path -name umc_RDAESR2R_all -critical_range 600 -weight 8 \
        -from $rdaes_regs -to $rdaes_regs
    puts "  Created umc_RDAESR2R_all: [sizeof_collection $rdaes_regs] AES read pipeline regs (weight=8, range=600)"
}

################################################################################
# 2. CRITICAL R2R SUB-MODULE GROUPS (Weight 7-8)
# More specific than umbrella groups - take priority for matching paths
################################################################################

# === UCLK_R2R: RDPIPE - AES read pipeline (main UCLK_R2R contributor) ===
set rdpipe_regs [filter_collection $ff "full_name =~ *UMCSEC_RDPIPE*"]
if {[sizeof_collection $rdpipe_regs] > 0} {
    group_path -name umc_RDPIPE_r2r -critical_range 600 -weight 8 \
        -from $rdpipe_regs -to $rdpipe_regs
    puts "  Created umc_RDPIPE_r2r: [sizeof_collection $rdpipe_regs] regs (weight=8, range=600)"
}

# === RDAESR2R: SUBBYTE - SubBytes AES transformation ===
set subbyte_regs [filter_collection $ff "full_name =~ *SUBBYTE*"]
if {[sizeof_collection $subbyte_regs] > 0} {
    group_path -name umc_SUBBYTE_r2r -critical_range 600 -weight 8 \
        -from $subbyte_regs -to $subbyte_regs
    puts "  Created umc_SUBBYTE_r2r: [sizeof_collection $subbyte_regs] regs (weight=8, range=600)"
}

# === RDAESR2R: MIXCOL - MixColumns AES transformation ===
set mixcol_regs [filter_collection $ff "full_name =~ *MIXCOL*"]
if {[sizeof_collection $mixcol_regs] > 0} {
    group_path -name umc_MIXCOL_r2r -critical_range 600 -weight 7 \
        -from $mixcol_regs -to $mixcol_regs
    puts "  Created umc_MIXCOL_r2r: [sizeof_collection $mixcol_regs] regs (weight=7, range=600)"
}

# === RDAESR2R: RdDatPipe endpoints ===
set rddatpipe_regs [filter_collection $ff "full_name =~ *RdDatPipe*"]
if {[sizeof_collection $rddatpipe_regs] > 0} {
    group_path -name umc_RdDatPipe_r2r -critical_range 500 -weight 7 \
        -to $rddatpipe_regs
    puts "  Created umc_RdDatPipe_r2r: [sizeof_collection $rddatpipe_regs] endpoints (weight=7, range=500)"
}

################################################################################
# 3. DFICLK_R2R - BEQ MODULE (Weight 6, reduced from v2's 7)
# DFICLK_R2R regressed in v2. Reducing weight and removing boundary opt.
# BEQ period = 231.58ps, WNS=-40.63ps (need 40.6ps cut, 20 levels at 13.7ps/lvl)
################################################################################

set beq_regs [filter_collection $ff "full_name =~ *BEQ/*"]
if {[sizeof_collection $beq_regs] > 0} {
    group_path -name umc_BEQ_r2r -critical_range 400 -weight 6 \
        -from $beq_regs -to $beq_regs
    puts "  Created umc_BEQ_r2r: [sizeof_collection $beq_regs] regs (weight=6, range=400)"
}

################################################################################
# 4. XTSAESR2R - XTS ENCRYPTION (Weight raised 6->7 - best responder in v2)
# v2 result: +6.46ps WNS improvement (best of all R2R groups)
# Raise weight to accelerate toward timing closure.
################################################################################

set xtspipe_regs [filter_collection $ff "full_name =~ *UMCSEC_XTSPIPE*"]
if {[sizeof_collection $xtspipe_regs] > 0} {
    group_path -name umc_XTSPIPE_r2r -critical_range 500 -weight 7 \
        -from $xtspipe_regs -to $xtspipe_regs
    puts "  Created umc_XTSPIPE_r2r: [sizeof_collection $xtspipe_regs] regs (weight=7, range=500) [v3: raised from 6]"
}

set xtsdatpipe_regs [filter_collection $ff "full_name =~ *XtsDatPipe*"]
if {[sizeof_collection $xtsdatpipe_regs] > 0} {
    group_path -name umc_XtsDatPipe_r2r -critical_range 500 -weight 6 \
        -to $xtsdatpipe_regs
    puts "  Created umc_XtsDatPipe_r2r: [sizeof_collection $xtsdatpipe_regs] endpoints (weight=6, range=500)"
}

################################################################################
# 5. MEDIUM PRIORITY PATH GROUPS (Weight 5-6)
################################################################################

# KEYEXP - Key expansion module
set keyexp_regs [filter_collection $ff "full_name =~ *KEYEXP*"]
if {[sizeof_collection $keyexp_regs] > 0} {
    group_path -name umc_KEYEXP_r2r -critical_range 500 -weight 6 \
        -from $keyexp_regs -to $keyexp_regs
    puts "  Created umc_KEYEXP_r2r: [sizeof_collection $keyexp_regs] regs (weight=6, range=500)"
}

# RdKeyPipe - Key pipeline
set rdkeypipe_regs [filter_collection $ff "full_name =~ *RdKeyPipe*"]
if {[sizeof_collection $rdkeypipe_regs] > 0} {
    group_path -name umc_RdKeyPipe_r2r -critical_range 500 -weight 6 \
        -from $rdkeypipe_regs -to $rdkeypipe_regs
    puts "  Created umc_RdKeyPipe_r2r: [sizeof_collection $rdkeypipe_regs] regs (weight=6, range=500)"
}

# UMCSEC general (catch remaining AES paths not covered above)
set umcsec_regs [filter_collection $ff "full_name =~ *umcsec*"]
if {[sizeof_collection $umcsec_regs] > 0} {
    group_path -name umc_UMCSEC_r2r -critical_range 400 -weight 5 \
        -from $umcsec_regs -to $umcsec_regs
    puts "  Created umc_UMCSEC_r2r: [sizeof_collection $umcsec_regs] regs (weight=5, range=400)"
}

################################################################################
# 6. CRITICAL PATH SPECIFIC GROUPS
################################################################################

# Aes128Mode -> RdKeyPipe (identified as worst explicit path in v2)
set aes128mode_regs [get_cells -quiet -hier -filter "full_name =~ *Aes128Mode*"]
set rdkeypipe_cells [get_cells -quiet -hier -filter "full_name =~ *RdKeyPipe*"]
if {[sizeof_collection $aes128mode_regs] > 0 && [sizeof_collection $rdkeypipe_cells] > 0} {
    group_path -name umc_AES_critical -critical_range 400 -weight 8 \
        -from $aes128mode_regs -to $rdkeypipe_cells
    puts "  Created umc_AES_critical: Aes128Mode -> RdKeyPipe (weight=8, range=400)"
}

################################################################################
# 7. TIMING EFFORT SETTINGS
################################################################################

set_app_options -name opt.timing.effort -value high
puts "  Set opt.timing.effort = high"

set_app_options -name opt.area.effort -value high
puts "  Set opt.area.effort = high"

set_app_options -name opt.common.buffer_area_effort -value ultra
puts "  Set opt.common.buffer_area_effort = ultra"

# v3 NEW: Enable high effort timing for more R2R optimization passes
# Missing from v2 - present in umccmd v5/v6, helps significantly
set_app_options -name compile.flow.high_effort_timing -value true
puts "  Set compile.flow.high_effort_timing = true [v3: NEW - more R2R opt passes]"

################################################################################
# 8. COMPILE PLACEMENT SETTINGS
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
# 9. LOGIC RESTRUCTURING
################################################################################

set_app_options -name opt.common.advanced_logic_restructuring_mode -value area_timing
puts "  Set opt.common.advanced_logic_restructuring_mode = area_timing"

################################################################################
# 10. ROUTING SETTINGS
################################################################################

set_app_options -name route.common.rc_driven_setup_effort_level -value high
puts "  Set route.common.rc_driven_setup_effort_level = high"

set_app_options -name route.global.effort_level -value high
puts "  Set route.global.effort_level = high"

set_app_options -name route.detail.optimize_wire_via_effort_level -value high
puts "  Set route.detail.optimize_wire_via_effort_level = high"

################################################################################
# 11. CCD AND HOLD
################################################################################

set_app_options -name ccd.hold_control_effort -value high
puts "  Set ccd.hold_control_effort = high"

set_app_options -name compile.flow.high_effort_area -value true
puts "  Set compile.flow.high_effort_area = true"

set_app_options -name multibit.banking.enable_tns_degradation_estimation -value true
puts "  Set multibit.banking.enable_tns_degradation_estimation = true"

################################################################################
# 12. AES MODULE OPTIMIZATION (UMCSEC only - BEQ boundary opt REMOVED)
################################################################################

# UMCSEC boundary optimization - safe, helps cross-boundary AES pipeline paths
set umcsec_hier_cells [get_cells -quiet -hier -filter \
    "full_name =~ *umcsec* && is_hierarchical == true"]
if {[sizeof_collection $umcsec_hier_cells] > 0} {
    set_boundary_optimization $umcsec_hier_cells true
    puts "  Enabled boundary optimization for [sizeof_collection $umcsec_hier_cells] UMCSEC cells"
}

# Remove dont_touch on UMCSEC to allow restructuring
set umcsec_cells [get_cells -quiet -hier -filter "full_name =~ *umcsec/*"]
if {[sizeof_collection $umcsec_cells] > 0} {
    set_dont_touch $umcsec_cells false
    puts "  Removed dont_touch on [sizeof_collection $umcsec_cells] UMCSEC cells"
}

# BEQ boundary opt: REMOVED from v3
# v2 enabled set_boundary_optimization on BEQ hier cells.
# Result: DFICLK_R2R regressed from -31.64 -> -40.63ps (-8.99ps worse over 3 passes).
# Root cause: boundary opt restructures BEQ interfaces, exposing new cross-boundary
# paths in the DFICLK domain (231.58ps period) that the optimizer cannot repair.

################################################################################
# 13. REGISTER REPLICATION
################################################################################

set_app_options -name compile.seqmap.register_replication_placement_effort -value medium
puts "  Set compile.seqmap.register_replication_placement_effort = medium"

set_app_options -name compile.retiming.optimization_priority -value setup_timing
puts "  Set compile.retiming.optimization_priority = setup_timing"

################################################################################
# 14. HIGH-FANOUT CONTROL SIGNALS
################################################################################

# Aes128Mode - high fanout control on worst path
set aes_ctrl [get_cells -quiet -hier -filter "full_name =~ *Aes128Mode*"]
if {[sizeof_collection $aes_ctrl] > 0} {
    set_max_fanout 20 $aes_ctrl
    puts "  Set max_fanout=20 for Aes128Mode: [sizeof_collection $aes_ctrl] cells"
}

# UclkEqMemclkBy4Phase - BEQ DFICLK control signal
set uclk_phase [get_cells -quiet -hier -filter "full_name =~ *UclkEqMemclkBy4Phase*"]
if {[sizeof_collection $uclk_phase] > 0} {
    set_max_fanout 20 $uclk_phase
    puts "  Set max_fanout=20 for UclkEqMemclkBy4Phase: [sizeof_collection $uclk_phase] cells"
}

################################################################################
# 15. PHYSICAL BOUNDS - NEW v3
# Wire delay ~14ps/level on 24-27 level critical paths.
# Clustering AES pipeline cells can recover 3-5 levels of wire delay = ~42-70ps.
# Soft bounds: hint to placer without creating hard congestion constraints.
################################################################################

# === Soft bound: AES pipeline (RDPIPE + SUBBYTE) ===
# UCLK_R2R has 24 levels, RDAESR2R has 27 levels - both at ~14ps/level.
# Clustering these physically reduces cross-chip routing on the critical path.
set aes_pipeline_cells [get_cells -quiet -hier -filter \
    "full_name =~ *UMCSEC_RDPIPE* || full_name =~ *SUBBYTE*"]
if {[sizeof_collection $aes_pipeline_cells] > 0} {
    create_bound \
        -name aes_pipeline_bound \
        -type soft \
        -cells $aes_pipeline_cells
    puts "  Created soft bound aes_pipeline_bound: [sizeof_collection $aes_pipeline_cells] RDPIPE+SUBBYTE cells"
} else {
    puts "  Note: RDPIPE/SUBBYTE cells not found for aes_pipeline_bound (check hierarchy)"
}

# === Soft bound: MIXCOL adjacent to SUBBYTE ===
# MIXCOL outputs feed into SUBBYTE in AES round function.
# Keeping them co-located minimizes inter-stage routing delay.
set mixcol_cells [get_cells -quiet -hier -filter "full_name =~ *MIXCOL*"]
if {[sizeof_collection $mixcol_cells] > 0} {
    create_bound \
        -name mixcol_bound \
        -type soft \
        -cells $mixcol_cells
    puts "  Created soft bound mixcol_bound: [sizeof_collection $mixcol_cells] MIXCOL cells"
} else {
    puts "  Note: MIXCOL cells not found for mixcol_bound (check hierarchy)"
}

# === Soft bound: XTS pipeline (XTSPIPE) ===
# XTSAESR2R is the best-responding group (+6.46ps in v2).
# Physical clustering can push it further toward timing closure.
set xtspipe_cells [get_cells -quiet -hier -filter "full_name =~ *UMCSEC_XTSPIPE*"]
if {[sizeof_collection $xtspipe_cells] > 0} {
    create_bound \
        -name xtspipe_bound \
        -type soft \
        -cells $xtspipe_cells
    puts "  Created soft bound xtspipe_bound: [sizeof_collection $xtspipe_cells] XTSPIPE cells"
} else {
    puts "  Note: XTSPIPE cells not found for xtspipe_bound (check hierarchy)"
}

################################################################################
# Summary
################################################################################

puts ""
puts "================================================================================"
puts "INFO: UMCDAT R2R optimization TCL v3 complete"
puts "================================================================================"
puts ""
puts "  Fixed from v2:"
puts "    - BEQ boundary optimization REMOVED"
puts "      -> v2 caused DFICLK_R2R regression: -31.64 -> -40.63ps (-8.99ps worse)"
puts "    - Added umbrella umc_UCLK_r2r_all group (all non-BEQ regs, weight=7)"
puts "      -> Safety net: catches UCLK_R2R paths if sub-module names mismatch"
puts "    - Added umbrella umc_RDAESR2R_all group (AES pipeline, weight=8)"
puts "      -> RDAESR2R WNS=-64.51ps (worse than UCLK_R2R) had no top-level group"
puts ""
puts "  Added in v3:"
puts "    - compile.flow.high_effort_timing = true (more R2R optimization passes)"
puts "    - XTSAESR2R weight 6->7 (best responder in v2: +6.46ps/3passes)"
puts "    - Soft bound aes_pipeline_bound (RDPIPE+SUBBYTE - wire delay reduction)"
puts "    - Soft bound mixcol_bound (MIXCOL co-location with SUBBYTE)"
puts "    - Soft bound xtspipe_bound (XTSAESR2R physical clustering)"
puts ""
puts "  Path Group Priorities:"
puts "    CRITICAL (weight=8): umc_RDAESR2R_all, umc_RDPIPE_r2r, umc_SUBBYTE_r2r, umc_AES_critical"
puts "    HIGH     (weight=7): umc_UCLK_r2r_all, umc_MIXCOL_r2r, umc_RdDatPipe_r2r, umc_XTSPIPE_r2r"
puts "    MEDIUM   (weight=6): umc_BEQ_r2r, umc_XtsDatPipe_r2r, umc_KEYEXP_r2r, umc_RdKeyPipe_r2r"
puts "    LOW      (weight=5): umc_UMCSEC_r2r"
puts ""
puts "  Expected vs v2 (Mar16 pass3):"
puts "    UCLK_R2R:   -62.65ps -> target <-50ps (umbrella group + high_effort_timing)"
puts "    RDAESR2R:   -64.51ps -> target <-55ps (new umbrella group weight=8)"
puts "    XTSAESR2R:  -28.23ps -> target <-20ps (weight raised 6->7)"
puts "    DFICLK_R2R: -40.63ps -> target <-35ps (BEQ regression fixed)"
puts "================================================================================"
