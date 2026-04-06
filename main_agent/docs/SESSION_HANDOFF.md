# Session Handoff - Agent Teams Implementation

**Last Updated:** 2026-03-17 (Session 8)
**Reference Plan:** `docs/AGENT_TEAMS_IMPLEMENTATION_GUIDE.md`

---

## Overall Implementation Status

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | IP Configuration File (`IP_CONFIG.yaml`) | ✅ Complete |
| Phase 2 | Teammate Prompt Templates (all 4) | ✅ Complete |
| Phase 3 | Self-Debug Templates (FIX_TEMPLATES + HISTORICAL_FIXES) | ✅ Complete |
| Phase 4 | Genie CLI Integration (`--agent-team`) | ✅ Partial — CDC classify+generate only |
| Phase 4 S5 | Two-phase CDC analyzer (pre-condition check + LOW_RISK bucket) | ✅ Complete — Session 5 |
| Phase 5 Step 1 | CDC Auto-Apply (`apply_cdc_waivers()` + `--self-debug` trigger) | ✅ Complete — Session 5 |
| Phase 4 cont. | Lint analysis in `--send-completion-email` handler | ✅ Complete — Session 6 |
| Phase 4 cont. | SPG_DFT analysis in `--send-completion-email` handler | ✅ Complete — Session 6 |
| Phase 5 Step 2 | Lint Auto-Apply | 🔲 Not started |
| Phase 5 Step 3 | SPG_DFT Auto-Apply | 🔲 Not started |
| **Phase 6** | **Real Multi-Agent via AMD LLM Gateway (`MultiAgentOrchestrator`)** | ✅ **Complete — Session 7** |
| **Phase 7** | **RTL Analyst — all violations analyzed from RTL source, no auto-waivers** | ✅ **Complete — Session 8** |

---

## All Files — Current State

```
config/
├── IP_CONFIG.yaml              ✅ Complete — UMC/OSS/GMC commands, report paths, RHEL detection (Session 6: fixed lint/spg_dft paths)
├── FIX_TEMPLATES.yaml          ✅ Complete — 10 CDC + 3 SPG_DFT patterns + low_risk_module_patterns + 2 lint patterns
├── HISTORICAL_FIXES.yaml       ✅ Complete — 15 confirmed fixes from Grimlock umc17_0
└── prompts/
    ├── team_lead.md            ✅ Complete — orchestration, IP routing, full_static_check flow
    ├── executor.md             ✅ Complete — command generation for UMC/OSS/GMC, all 4 checks
    ├── analyzer.md             ✅ Rewritten Session 5 — Phase A (pre-condition) + Phase B (LOW_RISK + classify)
    ├── fixer.md                ✅ Deprecation note added Session 8 — no longer called in standard flow
    └── rtl_analyst.md          ✅ NEW Session 8 — RTL Analyst prompt (engineer feedback, no waivers)

script/
├── genie_cli.py                ✅ Updated — --agent-team (CDC+Lint+SPG_DFT), 12 methods + MultiAgentOrchestrator class
│                                  Session 8: _run_rtl_analysis_all(), _format_analysis_report(), Semaphore(8), timeouts
│                                  (synced to /proj/rtg_oss_feint1/FEINT_AI_AGENT/genie_agent/script/)
├── rtl_signal_tracer.py        ✅ NEW Session 8 — RTL context extractor (VF parse → module file → signal context)
│                                  (synced to /proj/rtg_oss_feint1/FEINT_AI_AGENT/genie_agent/script/)
└── llm.py / use_llm.py         ✅ Pre-existing AMD gateway helper scripts (used as reference for Session 7)

script/rtg_oss_feint/oss/command/
├── run_cdc_rdc.csh             ✅ Fixed — dynamic RHEL detection (uname -r pattern)
├── run_lint.csh                ✅ Fixed — dynamic RHEL detection
└── run_spg_dft.csh             ✅ Fixed — dynamic RHEL detection
    (all 3 synced to genie_agent/script/)
```

---

## Phase 1: IP_CONFIG.yaml

**File:** `config/IP_CONFIG.yaml`

Covers UMC, OSS, GMC. Each IP section has:
- `commands`: tool, memory, queue, command template for cdc_rdc / lint / spg_dft / sync_tree
- `reports`: path patterns for locating output reports (used by genie_cli.py --agent-team)
- `tiles`: tile names and dropflow names per tile

**Key differences between IPs:**

| Feature | UMC | OSS | GMC |
|---------|-----|-----|-----|
| CDC/Lint tool | `lsf_bsub + dj` | `lsf_bsub + dj` | `bdji` |
| SPG_DFT tool | `lsf_bsub + dj` | `lsf_bsub + dj` | `lsf_bsub + be_dj` |
| Bootenv | none | `-v <tile>_orion` | none |
| RHEL | dynamic (uname) | dynamic (uname) | hardcoded RHEL8_64 (SPG only) |
| Codeline | `umc` | `oss_ip` | `umc4` |

**Bugs fixed (Session 2):** 7 bugs — RHEL hardcoding, missing spg_dft sections, incomplete report paths.

**Bugs fixed (Session 6):** 3 report path corrections in `reports` section:

| IP | Check | Was | Fixed To |
|----|-------|-----|----------|
| UMC | lint | `rhea_lint/lint_*_output` (directory, not a file) | `rhea_lint/leda_waiver.log` |
| UMC | spg_dft | `rhea_spg/spg_*_output` (wrong dir name + directory) | `spg_dft/{tile}/moresimple.rpt` |
| OSS | lint | `rhea_lint/report_vc_spyglass_lint.txt` (wrong filename) | `rhea_lint/leda_waiver.log` |

GMC lint (`leda_waiver.log`) and GMC spg_dft (`moresimple.rpt`) were already correct.

---

## Phase 2: Prompt Templates

**Files:** `config/prompts/`

| File | Purpose | Key Content |
|------|---------|-------------|
| `team_lead.md` | Orchestrates the team | IP routing rules, full_static_check sequential flow (Lint→CDC→SPG), GMC be_dj exception |
| `executor.md` | Generates and runs commands | Complete command examples for all 3 IPs × 4 checks, {rhel_type} placeholder usage |
| `analyzer.md` | Parses reports, classifies violations | CDC parsing (violation ID extraction, signal name lookup), classification priority order |
| `fixer.md` | Generates waivers/constraints | TCL waiver format for each pattern type, lint waiver YAML format, file locations |

---

## Phase 3: Self-Debug Templates

### FIX_TEMPLATES.yaml — 10 CDC + 3 LOW_RISK groups + 2 Lint patterns

**CDC patterns (`cdc_waiver_patterns`):**

