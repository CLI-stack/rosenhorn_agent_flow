# Agent Teams for IP Flexibility - Detailed Plan

## Document Information
- **Created**: 2026-03-16
- **Author**: Claude Code Analysis
- **Status**: Planning Phase
- **Focus**: Reducing IP-specific script maintenance through Agent Teams

---

## 1. Current Problem Analysis

### 1.1 Current State: IP-Specific Scripts

You have **3 IPs** (UMC, OSS, GMC) with **duplicated scripts** in separate directories:

```
script/rtg_oss_feint/
├── umc/                    # UMC-specific scripts
│   ├── sync_tree.csh       # 264 lines
│   ├── static_check.csh
│   ├── static_check_command.csh
│   ├── static_check_analysis.csh
│   ├── static_check_summary.csh
│   ├── update_cdc.csh
│   ├── update_lint.csh
│   ├── command/
│   │   ├── run_cdc_rdc.csh      # lsf_bsub with dj command
│   │   ├── run_lint.csh
│   │   └── run_spg_dft.csh
│   └── ... (25+ files)
│
├── oss/                    # OSS-specific scripts (copies with variations)
│   ├── sync_tree.csh       # Similar but OSS-specific
│   ├── static_check.csh
│   ├── command/
│   │   ├── run_cdc_rdc.csh      # bootenv -v orion, tile-specific
│   │   ├── run_cdc_rdc_arcadia.csh  # Arcadia variant!
│   │   └── run_lint_arcadia.csh
│   └── ... (25+ files)
│
├── gmc/                    # GMC-specific scripts (more copies)
│   ├── sync_tree.csh       # GMC-specific (p4_mkwa -codeline umc4)
│   ├── static_check.csh
│   ├── command/
│   │   └── run_cdc_rdc.csh      # bdji command (different!)
│   └── ... (25+ files)
│
└── static_check_unified.csh  # Router (just detects IP and calls correct dir)
```

### 1.2 Key Differences Between IPs

| Aspect | UMC | OSS | GMC |
|--------|-----|-----|-----|
| **P4 sync** | p4_mkwa -codeline umc | bootenv -v orion | p4_mkwa -codeline umc4 -wacfg er |
| **CDC/RDC command** | `lsf_bsub ... dj -e 'releaseflow::dropflow(:umc_top_drop2cad)'` | `lsf_bsub ... dj -x osssys_orion` (tile-specific) | `bdji -e 'releaseflow::dropflow(:gmc_cdc)'` |
| **Dropflow target** | `:umc_top_drop2cad` | `:osssys_dc_elab`, `:hdp_dc_elab` (varies by tile) | `:gmc_cdc` |
| **CDC yaml** | Not specified | Not specified | `-cdc_yml $STEMS/src/meta/tools/cdc0in/variant/gmc13_1a/cdc.yml` |
| **Tiles** | `umc_top` | `osssys`, `hdp`, `sdma0_gc`, `sdma1_gc`, `lsdma0`, `all` | `gmc_gmcctrl_t`, `gmc_gmcch_t` |
| **Report paths** | `out/linux_*/*/config/*/pub/sim/publish/tiles/tile/umc_top/cad/rhea_cdc/` | Different structure | Different structure |
| **Waiver files** | P4: `//depot/umc_ip/...` | P4: `//depot/oss/...` | P4: `//depot/gmc/...` |

### 1.3 Maintenance Burden

When you need to:
1. **Fix a bug** → Must update 3 copies (umc/, oss/, gmc/)
2. **Add new check type** → Create scripts in all 3 directories
3. **Add new IP** → Copy entire directory, modify all scripts
4. **Change report parsing** → Update extract scripts in all dirs

**Total duplicated files: ~75 files** (25 per IP × 3 IPs)

---

## 2. Solution Options

### Option A: Continue Current Approach
- Keep IP-specific directories
- Use `static_check_unified.csh` as router
- **Pros**: Works today, simple routing
- **Cons**: 3x maintenance, bug fixing in 3 places, inconsistencies

