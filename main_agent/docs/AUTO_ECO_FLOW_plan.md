# AUTO ECO Flow Plan
**Last Updated:** 2026-04-12
**Author:** Azman Bin Babah

---

## Overview

This document describes the end-to-end flow for analyzing and applying Metal ECO (Engineering Change Order) changes at the gate-level netlist, using RTL diffs and Formality `find_equivalent_nets` via the Genie Agent.

The flow was validated on:
- **ECO 9837** — `ddrss_umcdat` tile (`DEUMCIPRTL-9837`)
- **ECO 9874** — `ddrss_umccmd` tile (`DEUMCIPRTL-9874`)

---

## Directory Structure Reference

```
data/
├── PreEco/
│   ├── SynRtl/          ← RTL BEFORE ECO (reference)
│   │   ├── rtl_umcrec.v
│   │   ├── rtl_umctim.v
│   │   └── ...
│   ├── Synthesize.v.gz  ← Gate-level netlist BEFORE ECO (post-synthesis)
│   ├── PrePlace.v.gz    ← Gate-level netlist BEFORE ECO (post-place)
│   └── Route.v.gz       ← Gate-level netlist BEFORE ECO (post-route)
├── SynRtl/              ← RTL AFTER ECO (updated)
│   ├── rtl_umcrec.v
│   ├── rtl_umctim.v
│   └── ...
└── PostEco/
    ├── Synthesize.v.gz  ← Gate-level netlist AFTER ECO applied
    ├── PrePlace.v.gz
    └── Route.v.gz
```

---

## Step 1 — Find RTL Differences (Before vs After ECO)

### Command
```bash
# Find which files changed
diff -rq --exclude="*.vf" --exclude="*.vfe" --exclude="*.d" \
    data/PreEco/SynRtl/ data/SynRtl/

# Diff the changed file(s)
diff data/PreEco/SynRtl/<file>.v data/SynRtl/<file>.v
```

### What to Look For
- New input ports added (ECO enable/config bits)
- Signal assignments that changed
- New logic inserted (wires, always blocks)
- Submodule port connections changed

### ECO 9837 Example (`ddrss_umcdat`)
| File | Change |
|------|--------|
| `rtl_umcrec.v` | New port `UmcCfgEco9837`; `SPAZ_REC_RefReq_d1` gated; stall condition gated |
| `rtl_umcrecdsp.v` | New port `dbgu_rec_dbgstall`; `dsp_condsok` masked with `~dbgstall_mask` |

### ECO 9874 Example (`ddrss_umccmd`)
| File | Change |
|------|--------|
| `rtl_umctim.v` | Line 3728: `SendWckSyncOffCs2` → `SendWckSyncOffCs0` in `ArbBypassWckIsInSync[0]` |

---

## Step 2 — Identify Signals for `find_equivalent_nets`

For each RTL change, identify the **3 categories** of signals needed:

| Category | Signal | Purpose |
|----------|--------|---------|
| **Target register** | The flip-flop whose D-input changes | Find DFF and its current D-input net |
| **Wrong signal** (PreEco) | Signal currently connected | Net to disconnect/replace |
| **Correct signal** (PostEco) | Signal to connect instead | Net to wire in |

### ECO 9874 Example
| Category | Signal |
|----------|--------|
| Target register | `ArbBypassWckIsInSync` |
| Wrong signal | `SendWckSyncOffCs2` |
| Correct signal | `SendWckSyncOffCs0` |

---

## Step 3 — Trace Signal Hierarchy in RTL

This is critical — signals must be specified with their **full instance path** for Formality.

### How to Find the Hierarchy

```bash
# Step 3a: Which module declares the signal?
grep -rn "reg SendWckSyncOffCs0\|wire SendWckSyncOffCs0" data/PreEco/SynRtl/*.v

# Step 3b: How is that module instantiated?
grep -n "<module_name>\b" data/PreEco/SynRtl/rtl_umccmd.v

# Step 3c: How is the submodule instantiated inside that?
grep -n "<submodule_name>" data/PreEco/SynRtl/rtl_umcarb.v
```

