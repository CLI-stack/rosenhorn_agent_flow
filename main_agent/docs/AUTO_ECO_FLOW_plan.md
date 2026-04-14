# Auto ECO Flow — Implementation Guide

**Last Updated:** 2026-04-12
**Author:** Azman Bin Babah

---

## Overview

The Auto ECO Flow is a fully agentic pipeline that analyzes and applies Metal ECO (Engineering Change Order) changes at the gate-level netlist. Given a TileBuilder `refDir` and tile name, it:

1. Diffs PreEco vs PostEco RTL to discover what changed (fully dynamic — no hardcoded signals)
2. Traces RTL hierarchy to build verified gate-level net paths
3. Runs `find_equivalent_nets` via Formality (all 3 PreEco FM targets in parallel)
4. Studies the PreEco gate-level netlist to confirm cell+pin connectivity
5. Applies ECO rewiring to all 3 PostEco netlists (Synthesize / PrePlace / Route)
6. Runs PostEco Formality verification (all 3 PostEco FM targets)
7. Generates an HTML report and sends email

**Validated on:**
- ECO 9837 — `ddrss_umcdat` (`DEUMCIPRTL-9837`)
- ECO 9874 — `ddrss_umccmd` (`DEUMCIPRTL-9874`)

---

## How to Trigger

```bash
cd /proj/rtg_oss_feint1/FEINT_AI_AGENT/genie_agent/users/$USER
python3 script/genie_cli.py \
  -i "analyze eco at /proj/.../TileBuilder_dir for umccmd" \
  --execute --xterm --email
```

**Trigger keywords:** `analyze eco at <refdir> for <tile>` or `run eco analysis at <refdir> for <tile>`

---

## Architecture

```
User: "analyze eco at /proj/.../TileBuilder for umccmd"
         │
genie_cli.py → instruction.csv match → eco_analyze.csh $refDir $tag $tile
         │
eco_analyze.csh (thin wrapper, runs synchronously ~seconds)
  ├── Validates: revrc.main exists
  ├── Validates: data/PreEco/SynRtl/ and data/SynRtl/ exist
  ├── Validates: all 6 netlists (PreEco + PostEco × 3 stages)
  └── Emits: ECO_ANALYZE_MODE_ENABLED signal to stdout
         │
genie_cli.py detects ECO_ANALYZE_MODE_ENABLED
  └── Spawns ECO Orchestrator Agent (general-purpose)
           │
           ├── Step 1: RTL Diff Analysis        (rtl_diff_analyzer agent)
           ├── Step 2: find_equivalent_nets     (genie_cli.py → LSF/TileBuilder)
           ├── Step 3: PreEco Netlist Study     (eco_netlist_studier agent)
           ├── Step 4: Apply ECO to PostEco     (eco_applier agent)
           ├── Step 5: PostEco FM Verification  (genie_cli.py → post_eco_formality.csh)
           ├── Step 6: HTML Report
           └── Step 7: Email
```

---

## Directory Structure

```
<TileBuilder_refDir>/
├── revrc.main                    ← TileBuilder directory marker
├── data/
│   ├── PreEco/
│   │   ├── SynRtl/              ← RTL BEFORE ECO (reference snapshot)
│   │   │   ├── rtl_<module>.v
│   │   │   └── ...
│   │   ├── Synthesize.v.gz      ← Gate-level BEFORE ECO (post-synthesis)
│   │   ├── PrePlace.v.gz        ← Gate-level BEFORE ECO (post-place)
│   │   └── Route.v.gz           ← Gate-level BEFORE ECO (post-route)
│   ├── SynRtl/                  ← RTL AFTER ECO (updated)
│   │   ├── rtl_<module>.v
│   │   └── ...
│   └── PostEco/
│       ├── Synthesize.v.gz      ← Gate-level AFTER ECO (modified by flow)
│       ├── PrePlace.v.gz
│       └── Route.v.gz
└── rpts/
    ├── FmEqvPreEcoSynthesizeVsPreEcoSynRtl/
    │   └── find_equivalent_nets_<tag>.txt
    ├── FmEqvEcoSynthesizeVsSynRtl/
    │   ├── FmEqvEcoSynthesizeVsSynRtl.dat
    │   └── FmEqvEcoSynthesizeVsSynRtl__failing_points.rpt.gz
    └── ...
```

