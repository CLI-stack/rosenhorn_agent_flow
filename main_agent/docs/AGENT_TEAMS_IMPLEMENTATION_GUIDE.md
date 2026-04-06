# Agent Teams Implementation Guide for Genie Agent Flow

## Document Purpose
This is a step-by-step implementation guide for building Agent Teams integration with the existing Rosenhorn/Genie Agent Flow. Provide this document to Claude Code (with Agent Teams enabled) to build the system.

---

## Table of Contents
1. [Current System Overview](#1-current-system-overview)
2. [Target Architecture](#2-target-architecture)
3. [Phase 1: IP Configuration File](#3-phase-1-ip-configuration-file)
4. [Phase 2: Teammate Prompt Templates](#4-phase-2-teammate-prompt-templates)
5. [Phase 3: Self-Debug Templates](#5-phase-3-self-debug-templates)
6. [Phase 4: Integration with Genie CLI](#6-phase-4-integration-with-genie-cli)
7. [Testing Procedures](#7-testing-procedures)

---

## 1. Current System Overview

### 1.1 Directory Structure

```
/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/
├── script/
│   ├── genie_cli.py                    # Main CLI interface
│   └── rtg_oss_feint/
│       ├── umc/                        # UMC IP scripts (25+ files)
│       │   ├── sync_tree.csh
│       │   ├── static_check.csh
│       │   ├── static_check_command.csh
│       │   ├── update_cdc.csh
│       │   └── command/
│       │       ├── run_cdc_rdc.csh     # lsf_bsub + dj command
│       │       ├── run_lint.csh
│       │       └── run_spg_dft.csh
│       ├── oss/                        # OSS IP scripts (copies with variations)
│       │   ├── sync_tree.csh           # Uses bootenv -v orion
│       │   ├── command/
│       │       ├── run_cdc_rdc.csh     # Tile-specific dropflows
│       │       └── run_cdc_rdc_arcadia.csh  # Arcadia variant
│       ├── gmc/                        # GMC IP scripts
│       │   ├── sync_tree.csh           # Uses p4_mkwa -codeline umc4
│       │   └── command/
│       │       └── run_cdc_rdc.csh     # Uses bdji (different tool!)
│       ├── supra/                      # TileBuilder scripts
│       └── static_check_unified.csh    # Router script
├── data/                               # Task data and specs
├── runs/                               # Execution logs
├── config/                             # Configuration files (TO BE CREATED)
└── docs/                               # Documentation
```

### 1.2 Current IP Differences

| Aspect | UMC | OSS | GMC |
|--------|-----|-----|-----|
| **Sync Command** | `p4_mkwa -codeline umc` | `bootenv -v orion` | `p4_mkwa -codeline umc4 -wacfg er` |
| **CDC Tool** | `lsf_bsub ... dj` | `lsf_bsub ... dj -x {bootenv}` | `bdji` |
| **Dropflow** | `:umc_top_drop2cad` | `:osssys_dc_elab` (varies by tile) | `:gmc_cdc` |
| **Tiles** | `umc_top` | `osssys, hdp, sdma0_gc, sdma1_gc` | `gmc_gmcctrl_t, gmc_gmcch_t` |
| **Variants** | None | Arcadia (oss7_2) | None |

### 1.3 Problem Statement

- **75+ duplicated scripts** across 3 IPs
- Adding new IP requires copying entire directory
- Bug fixes must be applied to 3 places
- No automated error analysis or self-healing

---

## 2. Target Architecture

### 2.1 Agent Teams Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GENIE AGENT TEAMS                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         TEAM LEAD                                    │   │
│  │  - Reads IP_CONFIG.yaml for IP-specific knowledge                   │   │
│  │  - Spawns appropriate specialist teammates                          │   │
│  │  - Coordinates self-debug iterations                                │   │
│  │  - Synthesizes final report                                         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│          ┌─────────────────────────┼─────────────────────────┐             │
│          │                         │                         │             │
│          ▼                         ▼                         ▼             │
│   ┌──────────────┐         ┌──────────────┐         ┌──────────────┐      │
│   │   EXECUTOR   │         │   ANALYZER   │         │    FIXER     │      │
│   │              │         │              │         │              │      │
│   │ - Run checks │         │ - Parse rpts │         │ - Gen waiver │      │
│   │ - Monitor    │         │ - Classify   │         │ - Update cfg │      │
│   │ - Collect    │         │   issues     │         │ - Apply fix  │      │
│   │   logs       │         │ - Score      │         │              │      │
│   └──────────────┘         └──────────────┘         └──────────────┘      │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    SHARED RESOURCES                                  │   │
│  │  - IP_CONFIG.yaml (IP-specific commands)                            │   │
│  │  - FIX_TEMPLATES.yaml (waiver patterns)                             │   │
│  │  - HISTORICAL_FIXES.yaml (learned patterns)                         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Self-Debug Flow

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│  Run    │────▶│ Analyze │────▶│ Classify│────▶│ Generate│────▶│  Apply  │
│  Check  │     │ Results │     │ Issues  │     │  Fixes  │     │  Fixes  │
└─────────┘     └─────────┘     └─────────┘     └─────────┘     └────┬────┘
     ▲                                                               │
     │                          ┌─────────┐                          │
     └──────────────────────────│  Rerun  │◀─────────────────────────┘
                                └─────────┘
                                     │
                                     ▼
                               ┌──────────┐
                               │  Done?   │
                               │ Yes/No   │
                               └──────────┘
```

---

## 3. Phase 1: IP Configuration File

### 3.1 Create Directory Structure

```bash
mkdir -p /proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/config
```

### 3.2 Create IP_CONFIG.yaml

**File:** `/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/config/IP_CONFIG.yaml`

```yaml
# =============================================================================
# IP Configuration - Single Source of Truth for All IPs
# =============================================================================
# This file defines all IP-specific commands, paths, and settings.
# Agent Teams reads this to understand how to work with each IP.
# To add a new IP: add a new section following the existing patterns.
# =============================================================================

version: "1.0"
last_updated: "2026-03-16"

# =============================================================================
# UMC IP Family
# =============================================================================
umc:
  description: "UMC Unified Memory Controller IP"

  versions:
    - umc9_2    # Kedar project
    - umc9_3    # Rosenhorn project
    - umc9_6    # Medusadt project
    - umc14_0   # Medusa1 project
    - umc14_2   # Konark project
    - umc17_0   # Grimlock project

  tiles:
    - name: umc_top
      default: true
      dropflow: ":umc_top_drop2cad"

  p4:
    depot: "//depot/umc_ip"
    branch_pattern: "branches/{branch_name}"
    waiver_path: "src/meta/tools/cdc0in/waivers"
    constraint_path: "src/meta/tools/cdc0in/constraints"

  commands:
    sync_tree:
      tool: "p4_mkwa"
      options:
        codeline: "umc"
      example: "p4_mkwa -codeline umc"

    cdc_rdc:
      tool: "lsf_bsub"
      wrapper: "dj"
      project: "rtg-mcip-ver"
      memory: 30000
      queue: "normal"
      rhel_detection: true
      command_template: |
        lsf_bsub -P {project} -R "select[type=={rhel_type}] rusage[mem={memory}]" -q {queue} -I \
        dj -c -v -e 'releaseflow::dropflow({dropflow}).build(:rhea_drop,:rhea_cdc)' \
        -DDROP_TOPS="{tile}" -DRHEA_CDC_OPTS='-CDC_RDC' -l {log_file}
      log_file: "logs/cdc_rdc.log"

    lint:
      tool: "lsf_bsub"
      wrapper: "dj"
      project: "rtg-mcip-ver"
      memory: 30000
      queue: "normal"
      command_template: |
        lsf_bsub -P {project} -R "select[type=={rhel_type}] rusage[mem={memory}]" -q {queue} -I \
        dj -c -v -e 'releaseflow::dropflow({dropflow}).build(:rhea_drop,:rhea_lint)' \
        -DDROP_TOPS="{tile}" -l {log_file}
      log_file: "logs/lint.log"

    spg_dft:
      tool: "lsf_bsub"
      wrapper: "dj"
      project: "rtg-mcip-ver"
      memory: 30000
      queue: "normal"
      command_template: |
        lsf_bsub -P {project} -R "select[type=={rhel_type}] rusage[mem={memory}]" -q {queue} -I \
        dj -c -v -e 'releaseflow::dropflow({dropflow}).build(:rhea_drop,:rhea_spg)' \
        -l {log_file}
      log_file: "logs/spg_dft.log"

  reports:
    cdc:
      path_pattern: "out/linux_*/*/config/*/pub/sim/publish/tiles/tile/{tile}/cad/rhea_cdc/cdc_*_output/cdc_report.rpt"
      extract_script: "cdc_rdc_extract_violation.py"
    rdc:
      path_pattern: "out/linux_*/*/config/*/pub/sim/publish/tiles/tile/{tile}/cad/rhea_cdc/rdc_*_output/rdc_report.rpt"
      extract_script: "cdc_rdc_extract_violation.py"
    lint:
      path_pattern: "out/linux_*/*/config/*/pub/sim/publish/tiles/tile/{tile}/cad/rhea_lint/lint_*_output"
      extract_script: "lint_error_extract.pl"
    spg_dft:
      path_pattern: "out/linux_*/*/config/*/pub/sim/publish/tiles/tile/{tile}/cad/rhea_spg/spg_*_output"
      extract_script: "spg_dft_error_extract.pl"

# =============================================================================
# OSS IP Family
# =============================================================================
oss:
  description: "OSS System IP"

  versions:
    - oss7_2    # Arcadia variant
    - oss8_0    # Orion/Grimlock

  tiles:
    - name: osssys
      dropflow: ":osssys_dc_elab"
      bootenv: "osssys_orion"
    - name: hdp
      dropflow: ":hdp_dc_elab"
      bootenv: "hdp_orion"
    - name: sdma0_gc
      dropflow: ":sdma_dc_elab"
      bootenv: "sdma_orion"
    - name: sdma1_gc
      dropflow: ":sdma_dc_elab"
      bootenv: "sdma_orion"
    - name: lsdma0
      dropflow: ":lsdma_dc_elab"
      bootenv: "lsdma_orion"
    - name: all
      run_all_tiles: true

  variants:
    arcadia:
      applies_to_versions: ["oss7_2"]
      bootenv_override: "arcadia"
      command_suffix: "_arcadia"

  p4:
    depot: "//depot/oss"
    branch_pattern: "branches/{branch_name}"

  commands:
    sync_tree:
      tool: "bootenv"
      options:
        env: "orion"
      example: "bootenv -v orion"
      variant_arcadia:
        env: "arcadia"

    cdc_rdc:
      tool: "lsf_bsub"
      wrapper: "dj"
      requires_bootenv: true
      project: "rtg-mcip-ver"
      memory: 50000
      queue: "normal"
      command_template: |
        bootenv -v {bootenv_project}
        lsf_bsub -P {project} -R "select[type==RHEL7_64] rusage[mem={memory}]" -q {queue} -I \
        dj -c -v -x {bootenv} -e 'releaseflow::dropflow({dropflow}).build(:rhea_drop,:rhea_cdc)' \
        -DDROP_TOPS='{tile}' -l {log_file}
      log_file: "logs/{tile}_cdc_agent.log"

    lint:
      tool: "lsf_bsub"
      wrapper: "dj"
      requires_bootenv: true
      project: "rtg-mcip-ver"
      memory: 50000
      queue: "normal"
      command_template: |
        bootenv -v {bootenv_project}
        lsf_bsub -P {project} -R "select[type==RHEL7_64] rusage[mem={memory}]" -q {queue} -I \
        dj -c -v -x {bootenv} -e 'releaseflow::dropflow({dropflow}).build(:rhea_drop,:rhea_lint)' \
        -DDROP_TOPS='{tile}' -l {log_file}
      log_file: "logs/{tile}_lint.log"

  reports:
    cdc:
      path_pattern: "out/*/cad/rhea_cdc/cdc_*_output/cdc_report.rpt"

# =============================================================================
# GMC IP Family
# =============================================================================
gmc:
  description: "GMC Graphics Memory Controller IP"

  versions:
    - gmc13_1a  # Orion project

  tiles:
    - name: gmc_gmcctrl_t
    - name: gmc_gmcch_t

  p4:
    depot: "//depot/gmc_ip"
    branch_pattern: "branches/{branch_name}"

  commands:
    sync_tree:
      tool: "p4_mkwa"
      options:
        codeline: "umc4"
        wacfg: "er"
      example: "p4_mkwa -codeline umc4 -wacfg er"

    cdc_rdc:
      tool: "bdji"  # Different tool than UMC/OSS!
      job_handler: "lsf"
      command_template: |
        bdji -e 'releaseflow::dropflow(:gmc_cdc).build(:rhea_drop, :rhea_cdc)' \
        -J lsf -l {log_file} \
        -DRHEA_CDC_OPTS='-cdc_yml $STEMS/src/meta/tools/cdc0in/variant/{version}/cdc.yml'
      log_file: "logs/gmc_cdc_rdc.log"

    lint:
      tool: "bdji"
      job_handler: "lsf"
      command_template: |
        bdji -e 'releaseflow::dropflow(:gmc_lint).build(:rhea_drop, :rhea_lint)' \
        -J lsf -l {log_file}
      log_file: "logs/gmc_lint.log"

  reports:
    cdc:
      path_pattern: "out/*/cad/rhea_cdc/cdc_*_output/cdc_report.rpt"
    lint:
      path_pattern: "out/*/cad/rhea_lint/lint_*_output"

# =============================================================================
# RHEL Detection Helper
# =============================================================================
rhel_detection:
  command: "uname -r"
  patterns:
    el8: "RHEL8_64"
    el7: "RHEL7_64"
  default: "RHEL7_64"
```

---

## 4. Phase 2: Teammate Prompt Templates

### 4.1 Create Prompts Directory

```bash
mkdir -p /proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/config/prompts
```

### 4.2 Team Lead Prompt

**File:** `config/prompts/team_lead.md`

```markdown
# Genie Agent Team Lead

You are the Team Lead for the Genie Agent system. You coordinate static checks and supra tasks across multiple IPs (UMC, OSS, GMC).

## Your Responsibilities

1. **Read IP Configuration**: Always read `/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/config/IP_CONFIG.yaml` first to understand IP-specific requirements.

2. **Spawn Appropriate Teammates**:
   - EXECUTOR: For running checks and monitoring
   - ANALYZER: For parsing reports and classifying issues
   - FIXER: For generating waivers and applying fixes

3. **Coordinate Self-Debug Loop**:
   - Track iteration count (max 3)
   - Decide when to apply auto-fixes
   - Request human approval for uncertain fixes
   - Stop when no more progress or max iterations reached

4. **Synthesize Results**: Combine findings from all teammates into final report.

## Available Resources

- IP Config: `config/IP_CONFIG.yaml`
- Fix Templates: `config/FIX_TEMPLATES.yaml`
- Historical Fixes: `config/HISTORICAL_FIXES.yaml`
- Scripts: `script/rtg_oss_feint/{ip}/`

## When User Requests a Check

1. Parse the request to identify:
   - IP family (umc, oss, gmc)
   - IP version (umc17_0, oss8_0, etc.)
   - Check type (cdc_rdc, lint, spg_dft)
   - Tree/directory path
   - Self-debug enabled? (default: yes)

2. Read IP_CONFIG.yaml to get:
   - Correct command for this IP
   - Report paths
   - Tile names

3. Spawn teammates with IP-specific context.

4. Monitor progress and coordinate iterations.

5. Generate final summary report.
```

### 4.3 Executor Teammate Prompt

**File:** `config/prompts/executor.md`

```markdown
# Executor Teammate

You execute static checks and monitor their completion.

## Your Responsibilities

1. **Execute Commands**: Run the check command provided by the Team Lead.
2. **Monitor Progress**: Watch log files for completion or errors.
3. **Collect Results**: Gather output files and report paths.
4. **Report to Lead**: Send status updates and final results.

## Execution Steps

1. Receive command and parameters from Lead
2. Navigate to tree directory
3. Execute the check command
4. Monitor log file for completion indicators:
   - "completed" or "finished" = success
   - "error" or "failed" = failure
5. Locate report files using path patterns from IP_CONFIG
6. Report completion status and report paths to Lead

## Example Commands by IP

### UMC CDC/RDC
```bash
cd {tree_dir}
lsf_bsub -P rtg-mcip-ver -R "select[type==RHEL8_64] rusage[mem=30000]" -q normal -I \
  dj -c -v -e 'releaseflow::dropflow(:umc_top_drop2cad).build(:rhea_drop,:rhea_cdc)' \
  -DDROP_TOPS="umc_top" -DRHEA_CDC_OPTS='-CDC_RDC' -l logs/cdc_rdc.log
```

### OSS CDC/RDC
```bash
cd {tree_dir}
bootenv -v orion
lsf_bsub -P rtg-mcip-ver -R "select[type==RHEL7_64] rusage[mem=50000]" -q normal -I \
  dj -c -v -x osssys_orion -e 'releaseflow::dropflow(:osssys_dc_elab).build(:rhea_drop,:rhea_cdc)' \
  -DDROP_TOPS='osssys' -l logs/osssys_cdc_agent.log
```

### GMC CDC/RDC
```bash
cd {tree_dir}
bdji -e 'releaseflow::dropflow(:gmc_cdc).build(:rhea_drop, :rhea_cdc)' \
  -J lsf -l logs/gmc_cdc_rdc.log \
  -DRHEA_CDC_OPTS='-cdc_yml $STEMS/src/meta/tools/cdc0in/variant/gmc13_1a/cdc.yml'
```
```

### 4.4 Analyzer Teammate Prompt

**File:** `config/prompts/analyzer.md`

```markdown
# Analyzer Teammate

You parse check reports and classify issues.

## Your Responsibilities

1. **Parse Reports**: Read CDC/RDC/lint/SPG_DFT reports
2. **Extract Metrics**: Count violations, warnings, errors
3. **Classify Issues**: Determine which are auto-fixable
4. **Report Findings**: Send classification to Lead

## CDC/RDC Report Parsing

### Report Location
Path pattern from IP_CONFIG, e.g.:
`out/linux_*/*/config/*/pub/sim/publish/tiles/tile/{tile}/cad/rhea_cdc/cdc_*_output/cdc_report.rpt`

### Key Sections to Parse

1. **Summary Section** (around line 8750+):
```
Violations (9138)
-----------------------------------------------------------------
Single-bit signal does not have proper synchronizer.         (6043)
Asynchronous reset does not have proper synchronization.     (2)
Multiple-bit signal across clock domain boundary.            (3091)
```

2. **Extract violation IDs** from detail sections:
   - Pattern: `(ID:no_sync_12345)`
   - Pattern: `(ID:multi_bits_67890)`
   - Pattern: `(ID:async_reset_no_sync_11111)`

## Issue Classification

### Auto-Fixable (HIGH confidence)
- `no_sync` on signals matching: `*Cfg*`, `*Reg*`, `*Control*`, `*Static*`
- `async_reset_no_sync` with recognized sync cell in path
- Violations matching historical fix patterns

### Needs Verification (MEDIUM confidence)
- `multi_bits` on potential gray-coded buses
- Inferred clocks that might need SDC constraints

### Needs Human Review (LOW confidence)
- `no_sync` on datapath signals
- `multi_bits` without clear encoding
- Any violation not matching known patterns

## Output Format

Report to Lead:
```
ANALYSIS COMPLETE
=================
Total Violations: 9138
- no_sync: 6043
- multi_bits: 3091
- async_reset_no_sync: 2
- other: 2

Classification:
- AUTO-FIXABLE (HIGH): 3600
- VERIFY FIRST (MEDIUM): 500
- HUMAN REVIEW (LOW): 5038

Inferred Clocks: 10
Blackboxes: 3
```
```

### 4.5 Fixer Teammate Prompt

**File:** `config/prompts/fixer.md`

```markdown
# Fixer Teammate

You generate fixes (waivers, constraints) for classified issues.

## Your Responsibilities

1. **Generate Waivers**: Create waiver commands for auto-fixable issues
2. **Generate Constraints**: Create SDC/netlist constraints as needed
3. **Apply Fixes**: Add waivers to appropriate files
4. **Track Changes**: Document all modifications

## Waiver Generation

### CDC Waiver Format
```tcl
# Auto-generated waiver - {date}
# Pattern: {pattern_name}
# Confidence: {confidence}
cdc report crossing -from {start_signal} -to {end_signal} \
  -comment "{justification}" \
  -status waived
```

### CDC Waiver by Type

#### Static Configuration Register (no_sync)
```tcl
cdc report crossing -id {violation_id} \
  -comment "Static configuration register, written once during initialization" \
  -status waived
```

#### Reset Synchronizer (async_reset_no_sync)
```tcl
cdc report crossing -id {violation_id} \
  -comment "Reset properly synchronized through {sync_cell_name}" \
  -status waived
```

#### Gray-Coded Bus (multi_bits)
```tcl
netlist port {bus_name} -clock_domain {clock} \
  -comment "Gray coded bus, single bit change per cycle"
```

### Lint Waiver Format
```
error: {rule_code}
filename: {file_path}
line: {line_number}
code: {violation_code}
msg: {waiver_message}
reason: {justification}
author: genie_agent_auto
```

## File Locations

### CDC Waivers
- UMC: `{tree}/src/meta/tools/cdc0in/waivers/auto_waivers.tcl`
- OSS: `{tree}/src/meta/tools/cdc0in/waivers/auto_waivers.tcl`
- GMC: `{tree}/src/meta/tools/cdc0in/waivers/auto_waivers.tcl`

### Lint Waivers
- Path: `{tree}/src/meta/tools/lint/waivers/auto_waivers.txt`

## Output Format

Report to Lead:
```
FIXES GENERATED
===============
Waivers Created: 3600
- Static config: 2100
- Reset sync: 2
- Historical match: 1498

Constraints Created: 10
- Clock declarations: 10

Files Modified:
- src/meta/tools/cdc0in/waivers/auto_waivers.tcl (NEW)

Ready for rerun: YES
```
```

---

## 5. Phase 3: Self-Debug Templates

### 5.1 Fix Templates

**File:** `config/FIX_TEMPLATES.yaml`

```yaml
# =============================================================================
# Fix Templates - Patterns for Auto-Generating Waivers
# =============================================================================

version: "1.0"

cdc_waiver_patterns:

  # ---------------------------------------------------------------------------
  # Static Configuration Registers
  # ---------------------------------------------------------------------------
  static_config_register:
    description: "Static configuration register, written once"
    match:
      violation_type: "no_sync"
      signal_patterns:
        - ".*[Cc]fg.*"
        - ".*[Rr]eg[A-Z].*"
        - ".*[Cc]ontrol[A-Z].*"
        - ".*[Ss]tatic.*"
        - ".*[Mm]ode[Ss]el.*"
    exclude_patterns:
      - ".*[Dd]ata.*"
      - ".*[Ff]ifo.*"
    confidence: "HIGH"
    auto_apply: true
    waiver_template: |
      cdc report crossing -id {violation_id} \
        -comment "Static config register - written once during init, no timing requirement" \
        -status waived

  # ---------------------------------------------------------------------------
  # Reset Synchronizers
  # ---------------------------------------------------------------------------
  reset_synchronizer:
    description: "Reset signal through synchronizer cell"
    match:
      violation_type: "async_reset_no_sync"
      path_contains:
        - "sync"
        - "SYNC"
        - "hdsync"
    confidence: "HIGH"
    auto_apply: true
    waiver_template: |
      cdc report crossing -id {violation_id} \
        -comment "Reset properly synchronized through sync cell" \
        -status waived

  # ---------------------------------------------------------------------------
  # Gray-Coded Pointers
  # ---------------------------------------------------------------------------
  gray_coded_pointer:
    description: "Gray-coded FIFO pointer"
    match:
      violation_type: "multi_bits"
      signal_patterns:
        - ".*[Gg]ray.*[Pp]tr.*"
        - ".*[Pp]tr.*[Gg]ray.*"
        - ".*_gc_.*"
        - ".*_gptr.*"
    confidence: "MEDIUM"
    auto_apply: false  # Needs verification
    constraint_template: |
      netlist port {signal_name} -clock_domain {dest_clock} \
        -comment "Gray coded pointer - 1 bit change per cycle"

  # ---------------------------------------------------------------------------
  # DFT/Scan Signals
  # ---------------------------------------------------------------------------
  dft_scan_signal:
    description: "DFT/Scan signal - used during test mode only"
    match:
      violation_type: "no_sync"
      signal_patterns:
        - ".*[Ss]can.*"
        - ".*[Dd]ft.*"
        - ".*[Tt]est[Mm]ode.*"
        - ".*[Bb]ist.*"
    confidence: "HIGH"
    auto_apply: true
    waiver_template: |
      cdc report crossing -id {violation_id} \
        -comment "DFT signal - active only in test mode, not functional path" \
        -status waived

  # ---------------------------------------------------------------------------
  # RSMU Signals (UMC-specific)
  # ---------------------------------------------------------------------------
  rsmu_signal:
    description: "RSMU control signal"
    match:
      violation_type: "no_sync"
      signal_patterns:
        - ".*rsmu.*"
        - ".*RSMU.*"
    confidence: "MEDIUM"
    auto_apply: false
    waiver_template: |
      cdc report crossing -id {violation_id} \
        -comment "RSMU control signal - verify with RSMU team" \
        -status waived

lint_waiver_patterns:

  # ---------------------------------------------------------------------------
  # Unused DFT Signals
  # ---------------------------------------------------------------------------
  unused_dft:
    description: "Unused DFT/scan signal"
    match:
      rule_codes: ["W287", "W240"]
      signal_patterns:
        - ".*[Ss]can.*"
        - ".*[Dd]ft.*"
    confidence: "HIGH"
    auto_apply: true
    waiver_template: |
      error: {rule_code}
      filename: {file}
      line: .*
      code: unused.*{signal}
      msg: DFT signal - connected during scan insertion
      reason: Signal used for DFT purposes
      author: genie_agent_auto

  # ---------------------------------------------------------------------------
  # Intentional Width Truncation
  # ---------------------------------------------------------------------------
  width_truncation:
    description: "Intentional bit truncation"
    match:
      rule_codes: ["W116", "W164"]
      context_contains: "[\\d+:0]"  # Explicit bit select
    confidence: "MEDIUM"
    auto_apply: false
    waiver_template: |
      error: {rule_code}
      filename: {file}
      line: {line}
      msg: Intentional truncation
      reason: Upper bits explicitly not needed
      author: genie_agent_auto
```

### 5.2 Historical Fixes Database

**File:** `config/HISTORICAL_FIXES.yaml`

```yaml
# =============================================================================
# Historical Fixes - Patterns Learned from Previous Successful Fixes
# =============================================================================
# This file is auto-updated when fixes are applied successfully.
# Agent Teams uses this to recognize similar patterns in future runs.
# =============================================================================

version: "1.0"
last_updated: "2026-03-16"

successful_fixes: []
# Format:
# - id: "fix_001"
#   date: "2026-03-16"
#   ip: "umc17_0"
#   tree: "/proj/xxx"
#   violation_type: "no_sync"
#   violation_id: "no_sync_12345"
#   signal_pattern: "rsmu_sms_fuse_next_addr"
#   fix_type: "waiver"
#   fix_applied: "cdc report crossing -id no_sync_12345 -status waived"
#   result: "success"
#   reusable: true
#   reuse_pattern: "rsmu_sms_fuse_.*"
```

---

## 6. Phase 4: Integration with Genie CLI

### 6.1 Add Agent Teams Mode to genie_cli.py

Add these command-line options to `script/genie_cli.py`:

```python
# Add to argument parser
parser.add_argument('--agent-team', '-at', action='store_true',
                    help='Use Agent Teams mode for parallel execution')
parser.add_argument('--self-debug', '-sd', action='store_true',
                    help='Enable self-debug loop (auto-fix violations)')
parser.add_argument('--max-iterations', type=int, default=3,
                    help='Maximum self-debug iterations (default: 3)')
parser.add_argument('--auto-fix-confidence', choices=['high', 'medium', 'all'],
                    default='high', help='Auto-apply fixes at this confidence level')
```

### 6.2 Example Usage

```bash
# Standard mode (current behavior)
python3 script/genie_cli.py -i "run cdc_rdc for umc17_0 at /proj/xxx" --execute

# Agent Teams mode (parallel)
python3 script/genie_cli.py -i "run cdc_rdc for umc17_0 at /proj/xxx" --execute --agent-team

# Agent Teams with self-debug
python3 script/genie_cli.py -i "run cdc_rdc for umc17_0 at /proj/xxx" --execute --agent-team --self-debug

# Multi-IP parallel
python3 script/genie_cli.py -i "run cdc_rdc for umc17_0 and gmc13_1a" --execute --agent-team
```

---

## 7. Testing Procedures

### 7.1 Test 1: Basic Agent Team Creation

```
Create an agent team with 2 teammates:
- Teammate 1: Read the IP_CONFIG.yaml at /proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/config/IP_CONFIG.yaml and list all supported IPs
- Teammate 2: Read the FIX_TEMPLATES.yaml and list all waiver patterns

Have them report findings.
```

### 7.2 Test 2: IP-Specific Command Generation

```
Create an agent team to generate CDC/RDC commands:
- Read IP_CONFIG.yaml
- Generate the exact command for:
  1. UMC umc17_0 at /proj/rtg_oss_er_feint2/abinbaba/umc_grimlock_Mar16081153
  2. GMC gmc13_1a at /proj/rtg_oss_er_feint2/abinbaba/gmc_test
- Show the differences between the commands
```

### 7.3 Test 3: Report Analysis

```
Create an agent team with Analyzer teammate:
- Read CDC report at: /proj/rtg_oss_er_feint2/abinbaba/umc_grimlock_Mar16081153/out/linux_4.18.0_64.VCS/umc17_0/config/umc_top_drop2cad/pub/sim/publish/tiles/tile/umc_top/cad/rhea_cdc/cdc_umc_top_output/cdc_report.rpt
- Parse the summary section
- Classify violations by type
- Identify how many match auto-fix patterns from FIX_TEMPLATES.yaml
```

### 7.4 Test 4: Waiver Generation

```
Create an agent team with Fixer teammate:
- Read FIX_TEMPLATES.yaml
- For these sample violations, generate waivers:
  1. no_sync on signal "CfgRegData" (static config)
  2. async_reset_no_sync through "hdsync4msfqxss1us_ULVT" cell
  3. multi_bits on "gray_wr_ptr[3:0]"
- Show the generated waiver commands
```

### 7.5 Test 5: Full Self-Debug Simulation

```
Create an agent team with Lead, Executor, Analyzer, and Fixer:
1. Analyze the existing CDC report (don't run new check)
2. Classify all 9138 violations
3. Generate waivers for HIGH confidence matches
4. Report:
   - How many would be auto-fixed
   - How many need human review
   - Sample waivers generated
```

---

## 8. File Checklist

After implementation, verify these files exist:

```
config/
├── IP_CONFIG.yaml              # ✓ IP-specific commands
├── FIX_TEMPLATES.yaml          # ✓ Waiver patterns
├── HISTORICAL_FIXES.yaml       # ✓ Learned patterns
└── prompts/
    ├── team_lead.md            # ✓ Lead instructions
    ├── executor.md             # ✓ Executor instructions
    ├── analyzer.md             # ✓ Analyzer instructions
    └── fixer.md                # ✓ Fixer instructions
```

---

## 9. Success Criteria

| Metric | Target |
|--------|--------|
| IP config covers all IPs | UMC, OSS, GMC ✓ |
| Commands generate correctly | All 3 IPs ✓ |
| Analyzer parses reports | CDC, lint, SPG_DFT ✓ |
| Fixer generates valid waivers | TCL format ✓ |
| Self-debug reduces violations | >30% auto-fixed |
| Human review only when needed | <60% of violations |

---

## 10. Quick Start Command

After creating all config files, test with:

```
Create an agent team for CDC/RDC analysis with self-debug:

1. Read IP_CONFIG.yaml to understand UMC configuration
2. Spawn 3 teammates: Executor, Analyzer, Fixer
3. Analyzer: Parse the CDC report at /proj/rtg_oss_er_feint2/abinbaba/umc_grimlock_Mar16081153/.../cdc_report.rpt
4. Analyzer: Classify violations using FIX_TEMPLATES.yaml patterns
5. Fixer: Generate waivers for HIGH confidence matches
6. Report summary with counts and sample waivers

Max iterations: 1 (analysis only, no rerun)
```

---

**Document Version:** 1.0
**Last Updated:** 2026-03-16
**Author:** Claude Code Planning Session