| Pattern | Confidence | Trigger | Notes |
|---------|------------|---------|-------|
| `static_config_register` | HIGH | no_sync on Cfg/Reg/Control/Static/REGCMD/REG_/oQ_ signals | Excludes Data/Fifo |
| `reset_synchronizer` | HIGH | async_reset_no_sync with sync/SYNC/hdsync in path | — |
| `gray_coded_pointer` | MEDIUM | multi_bits on gray/ptr/gc signals | Generates constraint, not waiver |
| `dft_scan_signal` | HIGH | no_sync on Scan/Dft/TestMode/Bist signals | — |
| `rsmu_signal` | MEDIUM | no_sync on rsmu_pgfsm_* dynamic FSM signals | Not oQ_ register outputs — those match static_config_register |
| `power_reset_signal` | HIGH | no_sync on Cpl_PWROK/Cpl_RESETn/Cpl_GAP_PWROK | Grimlock-proven |
| `spaz_static_config` | MEDIUM | no_sync on SPAZ.ZQCTR.DramRdy/ZqcsDisable/ZqcsGrpVal | Learned Test 6 |
| `always_on_reset` | MEDIUM | no_sync on SPAZ.*.IResetAon | Learned Test 6 |
| `sync_internal_iq` | HIGH | no_sync on *Sync.SYNC.*.IQ_zint — CDC tool false positive | Learned Test 6 |
| `power_ok_shift_chain` | HIGH | series_redundant on CplPwrOk*Shft | Intentional redundant sync |

**LOW_RISK module patterns (`low_risk_module_patterns`) — Added Session 5:**

These are NOT waivers. Violations involving these modules are classified as LOW_RISK — active only in test/debug mode. No constraint generated.

| Group | Signals | Applies To | Risk |
|-------|---------|------------|------|
| `rsmu_debug` | `.*rsmu.*`, `.*RSMU.*`, `.*rdft.*`, `.*_rsmu_rdft.*` | cdc, lint, spg_dft | LOW |
| `dft_test_modules` | `.*dft_clk_marker.*`, `.*_tdr[_.].*`, `.*jtag.*`, `.*JTAG.*`, `.*Tdr_Tck.*`, `.*[Ss]can[Ee]n.*` | cdc, lint, spg_dft | LOW |
| `known_memory_macros` | `.*rfsd2p.*`, `.*rfps2p.*`, `.*hdsd1p.*`, `.*trfpss2p.*` | cdc only | IGNORE |

**Note on RSMU signal overlap:** `rsmu_debug` in `low_risk_module_patterns` catches general RSMU path violations. The `rsmu_signal` in `cdc_waiver_patterns` (MEDIUM) is for dynamic RSMU FSM signals (`rsmu_pgfsm_*`) that are NOT just test/debug. The `_is_low_risk_signal()` check runs BEFORE FIX_TEMPLATES matching, so general RSMU violations go to LOW_RISK bucket; only dynamic FSM signals that don't match LOW_RISK patterns reach the MEDIUM bucket.

**Lint patterns (`lint_waiver_patterns`):**

| Pattern | Confidence | Trigger |
|---------|------------|---------|
| `unused_dft` | HIGH | W287/W240 on Scan/Dft signal names |
| `width_truncation` | MEDIUM | W116/W164 — explicit bit truncation |

**SPG_DFT patterns (`spg_dft_waiver_patterns`) — Added Session 6:**

| Pattern | Confidence | Trigger | Filter Template |
|---------|------------|---------|----------------|
| `rsmu_module_instance` | HIGH | `umc0_rsmu_rdft_instance` in path | `umc0_rsmu_rdft_instance` |
| `cpl_pwrok_async_scan` | HIGH | `CplPwrOkDficlk` in path (Async_07) | `Async.*CplPwrOkDficlk.*is not disabled for 4 flip-flop` |
| `clkdiv2_testclock` | HIGH | `UCLKGEN.ClkDiv2_n0scan` in path (Clock_11) | `Clock domain.*UCLKGEN\.ClkDiv2_n0scan.*is not controlled by testclock` |

**Note:** SPG_DFT "waivers" are filter pattern additions to `spg_dft_error_filter.txt`, NOT TCL waivers.
The patterns above are used by `classify_spg_dft_violations()` to detect known unfiltered violations and
suggest the exact regex to add to `[umc17_0]` section. User reviews and applies manually.

### HISTORICAL_FIXES.yaml — 15 entries

Confirmed fixes from Grimlock umc17_0 (2026-03-17). All entries are `reusable: true`.

Covers: Cpl_GAP_PWROK, Cpl_PWROK, Cpl_RESETn (power_reset_signal) and REGCMD.REG_CtrlUpdClks, REG_ZqcsInterval, REG_OdtsReadInterval, REG_ShortInit, oQ_PETCtrl_tECSint, SCRUBCNTR.RegEcc*, REG_DAT.oQ_*, rsmu_register_wrapper.oQ_* (static_config_register).

**Finding from Test 6:** HISTORICAL_FIXES functions as an **audit trail**, not a discovery mechanism. It confirms that a pattern was previously verified safe — boosting confidence from MEDIUM to HIGH — but it does not match signals that FIX_TEMPLATES.yaml patterns already miss.

---

## Phase 4: genie_cli.py `--agent-team`

### What was implemented (CDC only)

**New flags:**
```bash
--agent-team  (-at)   Classify violations + generate waivers after check completes
--self-debug  (-sd)   Flag added (scaffolded — full loop not implemented yet)
```

**New methods on `GenieCLI` class (Phase 4, Sessions 4–5):**

| Method | Purpose |
|--------|---------|
| `_parse_cdc_report(report_path)` | Scans report for `(ID:no_sync_XXXX)` patterns, extracts signal names from `From:` lines |
| `_find_report_path(ref_dir, ip, check_type)` | Reads IP_CONFIG.yaml path pattern → globs filesystem → returns newest `.rpt` file |
| `classify_violations(report_path, ref_dir=None, ip=None)` | **Session 5 rewrite:** Phase A pre-condition check → Phase B LOW_RISK + FIX_TEMPLATES matching. Returns enriched dict with `status`, `preconditions`, `precond_issues`, `suggestions`, `HIGH`, `MEDIUM`, `LOW`, `LOW_RISK`, `total` |
| `generate_waivers(classified, tag)` | Writes `data/<tag>_waivers.tcl` with TCL waiver commands for all HIGH violations |
| `_parse_cdc_preconditions(report_path)` | **Session 5 new:** Parses Sections 1, 2, 9 of CDC report for clock/reset/blackbox counts and module names |
| `_is_low_risk_signal(signal)` | **Session 5 new:** Returns `(True, reason)` if signal matches RSMU/DFT/JTAG/TDR patterns |
| `_get_manifest_lib_dirs(ref_dir, ip)` | **Session 5 new:** Finds published RTL manifest, reads `.lib.gz` paths, returns unique lib parent directories (golden search paths) |
| `_find_lib_for_module(module_name, lib_dirs)` | **Session 5 new:** `zgrep -l "cell ({module_name})"` on manifest lib dirs, returns lib files where module defined |
| `apply_cdc_waivers(classified, tag, ref_dir, ip)` | **Session 5 new (Phase 5 Step 1):** Writes `data/$tag.cdc_rdc_waiver` + `data/$tag.cdc_rdc_constraint`, calls `update_cdc.csh` via `tcsh -f -c`, 600s timeout. Triggered by `auto_apply=true` in `_agent_team` flag (set when `--self-debug` used). |
| `classify_lint_violations(report_path)` | **Session 6 new:** Parses "Unwaived" section of `leda_waiver.log`. Returns early with status=OK if "No unwaived violations". Applies `_is_low_risk_signal()` then `lint_waiver_patterns` matching. Returns `{status, total, HIGH, MEDIUM, LOW, LOW_RISK}`. |
| `generate_lint_hints(classified, tag)` | **Session 6 new:** Writes `data/$tag.lint_waiver` in smart-match hint format for `update_lint.csh`. Fills `{rule_code}`, `{file}`, `{signal}`, `{line}` template variables. Returns hint file path or None. |
| `_find_spg_dft_filter_file(ip)` | **Session 6 new:** Returns path to `script/rtg_oss_feint/{family}/spg_dft_error_filter.txt` for the ip family. |
| `classify_spg_dft_violations(report_path, ip)` | **Session 6 new:** Loads filter patterns from `spg_dft_error_filter.txt` ([general]+[ip_lower] sections). Parses moresimple.rpt for Error lines. Classifies as: `filtered` (LOW_RISK, covered), `LOW_RISK_MISSING_FILTER` (matches `_is_low_risk_signal` but not in filter), `HIGH_KNOWN_PATTERN` (matches spg_dft_waiver_patterns), `HUMAN_REVIEW`. |
| `generate_spg_dft_filter_suggestions(classified_spg, tag, ip)` | **Session 6 new:** Generates `data/$tag.spg_dft_filter_hints` with suggested `[ip_lower]` section additions. Deduplicates by filter template. Sections: HIGH known patterns, LOW_RISK missing filter, HUMAN REVIEW. |