### Option B: Parameterized Scripts (Traditional)
- Single script with IP config file
- Config file defines commands per IP
- **Pros**: Single script to maintain
- **Cons**: Complex config parsing in CSH, hard to debug

### Option C: Agent Teams with IP Knowledge (Proposed)
- Agent Teams with IP-aware teammates
- Each teammate understands their IP's specifics
- Natural language flexibility for new IPs
- **Pros**: Flexible, self-documenting, easy to extend
- **Cons**: Token cost, experimental feature

---

## 3. Proposed Solution: Agent Teams with IP Configuration

### 3.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    AGENT TEAMS - IP FLEXIBLE ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    TEAM LEAD (Claude Code)                           │   │
│  │  - Receives: "run cdc_rdc for gmc13_1a at /proj/xxx"                │   │
│  │  - Reads: IP_CONFIG.yaml to understand IP requirements              │   │
│  │  - Spawns: IP-specific teammate with correct context                │   │
│  │  - Synthesizes: Results from all teammates                          │   │
│  └──────────────────────────────┬──────────────────────────────────────┘   │
│                                 │                                           │
│         ┌───────────────────────┼───────────────────────────────────────┐  │
│         │                       │                                       │  │
│         ▼                       ▼                                       ▼  │
│  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐       │
│  │  UMC Specialist  │   │  OSS Specialist  │   │  GMC Specialist  │       │
│  │  Teammate        │   │  Teammate        │   │  Teammate        │       │
│  │                  │   │                  │   │                  │       │
│  │  Knows:          │   │  Knows:          │   │  Knows:          │       │
│  │  - dj command    │   │  - bootenv orion │   │  - bdji command  │       │
│  │  - dropflow      │   │  - tile variants │   │  - cdc.yml path  │       │
│  │  - report paths  │   │  - arcadia mode  │   │  - report paths  │       │
│  └──────────────────┘   └──────────────────┘   └──────────────────┘       │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    IP_CONFIG.yaml (Single Source of Truth)           │   │
│  │  - All IP-specific commands and paths defined here                  │   │
│  │  - Read by Agent Teams to generate correct commands                 │   │
│  │  - Easy to add new IP: just add YAML section                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 IP Configuration File

Create a single YAML configuration that defines ALL IP-specific details:

**`/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/config/IP_CONFIG.yaml`**