---

## Step-by-Step Flow

### Step 1 — RTL Diff Analysis (`rtl_diff_analyzer` agent)

**What it does:**
```bash
cd <REF_DIR>
diff -rq --exclude="*.vf" --exclude="*.vfe" --exclude="*.d" data/PreEco/SynRtl/ data/SynRtl/
```

For each changed file, runs a full diff and classifies each hunk:

| Change Type | Description |
|-------------|-------------|
| `wire_swap` | Existing signal replaced by different signal in same expression |
| `new_port` | New `input`/`output` port declaration added |
| `new_logic` | New wire/always/assign/instance added |
| `port_connection` | Port connection changed on a module instantiation |

**Hierarchy tracing (mandatory):**
The agent traces every signal from its declaring module up to tile level, extracting **instance names** (not module names) at each level:
```bash
# Find declaring module
grep -rn "reg.*<signal>\|wire.*<signal>" data/PreEco/SynRtl/

# Find instance name in parent
grep -n "<module_name>" data/PreEco/SynRtl/rtl_<parent>.v
# → "umctim TIM (" means instance_name=TIM
```

**Output:** `data/<TAG>_eco_rtl_diff.json`
```json
{
  "changes": [{"file": "<file.v>", "module_name": "...", "change_type": "wire_swap",
                "old_token": "<old>", "new_token": "<new>", "context_line": "..."}],
  "nets_to_query": [
    {"net_path": "<INST_A>/<INST_B>/<signal>", "hierarchy": [...], "reason": "...", "is_bus_variant": false},
    {"net_path": "<INST_A>/<INST_B>/<signal>_0_", "hierarchy": [...], "reason": "bus variant", "is_bus_variant": true}
  ]
}
```

**Bus signal rule:** For `reg [N:0] Signal`, both `Signal` and `Signal_0_` are queried upfront.

---

### Step 2 — Run `find_equivalent_nets`

```bash
cd <BASE_DIR>
python3 script/genie_cli.py \
  -i "find equivalent nets at <REF_DIR> for <TILE> netName:<net1>,<net2>,..." \
  --execute --xterm
```

Runs all 3 PreEco FM targets in parallel. Tag is read from CLI output (`Tag: <fenets_tag>`).

**Completion detection:** Poll the rpt files directly (NOT the spec file — the sentinel is stripped there):
```bash
grep -c "FIND_EQUIVALENT_NETS_COMPLETE" \
  <REF_DIR>/rpts/FmEqvPreEcoSynthesizeVsPreEcoSynRtl/find_equivalent_nets_<fenets_tag>.txt \
  <REF_DIR>/rpts/FmEqvPreEcoPrePlaceVsPreEcoSynthesize/find_equivalent_nets_<fenets_tag>.txt \
  <REF_DIR>/rpts/FmEqvPreEcoRouteVsPreEcoPrePlace/find_equivalent_nets_<fenets_tag>.txt
```

**FM output format:**
```
==========================================
Net: r:/FMWORK_REF_<TILE>/<TILE>/<INST_A>/<INST_B>/<signal>
==========================================
  i:/FMWORK_IMPL_SYNTHESIZE/<TILE>/<cell_name>/<pin> (+)   ← use this
  i:/FMWORK_IMPL_SYNTHESIZE/<TILE>/<cell_name>/<pin> (-)   ← SKIP — inverted
```

**Polarity rule:** Only `(+)` impl lines are used for rewiring. `(-)` lines are inverted — never rewire from those.

**FM-036 Fallback Strategy (if `Error: Unknown name ... FM-036`):**

| Step | Action |
|------|--------|
| 1 | Check the bus variant (`_0_` suffix) — already pre-queried in same run |
| 2 | Retry with parent hierarchy stripped (max 3 retries via new genie_cli.py call each) |
| 3 | Direct netlist grep: `zcat data/PreEco/Synthesize.v.gz \| grep -n "<signal>"` |
| 4 | Use RTL diff context to search by structural proximity |
| 5 | Mark as `fm_failed` — continue flow, don't abort |