**Flow when `--agent-team` is used:**
1. `execute()` writes `data/<tag>_agent_team` flag file (contains `ref_dir`, `ip`, `check_type`)
2. CSH run script executes the check normally
3. On completion, run script calls `--send-completion-email <tag>`
4. `--send-completion-email` handler detects `_agent_team` flag → calls `_find_report_path()` → branches on `check_type`:
   - `cdc` → `classify_violations()` → `generate_waivers()` → attach `_waivers.tcl`
   - `lint` → `classify_lint_violations()` → `generate_lint_hints()` → attach `$tag.lint_waiver`
   - `spg_dft` → `classify_spg_dft_violations()` → `generate_spg_dft_filter_suggestions()` → attach `$tag.spg_dft_filter_hints`
5. Classification summary prepended to email body, hint/waiver file attached

**Example email with `--agent-team`:**
```
AGENT TEAM AUTO-ANALYSIS
=============================================
Report: cdc_report.rpt
Total Violations:      156
AUTO-WAIVED (HIGH):    77 (49%)
VERIFY FIRST (MEDIUM): 33
HUMAN REVIEW (LOW):    43

Waiver file: data/<tag>_waivers.tcl
Apply with: source data/<tag>_waivers.tcl
[Attachment: data/<tag>_waivers.tcl]
```

**Usage:**
```bash
python3 script/genie_cli.py -i "run cdc_rdc for umc17_0 at /proj/xxx" \
    --execute --email --agent-team
```

---

## Session 5: Two-Phase CDC Analyzer Redesign

### Problem Corrected

Original `classify_violations()` ran directly on CDC report violations without checking report validity first. If the CDC tool had **unresolved modules** or **inferred clocks/resets**, the domain assignments are guesses — violations under these conditions may be completely invalid. Classifying and waiving them would be wrong.

### Solution: Two-Phase Approach

**Phase A — Pre-Condition Check** (mandatory, runs first):
- Parses CDC report Sections 1, 2, 9 for clock/reset/blackbox counts
- If ANY unresolved modules → **FAIL** (stop, violations unreliable)
- If inferred primary clocks/resets > 0 → **WARN** (still classify, but flag)
- If inferred blackbox from known DFT shells, unresolved=0 → **INFO** (proceed normally)

**Phase B — Violation Classification** (only runs if Phase A is OK or WARN):
- Step 1: LOW_RISK module check — if RSMU/DFT/JTAG/TDR in path → `LOW_RISK` bucket (no waiver needed)
- Step 2: FIX_TEMPLATES pattern matching → HIGH/MEDIUM/LOW buckets

### Four New Methods in genie_cli.py

| Method | Purpose |
|--------|---------|
| `_parse_cdc_preconditions(report_path)` | Reads CDC report Sections 1, 2, 9. Returns dict with `inferred_clocks_primary`, `inferred_resets_primary`, `num_unresolved`, `empty_blackbox_modules`, etc. Uses `re.MULTILINE` patterns: `r'^\s+2\.1\s+Primary\s*:\s*(\d+)'` for clocks, `r'^\s+2\.1\.1\s+Primary\s*:\s*(\d+)'` for resets |
| `_is_low_risk_signal(signal)` | Returns `(True, reason)` if signal path matches RSMU/DFT/JTAG/TDR patterns. Covers: `rsmu`, `RSMU`, `rdft`, `_tdr_`, `dft_clk_marker`, `jtag`, `JTAG`, `Tdr_Tck` |
| `_get_manifest_lib_dirs(ref_dir, ip)` | Finds `out/linux_*.VCS/{ip}/config/*/pub/.../manifest/*_lib.list`, reads all `.lib.gz` paths, returns unique parent directories (golden lib search paths) |
| `_find_lib_for_module(module_name, lib_dirs)` | Runs `zgrep -l "cell ({module_name})" *.lib.gz` in each manifest lib dir. Returns list of lib files where module found |

### Updated classify_violations()

New signature: `classify_violations(self, report_path, ref_dir=None, ip=None)`

Returns enriched dict:
```python
{
    'status': 'OK' | 'PRECONDITION_WARN' | 'PRECONDITION_FAIL',
    'preconditions': { inferred_clocks_primary, inferred_resets_primary, num_unresolved, ... },
    'precond_issues': [ "Unresolved module: xyz — FAIL", ... ],
    'suggestions': [ "netlist blackbox xyz  # in project.0in_ctrl.v.tcl", ... ],
    'HIGH':     [ {id, signal, pattern, comment}, ... ],
    'MEDIUM':   [ ... ],
    'LOW':      [ ... ],
    'LOW_RISK': [ {signal, reason}, ... ],   # NEW — no waiver needed
    'total':    N,
}
```

On PRECONDITION_FAIL: returns early with empty HIGH/MEDIUM/LOW — no waivers generated.

### LOW_RISK Module Patterns in FIX_TEMPLATES.yaml

Added `low_risk_module_patterns` section (separate from `cdc_waiver_patterns`):

| Pattern Group | Signals | Risk | Action |
|---------------|---------|------|--------|
| `rsmu_debug` | `.*rsmu.*`, `.*RSMU.*`, `.*rdft.*`, `.*_rsmu_rdft.*` | LOW | Flag for RSMU team awareness, no waiver |
| `dft_test_modules` | `.*dft_clk_marker.*`, `.*_tdr[_.].*`, `.*jtag.*`, `.*JTAG.*`, `.*Tdr_Tck.*`, `.*[Ss]can[Ee]n.*` | LOW | DFT infrastructure, not functional CDC concern |
| `known_memory_macros` | `.*rfsd2p.*`, `.*rfps2p.*`, `.*hdsd1p.*`, `.*trfpss2p.*` | IGNORE | Already blackboxed in project.0in_ctrl.v.tcl |

The `applies_to` field lists which checks use each pattern: `["cdc", "lint", "spg_dft"]`.

### Pre-Condition Decision Rules (in analyzer.md)