```yaml
# IP Configuration - Single Source of Truth
# Add new IPs here, Agent Teams will automatically understand them

ips:
  # ============================================================
  # UMC IP Family
  # ============================================================
  umc:
    description: "UMC Memory Controller IP"
    versions:
      - umc9_2
      - umc9_3
      - umc9_6
      - umc14_0
      - umc14_2
      - umc17_0

    tiles:
      - name: umc_top
        default: true

    p4:
      depot: "//depot/umc_ip"
      branch_pattern: "branches/{branch_name}"
      waiver_path: "src/meta/tools/cdc0in"
      constraint_path: "src/meta/tools/cdc0in"

    commands:
      sync_tree:
        type: "p4_mkwa"
        codeline: "umc"
        options: ""

      cdc_rdc:
        type: "lsf_bsub"
        project: "rtg-mcip-ver"
        memory: 30000
        queue: "normal"
        command: "dj -c -v -e 'releaseflow::dropflow(:umc_top_drop2cad).build(:rhea_drop,:rhea_cdc)'"
        options:
          DROP_TOPS: "umc_top"
          RHEA_CDC_OPTS: "-CDC_RDC"
        log: "logs/cdc_rdc.log"

      lint:
        type: "lsf_bsub"
        project: "rtg-mcip-ver"
        memory: 30000
        queue: "normal"
        command: "dj -c -v -e 'releaseflow::dropflow(:umc_top_drop2cad).build(:rhea_drop,:rhea_lint)'"
        options:
          DROP_TOPS: "umc_top"
        log: "logs/lint.log"

      spg_dft:
        type: "lsf_bsub"
        project: "rtg-mcip-ver"
        memory: 30000
        queue: "normal"
        command: "dj -c -v -e 'releaseflow::dropflow(:umc_top_drop2cad).build(:rhea_drop,:rhea_spg)'"
        log: "logs/spg_dft.log"

    reports:
      cdc:
        path_pattern: "out/linux_*/*/config/*/pub/sim/publish/tiles/tile/umc_top/cad/rhea_cdc/cdc_*_output/cdc_report.rpt"
      rdc:
        path_pattern: "out/linux_*/*/config/*/pub/sim/publish/tiles/tile/umc_top/cad/rhea_cdc/rdc_*_output/rdc_report.rpt"
      lint:
        path_pattern: "out/linux_*/*/config/*/pub/sim/publish/tiles/tile/umc_top/cad/rhea_lint/lint_*_output"

    extract_scripts:
      cdc_rdc: "cdc_rdc_extract_violation.py"
      lint: "lint_error_extract.pl"
      spg_dft: "spg_dft_error_extract.pl"

  # ============================================================
  # OSS IP Family
  # ============================================================
  oss:
    description: "OSS System IP"
    versions:
      - oss7_2  # Arcadia variant
      - oss8_0

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
        run_all: true

    variants:
      arcadia:
        applies_to: ["oss7_2"]
        command_suffix: "_arcadia"
        bootenv: "arcadia"

    p4:
      depot: "//depot/oss"
      branch_pattern: "branches/{branch_name}"

    commands:
      sync_tree:
        type: "bootenv"
        env: "orion"
        # Arcadia variant uses different bootenv

      cdc_rdc:
        type: "lsf_bsub"
        project: "rtg-mcip-ver"
        memory: 50000
        queue: "normal"
        requires_bootenv: true
        command_template: "dj -c -v -x {bootenv} -e 'releaseflow::dropflow({dropflow}).build(:rhea_drop,:rhea_cdc)'"
        options:
          DROP_TOPS: "{tile_name}"
        log: "logs/{tile_name}_cdc_agent.log"

      lint:
        type: "lsf_bsub"
        project: "rtg-mcip-ver"
        memory: 50000
        queue: "normal"
        requires_bootenv: true
        command_template: "dj -c -v -x {bootenv} -e 'releaseflow::dropflow({dropflow}).build(:rhea_drop,:rhea_lint)'"

    reports:
      cdc:
        path_pattern: "out/*/cad/rhea_cdc/cdc_*_output/cdc_report.rpt"

  # ============================================================
  # GMC IP Family
  # ============================================================
  gmc:
    description: "GMC Graphics Memory Controller IP"
    versions:
      - gmc13_1a

    tiles:
      - name: gmc_gmcctrl_t
      - name: gmc_gmcch_t

    p4:
      depot: "//depot/gmc_ip"
      branch_pattern: "branches/{branch_name}"

    commands:
      sync_tree:
        type: "p4_mkwa"
        codeline: "umc4"
        wacfg: "er"

      cdc_rdc:
        type: "bdji"  # Different tool!
        command: "bdji -e 'releaseflow::dropflow(:gmc_cdc).build(:rhea_drop, :rhea_cdc)'"
        job_handler: "lsf"
        options:
          RHEA_CDC_OPTS: "-cdc_yml $STEMS/src/meta/tools/cdc0in/variant/gmc13_1a/cdc.yml"
        log: "logs/gmc_cdc_rdc.log"

      lint:
        type: "bdji"
        command: "bdji -e 'releaseflow::dropflow(:gmc_lint).build(:rhea_drop, :rhea_lint)'"
        job_handler: "lsf"
        log: "logs/gmc_lint.log"

    reports:
      cdc:
        path_pattern: "out/*/cad/rhea_cdc/cdc_*_output/cdc_report.rpt"
      lint:
        path_pattern: "out/*/cad/rhea_lint/lint_*_output"
```

### 3.3 How Agent Teams Uses This Config

**Scenario: User requests CDC/RDC for new IP**