**Valid PreEco FM Targets:**
| Target | Compares |
|--------|---------|
| `FmEqvPreEcoSynthesizeVsPreEcoSynRtl` | PreEco Synthesize ↔ PreEco RTL |
| `FmEqvPreEcoPrePlaceVsPreEcoSynthesize` | PreEco PrePlace ↔ PreEco Synthesize |
| `FmEqvPreEcoRouteVsPreEcoPrePlace` | PreEco Route ↔ PreEco PrePlace |

---

### Step 3 — Study PreEco Gate-Level Netlist (`eco_netlist_studier` agent)

For each impl cell found in Step 2, reads `<REF_DIR>/data/PreEco/<Stage>.v.gz` and:
- Finds the cell instantiation block (spans multiple lines until `);`)
- Extracts all `.portname(netname)` connections
- Confirms `old_net` is on the FM-identified pin

**Only `(+)` impl results from Step 2 are studied.**

**Output:** `data/<TAG>_eco_preeco_study.json`
```json
{
  "Synthesize": [{"cell_name": "...", "cell_type": "...", "pin": "...",
                  "old_net": "...", "new_net": "...",
                  "full_port_connections": {"A": "...", "B": "...", "Z": "..."},
                  "confirmed": true}],
  "PrePlace": [...],
  "Route": [...]
}
```

---

### Step 4 — Apply ECO to PostEco Netlists (`eco_applier` agent)

For each `confirmed: true` entry, per stage:

1. **Backup:** `cp data/PostEco/<Stage>.v.gz data/PostEco/<Stage>.v.gz.bak_<TAG>`
2. **Decompress:** `zcat ... > /tmp/eco_apply_<TAG>_<Stage>.v`
3. **Find cell** in PostEco by cell name
4. **Verify preconditions:**
   - Cell exists in PostEco
   - `old_net` is on the expected pin
   - Occurrence count of `.<pin>(<old_net>)` == 1 (if > 1 → AMBIGUOUS, skip)
   - `new_net` exists in PostEco (`grep -cw`)
5. **Apply:** Replace `.<pin>(<old_net>)` → `.<pin>(<new_net>)` within the cell block only
6. **Recompress:** `gzip -c /tmp/... > data/PostEco/<Stage>.v.gz`
7. **Verify:** `zcat data/PostEco/<Stage>.v.gz | grep -c ".<pin>(<old_net>)"` → must be 0
8. **Cleanup:** `rm /tmp/eco_apply_<TAG>_<Stage>.v`

**Special cases:**
| Case | Action |
|------|--------|
| `new_logic` change type | Report only — do NOT auto-insert cells |
| Cell not in PostEco | SKIPPED — may have been optimized away |
| `old_net` not on pin | SKIPPED — PostEco differs from PreEco structurally |
| Occurrence count > 1 | SKIPPED + AMBIGUOUS |
| `new_net` not in PostEco | SKIPPED — signal not yet in PostEco |

**Output:** `data/<TAG>_eco_applied.json`
```json
{
  "Synthesize": [{"cell_name": "...", "pin": "...", "old_net": "...", "new_net": "...",
                  "status": "APPLIED", "occurrence_count": 1, "verified": true}],
  "PrePlace": [...],
  "Route": [...],
  "summary": {"total": 3, "applied": 2, "skipped": 1, "verify_failed": 0}
}
```

---

### Step 5 — PostEco Formality Verification (`post_eco_formality.csh`)

**Guard:** If `summary.applied == 0` in eco_applied.json, skip this step.

```bash
cd <BASE_DIR>
python3 script/genie_cli.py \
  -i "run post eco formality at <REF_DIR> for <TILE>" \
  --execute --xterm
```