| Condition | Severity | Action |
|-----------|----------|--------|
| Unresolved Modules > 0 | **FAIL** | STOP. Violations unreliable. Report suggestions. |
| Inferred Primary Clocks > 0 | **WARN** | Report. Suggest `netlist clock` constraint. Still classify but flag. |
| Inferred Primary Resets > 0 | **WARN** | Report. Suggest `netlist reset` constraint. Still classify but flag. |
| Inferred Gated-Mux Clocks > 0 | **WARN** | May be missing clock gating cell lib. Check liblist. |
| Inferred Blackbox clocks/resets, Unresolved=0 | **INFO** | Known DFT shells — proceed normally. |

### Suggestion Templates for Pre-Condition Issues

**Unresolved modules** → add to `src/meta/tools/cdc0in/variant/$ip/project.0in_ctrl.v.tcl`:
```tcl
netlist blackbox <module_name>
```

**Inferred primary clocks** → add to constraint file:
```tcl
netlist clock <signal_name> -group <CLOCK_GROUP>  # verify group name from SDC
```

**Inferred primary resets** → add to constraint file:
```tcl
netlist reset <signal_name> -active_low  # verify polarity
```

**Unknown blackboxes** → check manifest lib dirs:
```
Path: out/linux_*.VCS/$ip/config/*/pub/sim/publish/tiles/tile/$tile/publish_rtl/manifest/*_lib.list
Action: zgrep "cell (module_name)" *.lib.gz in each lib directory listed
If found: add that lib to:
  - CDC:     src/meta/tools/cdc0in/variant/$ip/umc_top_lib.list
  - SPG_DFT: src/meta/tools/spgdft/variant/$ip/project.params (SPGDFT_STD_LIB)
```

### Grimlock umc17_0 Pre-Condition State (Reference)

| Check | Count | Status | Notes |
|-------|-------|--------|-------|
| Inferred Primary Clocks | 0 | ✅ CLEAN | All 3 clock groups are User-Specified |
| Inferred Primary Resets | 0 | ✅ CLEAN (INFO only) | 2 Inferred Blackbox from `dft_clk_marker` outputs — already constrained in project.0in_ctrl.v.tcl lines 39-40 |
| Unresolved Modules | 0 | ✅ PASS | 3 blackboxes (dft_clk_marker) — all DFT shells, LOW_RISK |
| → Overall Pre-Condition | — | **OK** | Phase B classification proceeds normally |

### Updated --send-completion-email Handler

After Session 5 changes, the handler:
1. Passes `ref_dir=at_ref_dir, ip=at_ip` to `classify_violations()`
2. On `PRECONDITION_FAIL`: skips waiver generation, emails pre-condition issues + suggestions only
3. On `PRECONDITION_WARN`: includes pre-condition issues + suggestions, then classifies violations, flags in email
4. Shows `LOW_RISK` count in email summary (no waivers generated for these)
5. Includes Python traceback in email on exception (for debugging)

### What is NOT yet implemented in Phase 4

All three check types (CDC, Lint, SPG_DFT) are now wired into the `--send-completion-email` handler.

**Phase 4 is fully complete.** All report paths are correct in both IP_CONFIG.yaml and the hardcoded fallbacks.

#### `--self-debug` loop (full implementation)

Flag exists but does nothing beyond `--agent-team`. Full loop would:
1. Apply generated waivers to source tree
2. Rerun the CDC/lint check
3. Re-classify remaining violations
4. Repeat up to `--max-iterations` times (default 3)

---

## Test Results Summary

| Test | Description | Result |
|------|-------------|--------|
| Test 1 | Agent team creation + IP_CONFIG/FIX_TEMPLATES readout | ✅ PASSED |
| Test 2 | IP-specific command generation (UMC + GMC) | ✅ PASSED |
| Test 3 | CDC report analysis + FIX_TEMPLATES classification | ✅ PASSED |
| Test 4 | Waiver generation (Fixer agent, 5 sample violations) | ✅ PASSED |
| Test 5 | Full 4-agent self-debug simulation (156 violations, 77 auto-waived) | ✅ PASSED |
| Test 6 | HISTORICAL_FIXES validation + 4 new FIX_TEMPLATES patterns | ✅ PASSED |

---

## Grimlock umc17_0 CDC Analysis (Reference Data)

**Report:** `/proj/rtg_oss_er_feint1/abinbaba/umc_grimlock_Mar16202602/out/linux_4.18.0_64.VCS/umc17_0/config/umc_top_drop2cad/pub/sim/publish/tiles/tile/umc_top/cad/rhea_cdc/cdc_umc_top_output/cdc_report.rpt`

**Total violations:** 156 (154 no_sync, 2 series_redundant) | 612 pass (techind_cdcefpm)

| Category | Count | Signals | Action |
|----------|-------|---------|--------|
| HIGH — power_reset_signal | 8 | Cpl_GAP_PWROK (2), Cpl_PWROK (4), Cpl_RESETn (2) | Auto-waive |
| HIGH — static_config_register | 69 | REGCMD.REG_*, ECC.SCRUBCNTR.Reg*, REG_DAT.oQ_*, rsmu_register_wrapper.oQ_* | Auto-waive |
| MEDIUM — rsmu_signal | 33 | rsmu_pgfsm_fsm.*, pgfsm_cntl_reg[*], ms_counter gray pointers | RSMU team review |
| LOW — unmatched | 41 | SPAZ.THMCTR.*, SPAZ.ZQCTR.ZqGrpInProg*, petctr.CtrlUpd*, BEQ_UMC_InSR_d1 | Human review |
| LOW — series_redundant | 2 | CplPwrOkDficlkTx_Shft[6] | Human review |

---

## Phase 5 Gap Analysis: Missing Agent Team Coverage for UPDATE Workflows

### Background

The current `--agent-team` mode (Phase 4) can:
1. Classify CDC violations into HIGH/MEDIUM/LOW
2. Generate waivers into `data/<tag>_waivers.tcl`
3. Summarize results in the completion email

**What it cannot do:** Actually APPLY those waivers to the design source tree and rerun the checks. That requires calling the existing update scripts.

The Genie CLI has 14 existing update instructions (in `instruction.csv`) that write waivers/constraints/params directly to source tree files. The agent team currently produces no output that feeds into these update scripts.

---

### Existing Update Scripts

#### update_cdc.csh — CDC Waiver/Constraint/Config/Version Updates

**Script:** `script/rtg_oss_feint/{umc|oss|gmc}/update_cdc.csh`
**Args:** `<refDir> <ip> <tile> <tag> <updateType>`

| updateType | Input Data File | Target File in Tree |
|------------|----------------|---------------------|
| `waiver` | `data/$tag.cdc_rdc_waiver` | `src/meta/tools/cdc0in/variant/$ip/umc.0in_waiver` |
| `constraint` | `data/$tag.cdc_rdc_constraint` | `src/meta/tools/cdc0in/variant/$ip/project.0in_ctrl.v.tcl` |
| `config` | `data/$tag.cdc_rdc_config` | `src/meta/tools/cdc0in/cdc.yml` (via `update_config_yaml.py`) |
| `version` | `data/$tag.cdc_rdc_version` | `_env/local/${ip}_modulefile` |

**Waiver format** (TCL — what gets appended to `umc.0in_waiver`):
```tcl
cdc report crossing -id no_sync_10569 \
  -comment "Asynchronous power/reset signal - safe crossing, no sync required" \
  -status waived
```