```
User: "Run cdc_rdc for gmc13_1a at /proj/rtg_oss_er_feint2/abinbaba/gmc_tree"

TEAM LEAD:
1. Read IP_CONFIG.yaml
2. Find gmc13_1a → gmc IP family
3. Get cdc_rdc command config:
   - type: bdji
   - command: "bdji -e 'releaseflow::dropflow(:gmc_cdc)...'"
4. Spawn teammate with context:
   "You are working on GMC IP. Use bdji command, not lsf_bsub.
    The cdc.yml is at $STEMS/src/meta/tools/cdc0in/variant/gmc13_1a/cdc.yml"

GMC SPECIALIST TEAMMATE:
1. cd to /proj/rtg_oss_er_feint2/abinbaba/gmc_tree
2. Execute: bdji -e 'releaseflow::dropflow(:gmc_cdc).build(:rhea_drop, :rhea_cdc)' \
            -J lsf -l logs/gmc_cdc_rdc.log \
            -DRHEA_CDC_OPTS='-cdc_yml $STEMS/src/meta/tools/cdc0in/variant/gmc13_1a/cdc.yml'
3. Monitor completion
4. Parse reports using path pattern from config
5. Report results to lead
```

### 3.4 Benefits of This Approach

| Benefit | Description |
|---------|-------------|
| **Single Source of Truth** | All IP configs in one YAML file |
| **Easy to Add New IP** | Just add YAML section, no script copies |
| **Self-Documenting** | YAML is readable, explains differences |
| **Flexible Parsing** | Agent can read YAML and generate commands |
| **No CSH Parsing Complexity** | Agent understands structure natively |
| **Variant Handling** | Arcadia vs non-Arcadia defined in config |
| **Easy Updates** | Change YAML, all IPs updated |

---

## 4. Implementation Phases

### Phase 1: Create IP Configuration (Week 1)

**Tasks:**
1. Create `config/IP_CONFIG.yaml` with all current IP details
2. Document all existing commands, paths, and variations
3. Validate config against current scripts

**Deliverable:** Complete IP_CONFIG.yaml

### Phase 2: Create Agent Team Prompts (Week 2)

**Tasks:**
1. Create lead agent prompt that reads IP_CONFIG.yaml
2. Create IP-specialist teammate prompt template
3. Test with single IP (UMC)

**Lead Agent Prompt:**
```
You are the Genie Agent Team Lead. When a user requests a static check:
1. Read /config/IP_CONFIG.yaml to understand IP-specific requirements
2. Identify the IP family from the request (umc, oss, gmc)
3. Spawn an IP-specialist teammate with the correct configuration
4. Monitor progress and synthesize results

For each IP, provide the teammate with:
- Exact commands to run (from config)
- Report paths to check (from config)
- Any special options (like cdc.yml for GMC)
```

**IP Specialist Prompt Template:**
```
You are an {ip_name} IP Specialist. Your configuration:

Commands:
{formatted_commands_from_yaml}

Report Paths:
{formatted_paths_from_yaml}

Execute the requested check type and report results.
```

### Phase 3: Parallel Check Execution (Week 3-4)

**Tasks:**
1. Enable multi-tile parallel execution
2. Each tile gets its own teammate
3. Lead coordinates and merges results

**Example:**
```
User: "Run full static check for oss8_0 all tiles"

Lead spawns 4 teammates in parallel:
├── OSS osssys specialist → Run CDC/RDC for osssys
├── OSS hdp specialist → Run CDC/RDC for hdp
├── OSS sdma0_gc specialist → Run CDC/RDC for sdma0_gc
└── OSS sdma1_gc specialist → Run CDC/RDC for sdma1_gc

All run simultaneously, lead merges results
```

### Phase 4: Unified Script Replacement (Week 5-6)

**Tasks:**
1. Create single `run_check.py` that reads IP_CONFIG.yaml
2. Agent Teams calls this unified script
3. Deprecate IP-specific script directories

**New Structure:**
```
script/rtg_oss_feint/
├── config/
│   └── IP_CONFIG.yaml        # Single source of truth
├── common/
│   ├── run_check.py          # Unified check runner
│   ├── extract_results.py    # Unified result extractor
│   └── generate_command.py   # Command generator from config
└── legacy/                    # Old IP-specific scripts (archived)
    ├── umc/
    ├── oss/
    └── gmc/
```

---

## 5. Adding a New IP - Before vs After