`post_eco_formality.csh` (modeled after `report_formality.csh`):
1. Sources `lsf_tilebuilder.csh` for TileBuilder/LSF environment
2. **Resets** all 3 PostEco FM targets via `serascmd --action reset`
3. **Runs** all 3 via `serascmd --action run`
4. **Polls** `TileBuilderShow` every 15 min (180-min timeout) until all complete
5. Reads `.dat` + `__failing_points.rpt.gz` per target
6. Writes per-target + overall summary to spec file

**Completion detection:** Poll `data/<eco_fm_tag>_spec` until `OVERALL ECO FM RESULT:` appears.

**PostEco FM Targets:**
| Target | Compares |
|--------|---------|
| `FmEqvEcoSynthesizeVsSynRtl` | PostEco Synthesize ↔ PostEco RTL |
| `FmEqvEcoPrePlaceVsEcoSynthesize` | PostEco PrePlace ↔ PostEco Synthesize |
| `FmEqvEcoRouteVsEcoPrePlace` | PostEco Route ↔ PostEco PrePlace |

Expected result: all 3 PASS — confirms PostEco netlist correctly implements the RTL change.

**Output:** `data/<TAG>_eco_fm_verify.json`
```json
{
  "FmEqvEcoSynthesizeVsSynRtl": "PASS",
  "FmEqvEcoPrePlaceVsEcoSynthesize": "PASS",
  "FmEqvEcoRouteVsEcoPrePlace": "PASS",
  "failing_points": []
}
```

---

### Step 6 — HTML Report

Written to `data/<TAG>_eco_report.html` with sections:
1. RTL Diff Summary — files changed, change types, signals
2. Net Analysis — find_equivalent_nets results per net per stage
3. PreEco Netlist Study — confirmed cell/pin/context per stage
4. ECO Actions Applied — APPLIED vs SKIPPED with reasons per stage
5. PostEco FM Verification — PASS/FAIL per target, failing points if any

---

### Step 7 — Email

```python
from genie_cli import GenieCLI
cli = GenieCLI()
cli.send_email(cli.get_email_recipients(),
               '[ECO Analysis Complete] <TILE> @ <REF_DIR> (<TAG>)',
               open('data/<TAG>_eco_report.html').read())
```

---

## Output Files Summary

| File | Written by | Content |
|------|-----------|---------|
| `data/<TAG>_spec` | `eco_analyze.csh` | Validation summary |
| `data/<TAG>_eco_rtl_diff.json` | Step 1 agent | RTL diff analysis + nets to query |
| `data/<fenets_tag>_spec` | Step 2 (`find_equivalent_nets`) | FM impl cell+pin results per stage |
| `data/<TAG>_eco_preeco_study.json` | Step 3 agent | PreEco netlist confirmation |
| `data/<TAG>_eco_applied.json` | Step 4 agent | ECO changes applied/skipped per stage |
| `data/<TAG>_eco_fm_verify.json` | Step 5 | PostEco FM PASS/FAIL |
| `data/<eco_fm_tag>_spec` | Step 5 (`post_eco_formality`) | PostEco FM detail per target |
| `data/<TAG>_eco_report.html` | Step 6 | Full HTML report |
| `data/PostEco/<Stage>.v.gz.bak_<TAG>` | Step 4 | Backup before editing |

---

## Scripts and Config Files

### Scripts Created

| Script | Location | Purpose |
|--------|----------|---------|
| `eco_analyze.csh` | `script/rtg_oss_feint/supra/` | Entry point — validates dirs, emits ECO_ANALYZE_MODE_ENABLED |
| `post_eco_formality.csh` | `script/rtg_oss_feint/supra/` | Resets, runs, and reports PostEco FM targets |

### ECO Agent Config Files

| File | Purpose |
|------|---------|
| `config/eco_agents/ORCHESTRATOR.md` | Main orchestrator guide — 7-step flow |
| `config/eco_agents/rtl_diff_analyzer.md` | RTL diff + hierarchy tracing specialist |
| `config/eco_agents/eco_netlist_studier.md` | PreEco gate-level netlist analysis specialist |
| `config/eco_agents/eco_applier.md` | PostEco netlist editor specialist |

### Existing Scripts Used