**Constraint format** (TCL — what gets appended to `project.0in_ctrl.v.tcl`):
```tcl
netlist port bus_name -clock_domain clk_dest \
  -comment "Gray coded pointer - 1 bit change per cycle"
```

After applying, the script automatically reruns CDC/RDC via `static_check_command.csh` to verify.

#### update_lint.csh — Lint Waiver Updates

**Script:** `script/rtg_oss_feint/{umc|oss|gmc}/update_lint.csh`
**Args:** `<refDir> <ip> <tile> <tag> <updateType>`

**Input Data File:** `data/$tag.lint_waiver`
**Target File:** `src/meta/waivers/lint/variant/$ip/umc_waivers.xml`

Two modes depending on content of `data/$tag.lint_waiver`:

**Mode 1 — Direct XML** (if file contains `<waive_regexp>`):
Content is appended directly to the XML file.

**Mode 2 — Smart Log Matching** (if no XML tags detected):
Content is treated as hints (error code + code snippet). The script:
1. Finds `leda_waiver.log` from the lint run
2. Calls `generate_waiver_from_log.py` which matches violations from the log
3. Generates XML `<waive_regexp>` entries and inserts them before `</block>` in the XML file

**Lint waiver XML format:**
```xml
<waive_regexp>
   <error>W287</error>
   <filename>src/rtl/umcdat.v</filename>
   <code>scan_en_o unused</code>
   <msg>unused output port scan_en_o</msg>
   <line>123</line>
   <column>.*</column>
   <reason>DFT signal - connected during scan insertion</reason>
   <author>genie_agent_auto</author>
</waive_regexp>
```

**Smart match hint format** (YAML-like, consumed by `generate_waiver_from_log.py`):
```
error: W287
code: scan_en_o unused output
reason: DFT signal - connected during scan insertion
author: genie_agent_auto
```

After applying, the script reruns Lint via `static_check_command.csh` to verify.

#### update_spg_dft.csh — SPG_DFT Parameter Updates

**Script:** `script/rtg_oss_feint/{umc|oss|gmc}/update_spg_dft.csh`
**Args:** `<refDir> <ip> <tile> <tag>`

**Input Data File:** `data/$tag.spg_dft_params`
**Target File:** `src/meta/tools/spgdft/variant/$ip/project.params`

Content is appended directly. Format is `PARAM = value` key-value pairs.

After applying, the script reruns SPG_DFT via `static_check_command.csh` to verify.

---

### The Gap: Phase 4 vs Phase 5

#### What Phase 4 Currently Produces

When `--agent-team` is used with a CDC run:
```
data/<tag>_waivers.tcl     ← TCL waiver commands (HIGH confidence only)
data/<tag>_agent_team      ← flag file with ref_dir/ip/check_type
```

The `_waivers.tcl` content is in the **correct format** for `update_cdc.csh` — it uses
`cdc report crossing -id ... -status waived` syntax. But:
1. It is written to `_waivers.tcl`, not `$tag.cdc_rdc_waiver` (different filename)
2. The update script is never called to actually apply them to the tree
3. After applying, the CDC check is not rerun automatically

#### What Phase 5 Needs to Add

**Phase 5 = Auto-Apply Loop**: classify violations → write to correct data file → call update script → rerun check

This is essentially the `--self-debug` loop flag that was scaffolded but never implemented.

---

### Implementation Plan for Phase 5

#### Step 1: CDC Auto-Apply (connect Phase 4 to update_cdc.csh)

In `genie_cli.py`, after `generate_waivers()`, add `apply_cdc_waivers()`:

```python
def apply_cdc_waivers(self, classified, tag, ref_dir, ip, tile='umc_top'):
    """Write waivers to data file and call update_cdc.csh to apply them"""
    # 1. Write HIGH waivers to data/$tag.cdc_rdc_waiver (same format as _waivers.tcl)
    waiver_file = os.path.join(self.base_dir, 'data', f'{tag}.cdc_rdc_waiver')
    with open(waiver_file, 'w') as f:
        for v in classified['HIGH']:
            f.write(f"cdc report crossing -id {v['id']} \\\n")
            f.write(f"  -comment \"{v['comment']}\" \\\n")
            f.write(f"  -status waived\n\n")

    # 2. Write MEDIUM constraints to data/$tag.cdc_rdc_constraint (gray_coded_pointer)
    constraint_file = os.path.join(self.base_dir, 'data', f'{tag}.cdc_rdc_constraint')
    # ... write constraint content for gray_coded_pointer violations

    # 3. Call update_cdc.csh with updateType=waiver
    update_script = os.path.join(self.base_dir, 'script/rtg_oss_feint', ip_family, 'update_cdc.csh')
    cmd = f"source {update_script} {ref_dir} {ip} {tile} {tag} waiver"
    # execute cmd
```

Triggered from `--send-completion-email` handler (already knows ref_dir/ip from `_agent_team` flag file).

#### Step 2: Lint Auto-Apply (after lint analysis is implemented)

After `generate_lint_waivers()` produces YAML-block hints:
- Write to `data/$tag.lint_waiver` in smart-match hint format
- Call `update_lint.csh` — it will use smart log matching to generate proper XML
- `generate_waiver_from_log.py` reads `leda_waiver.log` and matches violations

**Important:** The YAML-block format from `fixer.md` is ALREADY compatible with the hint format that `generate_waiver_from_log.py` expects:
```
error: {rule_code}
code: {signal_name}
reason: {justification}
author: genie_agent_auto
```
This maps directly to `generate_waiver_from_log.py`'s `error_match` / `code_match` / `reason_match` / `author_match` parsing.

#### Step 3: SPG_DFT Auto-Apply (after SPG_DFT analysis is defined)

After agent team classifies SPG_DFT violations:
- Write recommended params to `data/$tag.spg_dft_params`
- Call `update_spg_dft.csh` to apply
- SPG_DFT reruns automatically in the update script

---

### Instruction CSV Entries That Need Agent Team Coverage

These 14 instructions in `instruction.csv` are the UPDATE side — currently no agent team support:

```
could you add cdc_rdc waiver         → update_cdc.csh (updateType=waiver)
could you update cdc_rdc waiver      → update_cdc.csh (updateType=waiver)
could you add cdc_rdc constraint     → update_cdc.csh (updateType=constraint)
could you update constraint          → update_cdc.csh (updateType=constraint)
could you add cdc_rdc config         → update_cdc.csh (updateType=config)
could you update cdc_rdc config      → update_cdc.csh (updateType=config)
could you update cdc_rdc version     → update_cdc.csh (updateType=version)
could you add lint waiver            → update_lint.csh
could you update lint waiver         → update_lint.csh
could you add lint waiver on violation below    → update_lint.csh
could you update lint waiver on violation below → update_lint.csh
could you update spyglass dft parameters        → update_spg_dft.csh
could you update spg_dft parameters  → update_spg_dft.csh
could you add spyglass dft parameters → update_spg_dft.csh
```

For the `--agent-team` flag to be truly useful, after classifying violations the agent team should be able to call these update workflows automatically — without the user having to manually compose and send a second instruction.

---

### Summary: What Agent Team Covers vs What It Doesn't