### ECO 9874 Hierarchy Example
```
ddrss_umccmd_t                   (top tile module)
  └── umccmd                     (tile module, instance in top)
        └── ARB                  (instance of umcarb — line 2727 in rtl_umccmd.v)
              ├── SendWckSyncOffCs0    ← reg declared here
              ├── SendWckSyncOffCs2    ← reg declared here
              └── TIM              (instance of umctim — line 4857 in rtl_umcarb.v)
                    └── ArbBypassWckIsInSync  ← reg declared here
```

### ECO 9837 Hierarchy Example
```
ddrss_umcdat_t                   (top tile module)
  └── umcdat                     (tile module)
        ├── umcrec               (instance of rtl_umcrec)
        │     ├── UmcCfgEco9837        ← new input port
        │     ├── DBGU_REC_DbgStall    ← signal here
        │     ├── DBGU_REC_DbgStall_d1 ← signal here
        │     └── SPAZ_REC_RefReq_d1   ← register here
        └── umcrecdsp            (instance of rtl_umcrecdsp)
              └── dsp_condsok          ← register here
```

---

## Step 4 — Run `find_equivalent_nets` via Genie Agent

### Script Location
```
script/rtg_oss_feint/supra/find_equivalent_nets.csh
```

### Genie CLI Command Format
```bash
python3 script/genie_cli.py -i "find equivalent nets at <TileBuilder_dir> \
    NetName: <path1>,<path2>,<path3> tile <tile_name>" \
    --execute --xterm --email --to <your_email>
```

### Important Rules
| Rule | Detail |
|------|--------|
| `NetName:` requires colon | `NetName:` not `netName` — colon is mandatory |
| Nets with `/` used as-is | If net contains `/`, tile prefix is NOT prepended |
| Nets without `/` get tile prefix | e.g. `umcrec` + `DBGU_REC_DbgStall` → `umcrec/DBGU_REC_DbgStall` |
| No target = all 3 PreEco | Defaults to Synthesize + PrePlace + Route in parallel |

### Valid FM Targets
| Target | Compares |
|--------|---------|
| `FmEqvPreEcoSynthesizeVsPreEcoSynRtl` | PreEco Synthesize ↔ PreEco RTL |
| `FmEqvPreEcoPrePlaceVsPreEcoSynthesize` | PreEco PrePlace ↔ PreEco Synthesize |
| `FmEqvPreEcoRouteVsPreEcoPrePlace` | PreEco Route ↔ PreEco PrePlace |
| `FmEqvEcoSynthesizeVsEcoSynRtl` | PostEco Synthesize ↔ PostEco RTL |
| `FmEqvEcoPrePlaceVsEcoSynthesize` | PostEco PrePlace ↔ PostEco Synthesize |
| `FmEqvEcoRouteVsEcoPrePlace` | PostEco Route ↔ PostEco PrePlace |

> **Note:** Target names are case-sensitive. `PrePlace` has capital `P` — not `Preplace`.

### ECO 9874 Example Command
```bash
python3 script/genie_cli.py -i "find equivalent nets at \
    /proj/cip_feint2_konark/konark/MECO/regr_0306/main/pd/tiles/ddrss_umccmd_t_DEUMCIPRTL-9874_AI_trial_neednot_care_TileBuilder_Mar06_0357_43305_GUI \
    NetName: ARB/SendWckSyncOffCs2,ARB/SendWckSyncOffCs0,ARB/TIM/ArbBypassWckIsInSync \
    tile umccmd" --execute --xterm --email --to Azman.BinBabah@amd.com
```

---

## Step 5 — Interpret `find_equivalent_nets` Output

Results are in `data/<tag>_spec` and `rpts/<target>/find_equivalent_nets_<tag>.txt`.

### Output Format
```
===========================================
TARGET: FmEqvPreEcoSynthesizeVsPreEcoSynRtl
===========================================
==========================================
Net: r:/FMWORK_REF_.../ARB/SendWckSyncOffCs2
==========================================
i:/FMWORK_IMP_.../SendWckSyncOffCs2   ← gate-level net name
```

### Net Name Progression Per Stage
| Stage | Net type | Example |
|-------|----------|---------|
| Synthesize | Direct synthesis net | `SendWckSyncOffCs2` |
| PrePlace | HFS-buffered net | `FxPrePlace_HFSNET_XXX` |
| Route | Routed net | similar to PrePlace with routing |