| Script | Purpose |
|--------|---------|
| `find_equivalent_nets.csh` | Runs FM `find_equivalent_nets` via `TileBuilderIntFM --nogui --append` |
| `report_formality.csh` | Reference implementation (single PreEco target) |
| `lsf_tilebuilder.csh` | Sources TileBuilder/LSF environment |

---

## Critical Rules (Built Into All Agents)

| Rule | Detail |
|------|--------|
| **No hardcoded signals** | All net names extracted dynamically from RTL diff |
| **Instance names only** | Hierarchy paths use instance names (`ARB`, `TIM`), never module names (`umcarb`, `umctim`) |
| **Polarity** | Only `(+)` impl nets used — never `(-)` (inverted) |
| **Bus dual-query** | For `reg [N:0] X`, query both `X` and `X_0_` |
| **Study PreEco first** | Always confirm cell+pin in PreEco before touching PostEco |
| **Single-occurrence** | If `.<pin>(<old_net>)` appears >1 time in PostEco → SKIPPED (AMBIGUOUS) |
| **Always backup** | `cp PostEco/<stage>.v.gz PostEco/<stage>.v.gz.bak_<TAG>` before any edit |
| **new_logic = report only** | Cell insertion not auto-applied — requires physical awareness |

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `FM-036: Unknown name` | Wrong hierarchy path or signal not at that level | Check instance names in RTL; try parent hierarchy; try `_0_` bus variant |
| `NetName not specified` | Missing colon in `netName` | Use `netName:<net>` (colon required) |
| `NOT_FOUND` for FM target | Wrong target name casing | Use `PrePlace` not `Preplace`; target names are case-sensitive |
| `NOTRUN` for PreEco target | PreEco FM not yet completed | PreEco FM must be PASSED before running `find_equivalent_nets` |
| ECO_ANALYZE_MODE_ENABLED not emitted | Validation failed | Check `data/<TAG>_spec` for which file/dir is missing |
| Verify step returns non-zero | Edit didn't fully take | Check for multiple occurrences; inspect the instance block manually |

---

## Full Flow Diagram

```
User: "analyze eco at <refDir> for <tile>"
             │
    eco_analyze.csh
    (validate 6 netlists + 2 RTL dirs)
             │
    ECO_ANALYZE_MODE_ENABLED
             │
    ECO Orchestrator Agent
             │
    ┌────────▼────────────────────────────────────┐
    │ Step 1: RTL Diff                            │
    │   diff PreEco/SynRtl/ vs SynRtl/           │
    │   → classify changes                        │
    │   → trace hierarchy (instance names)        │
    │   → select nets to query                    │
    └────────┬────────────────────────────────────┘
             │ data/<TAG>_eco_rtl_diff.json
    ┌────────▼────────────────────────────────────┐
    │ Step 2: find_equivalent_nets                │
    │   genie_cli.py → 3 PreEco FM targets        │
    │   poll rpt files for FIND_EQ_NETS_COMPLETE  │
    └────────┬────────────────────────────────────┘
             │ data/<fenets_tag>_spec
    ┌────────▼────────────────────────────────────┐
    │ Step 3: Study PreEco Netlist                │
    │   zcat PreEco/<stage>.v.gz                  │
    │   find cell block → confirm old_net on pin  │
    │   (only (+) polarity results)               │
    └────────┬────────────────────────────────────┘
             │ data/<TAG>_eco_preeco_study.json
    ┌────────▼────────────────────────────────────┐
    │ Step 4: Apply ECO to PostEco                │
    │   backup → decompress → verify → replace    │
    │   → recompress → verify → cleanup           │
    └────────┬────────────────────────────────────┘
             │ data/<TAG>_eco_applied.json
    ┌────────▼────────────────────────────────────┐
    │ Step 5: PostEco FM Verification             │  ← skip if applied==0
    │   post_eco_formality.csh                    │
    │   reset+run 3 PostEco targets               │
    │   poll 15min intervals (180min max)         │
    └────────┬────────────────────────────────────┘
             │ data/<TAG>_eco_fm_verify.json
    ┌────────▼────────────────────────────────────┐
    │ Step 6 + 7: HTML Report + Email             │
    └─────────────────────────────────────────────┘
```