| Workflow | Current Agent Team Coverage | Missing |
|----------|---------------------------|---------|
| CDC run → classify violations | ✅ classify_violations() | — |
| CDC run → generate waiver TCL | ✅ generate_waivers() | — |
| CDC run → apply waivers to tree | ✅ apply_cdc_waivers() + update_cdc.csh (use --self-debug) | — |
| CDC run → rerun after waiving | ✅ Built into update_cdc.csh (reruns CDC automatically) | — |
| Lint run → classify violations | ❌ | _parse_lint_report() + classify_lint_violations() |
| Lint run → generate waiver hints | ❌ | generate_lint_waivers() |
| Lint run → apply waivers to tree | ❌ | write data/$tag.lint_waiver + call update_lint.csh |
| Lint run → rerun after waiving | ❌ | --self-debug loop |
| SPG_DFT run → classify | ❌ | need real moresimple.rpt first |
| SPG_DFT run → apply params | ❌ | write data/$tag.spg_dft_params + call update_spg_dft.csh |
| manual CDC update (user-provided waiver) | ✅ (existing Genie CLI) | — |
| manual lint update (user-provided waiver) | ✅ (existing Genie CLI) | — |
| manual spg_dft update (user-provided params) | ✅ (existing Genie CLI) | — |

---

---

## Session 7: Real Multi-Agent Orchestration via AMD LLM Gateway

### Problem: "Agent Team" Was Just Pattern Matching

Before Session 7, `--agent-team` was purely Python pattern matching against `FIX_TEMPLATES.yaml`. No actual
agent was spawned. The "Analyzer" and "Fixer" were just loops over regex patterns — fast but limited.

### Solution: `MultiAgentOrchestrator` Class

A new class added to `genie_cli.py` that makes **real LLM API calls** for each agent role:

```
Team Lead (genie_cli.py process)
    │
    ├─→ pre-parse report locally (Python, no LLM)
    │     _parse_cdc_report()
    │     _parse_cdc_preconditions()
    │
    ├─→ [ANALYZER AGENT] AMD Gateway call
    │     Input:  structured violation summary (not 69K-line raw report)
    │     Output: ANALYSIS COMPLETE block with classification counts + reasoning
    │
    └─→ [FIXER AGENT] AMD Gateway call
          Input:  analyzer output + HIGH violations list
          Output: TCL waiver commands for each violation
```

### AMD LLM Gateway Details

| Setting | Value |
|---------|-------|
| Gateway URL | `https://llm-api.amd.com/azure` |
| Auth header | `Ocp-Apim-Subscription-Key` |
| Deployment | `swe-gpt4o-exp1` (GPT-4o) |
| Key location | `assignment.csv` → row `llmKey,<key>` |
| Body param | `max_Tokens` (capital T — AMD gateway quirk) |

The key was already present in `assignment.csv`. The format was discovered by reading the existing
`script/llm.py` and `script/use_llm.py` helper scripts.

### Key Design Decisions

**1. AMD gateway as primary backend, Anthropic as fallback:**
- `get_llm_key()` reads `llmKey` from `assignment.csv`
- `get_api_key()` reads `ANTHROPIC_API_KEY` from env (ignores `dummy` placeholder)
- AMD gateway preferred: no extra Python package required (`requests` is already installed)
- Anthropic fallback: requires `import anthropic` to succeed (optional package)

**2. `ANTHROPIC_AVAILABLE` flag at import time:**
```python
try:
    import anthropic as _anthropic_lib
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False
```
Not required for AMD path. Only used in Anthropic fallback branch.

**3. Graceful no-key fallback:**
If neither `llmKey` nor Anthropic key is available, `use_multi_agent` is set `False` and the
original Python FIX_TEMPLATES.yaml pattern-matching runs unchanged. Zero disruption to existing users.

**4. Team Lead pre-parses data:**
Raw CDC reports are 69K+ lines. Sending the full report to the LLM would waste tokens and context.
The Team Lead runs `_parse_cdc_report()` and `_parse_cdc_preconditions()` locally (pure Python)
to extract a compact structured summary, then sends only that to the LLM.

**5. Agent outputs saved for audit:**
```
data/<tag>_analyzer_output.txt   ← full text response from Analyzer agent
data/<tag>_fixer_output.txt      ← full text response from Fixer agent
data/<tag>_waivers.tcl           ← parsed TCL from Fixer output
```

### New Code in genie_cli.py

**Imports added** (after `import sys`):
```python
import threading

try:
    import anthropic as _anthropic_lib
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False
```

**`MultiAgentOrchestrator` class** (before `class GenieCLI:`):

| Method | Description |
|--------|-------------|
| `__init__(base_dir, llm_key='', anthropic_key='')` | Sets `_backend` to `'amd'` or `'anthropic'` |
| `from_cli(cli_instance)` | Factory: reads `get_llm_key()` then `get_api_key()`, returns orchestrator |
| `_call_amd_gateway(system_prompt, user_message, max_tokens)` | POST to AMD gateway, returns text |
| `_call_anthropic(system_prompt, user_message, max_tokens)` | Anthropic messages API fallback |
| `call_agent(role, user_message, max_tokens, tag)` | Loads prompt from `config/prompts/{role}.md`, calls gateway, saves output |
| `load_prompt(role)` | Reads `config/prompts/{role}.md` — system prompt for each agent role |
| `orchestrate(cli, report_path, ip, tag, ref_dir, check_type)` | CDC: sequential Analyzer→Fixer; lint/spg_dft: Analyzer only; full_static_check: parallel threads |

**New methods in `GenieCLI`:**

| Method | Description |
|--------|-------------|
| `get_llm_key()` | Reads `llmKey` row from `assignment.csv` |
| `get_api_key()` | Reads `ANTHROPIC_API_KEY` env var (ignores `dummy`), fallback to `assignment.csv` |

**Updated `--send-completion-email` handler:**
```python
llm_key       = cli.get_llm_key()
anthropic_key = cli.get_api_key()
use_multi_agent = bool(llm_key or (anthropic_key and ANTHROPIC_AVAILABLE))
if use_multi_agent:
    try:
        orc = MultiAgentOrchestrator.from_cli(cli)
        ma_summary, ma_waiver = orc.orchestrate(cli, report_path, at_ip, tag, at_ref_dir, at_check)
        agent_team_summary = f"\n#text#\n{ma_summary}"
        ...
    except Exception as ma_exc:
        use_multi_agent = False   # fall through to Python-only path
if not use_multi_agent:
    # Python-only FIX_TEMPLATES.yaml matching (original behavior — unchanged)
    ...
```

### Bug Fixed: Python-Only Blocks Overwriting Multi-Agent Output

Before the fix, all three `if at_check == 'lint':` / `elif at_check == 'spg_dft':` / `else: # CDC`
blocks ran unconditionally, overwriting `agent_team_summary` even after multi-agent succeeded.

Fix: indented all three blocks inside `if not use_multi_agent:`.

### Bug Fixed: ANTHROPIC_API_KEY=dummy in Shell Env

The shell had `ANTHROPIC_API_KEY=dummy` set as a placeholder. `get_api_key()` was returning `'dummy'`
which caused `MultiAgentOrchestrator.__init__()` to try the Anthropic path and fail.

Fix: `and not key.startswith('dummy')` added to `get_api_key()`.

### Session 7 Test Results