### ECO 9874 Gate-Level Finding (from Synthesize.v diff)
The `find_equivalent_nets` confirmed:
```
SendWckSyncOffCs2 → phfnr_buf_2205341.I  (input of existing INVD1 cell)
SendWckSyncOffCs0 → direct net
```
ECO action: rewire `phfnr_buf_2205341.I` from `SendWckSyncOffCs2` to `SendWckSyncOffCs0`

---

## Step 6 — Apply ECO to Gate-Level Netlist

Using the net names found in Step 5, modify the gate-level netlist:

### Types of ECO Changes
| Change Type | Gate-Level Action |
|-------------|------------------|
| Signal rewire (wrong→correct) | Change `.I(SendWckSyncOffCs2)` → `.I(SendWckSyncOffCs0)` |
| New gating logic | Insert AND/NAND/INV cells, tag as `ECO_XXXX_cellN` |
| New input port | Add `input <PortName>` declaration |
| New clock gate | Insert `CKOR2` + `OR2` cells for clock enable |

### ECO Cell Naming Convention (from ECO 9837)
```verilog
// New wires
wire ECO_9837_net0;
wire ECO_9837_dbgu_rec_dbgstall_inv;

// New cells — prefix ECO_<JIRA>_cell<N>
AN2D1... ECO_9837_cell0  (.A1(UmcCfgEco9837), .A2(DbgStall_d1), .Z(ECO_9837_net0));
INVD1... ECO_9837_cell30 (.I(IReset), .ZN(ECO_9837_IReset_inv));

// Original line commented out, new line added
// .D1 ( N227 ) ,    ← commented out
   .D1 ( ECO_9837_net21 ) ,  ← new connection
```

---

## Step 7 — Verify ECO with PostEco Formality

Run the PostEco FM targets to confirm the gate-level ECO matches the updated RTL:

```bash
python3 script/genie_cli.py -i "find equivalent nets at <TileBuilder_dir> \
    NetName: ARB/SendWckSyncOffCs0,ARB/TIM/ArbBypassWckIsInSync tile umccmd \
    target FmEqvEcoSynthesizeVsEcoSynRtl,FmEqvEcoPrePlaceVsEcoSynthesize,FmEqvEcoRouteVsEcoPrePlace" \
    --execute --xterm --email --to Azman.BinBabah@amd.com
```

PostEco FM should PASS — confirming the netlist correctly implements the RTL fix.

---

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `FM-036: Unknown name` | Wrong hierarchy path | Check instance names in RTL with `grep` |
| `NetName not specified` | Missing colon in `NetName` | Use `NetName:` (with colon) |
| `NOT_FOUND` for FM target | Wrong target name case | Use `PrePlace` not `Preplace` |
| `NOTRUN` for FM target | FM not yet completed | Wait for FM to finish before running |

---

## Full Flow Summary

```
1. diff data/PreEco/SynRtl/ vs data/SynRtl/
        ↓
2. Identify changed signals + categories (target reg, wrong net, correct net)
        ↓
3. Trace RTL hierarchy (grep module declarations + instantiations)
        ↓
4. Run find_equivalent_nets via Genie (all 3 PreEco FM targets in parallel)
        ↓
5. Get gate-level net names per stage (Synthesize / PrePlace / Route)
        ↓
6. Apply ECO to gate-level netlist (rewire / insert cells)
        ↓
7. Verify with PostEco FM targets (should PASS)
```

---

## Genie Agent Script Reference

| Script | Purpose |
|--------|---------|
| `script/rtg_oss_feint/supra/find_equivalent_nets.csh` | Runs `find_equivalent_nets` in FM shell via `TileBuilderIntFM --nogui --append` |
| `script/rtg_oss_feint/supra/report_formality.csh` | Reports overall Formality equivalence results |

### `find_equivalent_nets.csh` Parameters
| Param | Position | Example |
|-------|----------|---------|
| `refDir` | `$1` | `/proj/.../TileBuilder_GUI` |
| `tag` | `$2` | `20260412205451` (auto-generated) |
| `target` | `$3` | `target:` (empty = all 3 PreEco) |
| `netName` | `$4` | `netName:ARB/SendWckSyncOffCs2,...` |
| `tile` | `$5` | `tile:umccmd` |

### Output Files
| File | Content |
|------|---------|
| `data/<tag>_spec` | Formatted results (table + per-target text) |
| `rpts/<target>/find_equivalent_nets_<tag>.txt` | Raw FM output per target |
| `runs/<tag>.log` | Execution log |