### Current Process (Without Agent Teams)

1. Create new directory: `script/rtg_oss_feint/new_ip/`
2. Copy all scripts from existing IP (~25 files)
3. Modify each script for new IP specifics
4. Update `static_check_unified.csh` router
5. Test each script individually
6. Document new IP somewhere

**Effort: 2-3 days, high error risk**

### New Process (With Agent Teams + IP_CONFIG.yaml)

1. Add new section to `IP_CONFIG.yaml`:
```yaml
new_ip:
  description: "New IP Description"
  versions:
    - new_ip_1_0
  tiles:
    - name: new_ip_top
  commands:
    cdc_rdc:
      type: "lsf_bsub"  # or "bdji" etc.
      command: "..."
```

2. Agent Teams automatically understands new IP
3. Test with: "run cdc_rdc for new_ip_1_0 at /proj/xxx"

**Effort: 30 minutes, low error risk**

---

## 6. Comparison Matrix

| Aspect | Current (IP Dirs) | Proposed (Agent Teams + YAML) |
|--------|-------------------|-------------------------------|
| **Files to maintain** | ~75 (25 × 3 IPs) | 1 (IP_CONFIG.yaml) |
| **Add new IP** | Copy 25 files, modify each | Add YAML section |
| **Fix bug** | Update 3+ files | Update 1 file |
| **Command changes** | Find/replace in scripts | Update YAML key |
| **Documentation** | Scattered in scripts | Centralized in YAML |
| **Parallelism** | Manual scripting | Built-in (Agent Teams) |
| **Error handling** | Per-script | Agent can adapt |
| **Token cost** | None | Moderate |
| **Learning curve** | CSH scripting | YAML + Agent prompts |

---

## 7. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| **YAML parsing errors** | Validate YAML schema, use Python yamllint |
| **Agent misunderstands config** | Include examples in YAML comments |
| **Token cost too high** | Use for complex tasks, keep simple CLI for basics |
| **Feature experimental** | Keep legacy scripts as fallback |
| **New team members** | YAML is self-documenting |

---

## 8. Recommended Next Steps

1. **Immediate**: Create IP_CONFIG.yaml draft from existing scripts
2. **Week 1**: Validate config against all current IP operations
3. **Week 2**: Enable Agent Teams, test with read-only operations
4. **Week 3**: Test single IP execution (UMC CDC/RDC)
5. **Week 4**: Test multi-IP parallel execution
6. **Week 5+**: Gradual migration from legacy scripts

---

## 9. Quick Start: Creating IP_CONFIG.yaml

I can help you create the initial IP_CONFIG.yaml by:

1. Extracting all commands from current CSH scripts
2. Identifying differences between IPs
3. Structuring into YAML format
4. Validating completeness

**Would you like me to proceed with creating the IP_CONFIG.yaml?**

---

## Appendix: Current IP Differences Summary

| Command | UMC | OSS | GMC |
|---------|-----|-----|-----|
| **Sync** | `p4_mkwa -codeline umc` | `bootenv -v orion` | `p4_mkwa -codeline umc4 -wacfg er` |
| **CDC** | `lsf_bsub ... dj -e 'releaseflow::dropflow(:umc_top_drop2cad)'` | `lsf_bsub ... dj -x {bootenv} -e 'releaseflow::dropflow({dropflow})'` | `bdji -e 'releaseflow::dropflow(:gmc_cdc)'` |
| **Lint** | Similar to CDC | Per-tile dropflow | `bdji -e 'releaseflow::dropflow(:gmc_lint)'` |
| **SPG_DFT** | `dj ... :rhea_spg` | Per-tile | `bdji ... :rhea_spg` |
| **Reports** | `out/linux_*/*/config/*/pub/sim/publish/tiles/tile/umc_top/cad/rhea_*/` | Varies by tile | `out/*/cad/rhea_*/` |
| **Tiles** | `umc_top` only | `osssys, hdp, sdma0_gc, sdma1_gc, lsdma0, all` | `gmc_gmcctrl_t, gmc_gmcch_t` |
| **Variants** | None | Arcadia (oss7_2) | None |