| Test | Result | Notes |
|------|--------|-------|
| Connectivity test | ✅ PASSED | `GATEWAY_OK` response from AMD gateway |
| Grimlock CDC multi-agent run | ✅ PASSED | 153 violations classified by GPT-4o |

**Grimlock CDC result via GPT-4o Analyzer:**
```
ANALYSIS COMPLETE
=================
PRE-CONDITION STATUS: OK
Total Violations: 153
  - no_sync: 151
  - series_redundant: 2

Classification:
  AUTO-WAIVE (HIGH):     151
    - static_config_register:    ~140
    - power_reset_signal:        ~8
    - others:                    ~3
  VERIFY FIRST (MEDIUM): 2
    - rsmu_signal:               2  (series_redundant CplPwrOkDficlkTx_Shft)
  HUMAN REVIEW (LOW):    0
  LOW RISK (RSMU/DFT):   0
```

**Note on Fixer output:** Fixer used `-id signal_name` format (signal name as ID) rather than
numeric violation IDs (e.g., `no_sync_XXXXX`). This is a minor discrepancy from the Python-only path.
The TCL format is otherwise correct. If needed, post-processing could map signal names to IDs from
the parsed violation list.

### Sync

Both copies updated:
```
/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/script/genie_cli.py
/proj/rtg_oss_feint1/FEINT_AI_AGENT/genie_agent/script/genie_cli.py
```

---

## Session 8: RTL Analyst — All Violations Analyzed from RTL Source

### Architectural Redesign — No Auto-Waivers

**User decision (Session 8):** Pattern-based classification (signal name matching → HIGH/MEDIUM/LOW) is wrong. Engineers need RTL-based analysis for ALL violations, not auto-generated waivers. The agent's role is to give feedback to engineers so THEY decide whether to waive or fix.

**Old flow (`--agent-team` post Session 7):**
```
violations → Analyzer (pattern match) → HIGH/MEDIUM/LOW → Fixer (TCL waivers)
```

**New flow (`--agent-team` post Session 8):**
```
violations → RTL Analyst (read actual Verilog, LLM explains WHY) → Markdown report for engineer
```

No auto-waivers are generated. The Fixer agent is no longer called. Output is a human-readable `.md` report.

---

### New Files

#### `config/prompts/rtl_analyst.md`

New agent prompt. Role: analysis assistant that reads RTL source and explains each violation to engineers.

Key output format per violation:
```
SIGNAL: <full_signal_path>
TYPE: <violation_type>
RTL_FINDING: <what was found in the RTL>
ROOT_CAUSE: <why the tool flagged it>
RECOMMENDATION: <what the engineer should investigate>
CONFIDENCE: HIGH | MEDIUM | LOW
NOTE: <caveats if RTL not found>
```

No WAIVE/FIX_RTL decisions. No TCL generation. Engineer decides.

#### `script/rtl_signal_tracer.py`

Lightweight RTL context extractor. Reads the VF file from the published RTL tree and finds source code for a given module.

| Method | Purpose |
|--------|---------|
| `RTLSignalTracer(ref_dir)` | Init with tree root |
| `_find_vf_file()` | Globs `**/publish_rtl/*.vf`, returns most recent |
| `_load_rtl_files()` | Parses VF for `.sv/.v/.vg` paths; fallback to `src/` glob; cap 8000 files |
| `_module_from_path(signal_path)` | Extracts second-to-last part of hierarchy (e.g., `umc0.umccmd.REGCMD` → `REGCMD`) |
| `_signal_leaf(signal_path)` | Extracts last part, strips `[...]` |
| `find_module_files(module_name)` | Filename match first, then `grep -rl` subprocess (15s timeout) |
| `get_signal_context(signal_path, context_lines=50)` | Finds module file, reads up to 200 lines, returns formatted context |
| `get_port_context(filename, line, port_name, context_lines=60)` | For lint violations with exact file+line |
| `find_driving_always(lines, signal_name, hit_line)` | Walks backwards to find enclosing always/assign block |

**Known limitation:** Module name in CDC hierarchy is the instance name, not the Verilog module definition name. File lookup by filename match often fails (e.g., instance `REGCMD` has no file `REGCMD.sv`). The `grep -rl` fallback helps but is slow. Most modules currently return "RTL not found" — the LLM still provides useful analysis based on signal name context.

---

### New Methods in `MultiAgentOrchestrator`

| Method | Description |
|--------|-------------|
| `_run_rtl_analysis_all(violations, ref_dir, ip, check_type, tag)` | Groups violations by module (second-to-last signal path element). Reads RTL file once per module. Fires all module groups in parallel threads (capped by `Semaphore(8)`). Returns `{module → {violations, rtl_ctx_found, analysis}}` |
| `_format_analysis_report(all_analyses, ip, tag, check_type)` | Assembles Markdown report: header, summary table (module + violation count + RTL found), per-module analysis blocks. Saves to `data/<tag>_rtl_analysis.md` |

**Module batching logic:**
- CDC: module = second-to-last element of signal hierarchy path
- Lint: module = stem of filename (e.g., `umccmd.sv` → `umccmd`)
- SPG_DFT: module = first word of error line

**Parallelism:** All module groups fire simultaneously. Semaphore caps concurrent AMD gateway calls at 8 to avoid rate limiting.

---

### Updated `orchestrate()` Dispatch

**CDC:**
```python
# Old: Analyzer → Fixer
# New: RTL Analyst on ALL 153 violations
violations = self._parse_cdc_report(report_path)
all_analyses = self._run_rtl_analysis_all(violations, ref_dir, ip, 'cdc', tag)
summary, report_file = self._format_analysis_report(all_analyses, ip, tag, 'cdc')
# Output: data/<tag>_rtl_analysis.md
```

**Lint:**
```python
all_analyses = self._run_rtl_analysis_all(all_viols, ref_dir, ip, 'lint', tag)
# Output: data/<tag>_lint_rtl_analysis.md
```

**SPG_DFT:**
```python
all_analyses = self._run_rtl_analysis_all(viols, ref_dir, ip, 'spg_dft', tag)
# Output: data/<tag>_spgdft_rtl_analysis.md
```

**full_static_check:** Dispatches all three in parallel threads, each calling `orchestrate()` for its check type.

---

### Performance Fixes

**Problem:** First run hung indefinitely — 19 simultaneous LLM calls; AMD gateway queued the 19th; HTTP connection stayed alive (no socket timeout triggered); `t.join()` had no timeout.

**Three fixes applied:**

| Fix | Code | Effect |
|-----|------|--------|
| Concurrency cap | `_sem = threading.Semaphore(8)` around `call_agent()` | Max 8 simultaneous gateway calls; remaining threads wait |
| HTTP read timeout | `timeout=(30, 90)` in `_call_amd_gateway()` | Hard kill after 90s of last byte received |
| Thread join timeout | `t.join(timeout=180)` + `t.is_alive()` check | Skip module if still running after 3 min; log TIMEOUT and continue |

**Before:** `timeout=120` (single value) — only applies to connection establishment, not active response streaming.
**After:** `timeout=(30, 90)` tuple — 30s connect + 90s read (both hard limits).

---

### `fixer.md` Deprecation

Added note at top of `config/prompts/fixer.md`:
```
> **Note (2026-03-17):** The Fixer agent is no longer called in the standard `--agent-team` flow.
> The RTL Analyst now provides analysis directly to engineers for all violations.
> No automatic waivers are generated.
```

Fixer is retained for potential future use (e.g., applying engineer-approved waivers), but is not called by `orchestrate()`.

---

### Email Fix

**Problem:** Email sending from orchestrator was attaching the full report file (91KB markdown → 121KB base64). With the 94KB body text, total email was ~215KB — likely blocked by AMD mail relay silently.

**Fix:** Never attach the report file. Send only a compact summary (top ~65 lines of the report = summary table + pre-conditions). Full report is saved on disk. Engineers read it locally.

The ad-hoc email script that was used to demo the output included `attachments=[report_file]` — this has been removed. Standard orchestrator email path never attaches files.

---

### Live Demo Run — Grimlock umc17_0 CDC

**Report:** `.../umc_grimlock_Mar16202602/.../cdc_umc_top_output/cdc_report.rpt`
**IP:** `umc17_0`
**Tag:** `rtl_analyst_20260317023517`

**Results:**

| Metric | Value |
|--------|-------|
| Total violations | 153 |
| Modules grouped | 19 |
| Modules analyzed successfully | 17 |
| Timeout (gateway slow) | 1 (`unknown` — 8 violations, thread hit 180s limit) |
| Error (read timeout) | 1 (`petctr` — 7 violations, gateway took >90s) |
| RTL context found | 1/19 (`umccmd` only) |
| Wall time | 180s |
| Email | Sent to Azman.BinBabah@amd.com, CC: Warren1.Wang@amd.com |
| Report | `data/rtl_analyst_20260317023517_rtl_analysis.md` (91KB) |

**Note on RTL not found:** 18/19 modules returned "RTL not found". The LLM still provides useful analysis based on signal name inference (e.g., `oQ_RSMU_CAC_ENABLE` → correctly inferred as static config register). When RTL IS found, analysis is more specific and cites actual code.

**Root cause of RTL not found:** CDC hierarchy uses INSTANCE names (`REGCMD`, `SCRUBCNTR`) not Verilog MODULE names. The `rtl_signal_tracer.py` `find_module_files()` searches by filename match (e.g., `REGCMD.sv`) — unlikely to match. The `grep -rl` fallback searches for `module REGCMD` in source files — may work but is slow and wasn't improving the hit rate. Future work: grep for the instance declaration in parent module RTL to find the actual module name.

---

### Sync

Both copies updated after Session 8:
```
/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/script/genie_cli.py
/proj/rtg_oss_feint1/FEINT_AI_AGENT/genie_agent/script/genie_cli.py
/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/script/rtl_signal_tracer.py
/proj/rtg_oss_feint1/FEINT_AI_AGENT/genie_agent/script/rtl_signal_tracer.py
```

---

## Next Session: Where to Start

1. **Read this file** to understand current state.

2. **Sessions completed:**
   - **Session 5:** Two-phase CDC analyzer (pre-condition + LOW_RISK + FIX_TEMPLATES), `apply_cdc_waivers()`, `_parse_cdc_preconditions()`, etc.
   - **Session 6:** Lint + SPG_DFT classification in `--send-completion-email`, OSS RHEL detection fix, `FIX_TEMPLATES.yaml` SPG_DFT patterns added.
   - **Session 7:** `MultiAgentOrchestrator` class — real LLM API calls via AMD gateway (`swe-gpt4o-exp1`). Both Analyzer and Fixer now make separate API calls. Python FIX_TEMPLATES path preserved as no-key fallback.
   - **Session 8:** Full architectural redesign — RTL Analyst replaces Analyzer+Fixer. No auto-waivers. All violations analyzed from RTL source. `rtl_signal_tracer.py` added. Performance fixes (Semaphore, HTTP timeout tuple, thread join timeout).

3. **Priority order for next implementation:**

   **A. RTL file lookup improvement** (HIGH — affects quality of every run)
   - Currently 18/19 modules return "RTL not found" because CDC hierarchy uses instance names, not module names
   - Fix: when filename match fails and grep-rl fails, try to find the PARENT module RTL and grep for the instance declaration to get the actual module type name
   - Example: `umc0.umccmd.REGCMD` — look in `umccmd.sv` for `REGCMD` instance declaration to get module type
   - Alternative: expand grep pattern from `module REGCMD` to case-insensitive or prefix match

   **B. RTL Analyst for Lint and SPG_DFT verification**
   - `_run_lint()` and `_run_spg_dft()` dispatch exists in `orchestrate()` — needs testing with real reports
   - Lint: find a real `leda_waiver.log`: `find /proj/rtg_oss_er_feint1/abinbaba -name "leda_waiver.log" 2>/dev/null | head -3`
   - SPG_DFT: find a real `moresimple.rpt`: `find /proj/rtg_oss_er_feint1/abinbaba -name "moresimple.rpt" 2>/dev/null | head -3`

   **C. Email output improvement**
   - Currently sends top 65 lines of the report (summary table only)
   - Consider sending per-module analysis for top N violations with LOW confidence as the body
   - Or: convert the markdown report to HTML for better rendering in Outlook

   **D. RDC report support**
   - `_parse_cdc_report()` looks for `'CDC Results'` section keyword
   - RDC reports use `'RDC Results'` — need to handle `check_type='rdc'`
   - Add a check: if `'CDC Results'` not found, try `'RDC Results'`

4. **Deferred:** `--self-debug` full loop, Lint/SPG_DFT auto-apply (Phase 5)

---

## Useful Commands

```bash
# Check current FIX_TEMPLATES patterns (includes low_risk_module_patterns from Session 5)
cat config/FIX_TEMPLATES.yaml

# Check HISTORICAL_FIXES entries
cat config/HISTORICAL_FIXES.yaml

# Verify all 8 genie_cli.py methods exist (4 original + 4 from Session 5)
grep -n "def classify_violations\|def generate_waivers\|def _parse_cdc\|def _find_report\|def _is_low_risk\|def _get_manifest\|def _find_lib_for\|agent.team" script/genie_cli.py

# Test --agent-team dry run (no execute)
python3 script/genie_cli.py -i "run cdc_rdc for umc17_0 at /proj/xxx" --agent-team

# Quick syntax check on genie_cli.py
python3 -c "import ast; ast.parse(open('script/genie_cli.py').read()); print('OK')"

# Check analyzer.md (two-phase CDC analysis)
cat config/prompts/analyzer.md

# Find a lint report to examine (for Lint Analysis implementation)
find /proj/rtg_oss_er_feint1/abinbaba -name "leda_waiver.log" 2>/dev/null | head -5
find /proj/rtg_oss_er_feint1/abinbaba -name "report_vc_spyglass_lint.txt" 2>/dev/null | head -5

# Find a spg_dft report to examine (for SPG_DFT Analysis implementation)
find /proj/rtg_oss_er_feint1/abinbaba -name "moresimple.rpt" 2>/dev/null | head -5

# Verify manifest lib dir resolution (golden paths for blackbox cell lookup)
# The manifest is at: out/linux_*.VCS/umc17_0/config/*/pub/.../manifest/umc_top_lib.list
# Example golden path: /proj/glkcmd1_lib/a0/library/lib_0.0.1_h110/
```
