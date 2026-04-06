# Agent Teams Self-Debug Capability

## Document Information
- **Created**: 2026-03-16
- **Author**: Claude Code Analysis
- **Status**: Planning Phase
- **Focus**: Autonomous error detection, analysis, fix, and rerun

---

## 1. Concept: Self-Debugging Agents

### 1.1 Current Flow (Manual Debug)

```
Run Check → Find Errors → Human Analyzes → Human Fixes → Human Reruns
     │                          │                │              │
     └──────────────────────────┴────────────────┴──────────────┘
                        Manual intervention required
```

### 1.2 Proposed Flow (Self-Debug)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SELF-DEBUG LOOP                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐          │
│   │ Run      │     │ Analyze  │     │ Generate │     │ Apply    │          │
│   │ Check    │────▶│ Results  │────▶│ Fix      │────▶│ Fix      │          │
│   └──────────┘     └──────────┘     └──────────┘     └──────────┘          │
│        ▲                                                   │                │
│        │                                                   │                │
│        │              ┌──────────┐                         │                │
│        └──────────────│ Rerun    │◀────────────────────────┘                │
│                       │ Check    │                                          │
│                       └──────────┘                                          │
│                            │                                                │
│                            ▼                                                │
│                    ┌──────────────┐                                         │
│                    │ Pass?        │                                         │
│                    │ Yes → Done   │                                         │
│                    │ No → Loop    │                                         │
│                    └──────────────┘                                         │
│                                                                             │
│   Max iterations: configurable (default: 3)                                │
│   Human approval: optional for certain fix types                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Self-Debug Architecture

### 2.1 Agent Team Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SELF-DEBUG AGENT TEAM                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         TEAM LEAD                                    │   │
│  │  - Coordinates debug cycles                                          │   │
│  │  - Tracks iteration count                                            │   │
│  │  - Decides when to stop (pass/max iterations/needs human)           │   │
│  │  - Synthesizes final report                                          │   │
│  └──────────────────────────────┬──────────────────────────────────────┘   │
│                                 │                                           │
│     ┌───────────────────────────┼───────────────────────────────────┐      │
│     │                           │                                   │      │
│     ▼                           ▼                                   ▼      │
│  ┌──────────────┐        ┌──────────────┐        ┌──────────────┐         │
│  │   EXECUTOR   │        │   ANALYZER   │        │   FIXER      │         │
│  │   Teammate   │        │   Teammate   │        │   Teammate   │         │
│  │              │        │              │        │              │         │
│  │  - Run check │        │  - Parse     │        │  - Generate  │         │
│  │  - Monitor   │        │    reports   │        │    waivers   │         │
│  │  - Collect   │        │  - Classify  │        │  - Update    │         │
│  │    logs      │        │    issues    │        │    constraints│        │
│  │              │        │  - Determine │        │  - Modify    │         │
│  │              │        │    fixable   │        │    configs   │         │
│  └──────────────┘        └──────────────┘        └──────────────┘         │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      KNOWLEDGE BASE                                  │   │
│  │  - Known violation patterns                                          │   │
│  │  - Fix templates for each pattern                                    │   │
│  │  - Historical fixes (what worked before)                             │   │
│  │  - Rules for when human approval needed                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Teammate Responsibilities

| Teammate | Role | Actions |
|----------|------|---------|
| **Executor** | Run checks | Execute CDC/RDC/lint/SPG_DFT, monitor completion, collect logs |
| **Analyzer** | Parse results | Read reports, classify issues, identify fixable vs needs-human |
| **Fixer** | Apply fixes | Generate waivers, update constraints, modify configs |
| **Lead** | Coordinate | Track iterations, decide next action, final report |

---

## 3. Issue Classification

### 3.1 CDC/RDC Issues

| Issue Type | Auto-Fixable? | Fix Action |
|------------|---------------|------------|
| **no_sync** - Known safe crossing | Yes | Add waiver with justification |
| **no_sync** - Needs synchronizer | No | Flag for RTL fix, human review |
| **async_reset_no_sync** - Design intent | Yes | Add waiver with reset justification |
| **async_reset_no_sync** - Real issue | No | Flag for RTL fix |
| **multi_bits** - Gray coded | Yes | Add constraint declaring gray code |
| **multi_bits** - Needs MCP | No | Flag for RTL fix |
| **Inferred clocks** - False positive | Yes | Add clock constraint |
| **Inferred clocks** - Missing SDC | Maybe | Generate SDC constraint, verify |
| **Blackbox** - Expected | Yes | Add blackbox waiver |
| **Blackbox** - Missing module | No | Flag RTL issue |

### 3.2 Lint Issues

| Issue Type | Auto-Fixable? | Fix Action |
|------------|---------------|------------|
| **Unused signal** - Intentional | Yes | Add lint waiver |
| **Unused signal** - Bug | No | Flag for RTL review |
| **Width mismatch** - Safe truncation | Yes | Add waiver with justification |
| **Width mismatch** - Potential bug | No | Flag for RTL review |
| **Undriven** - Tied off by design | Yes | Add waiver |
| **Undriven** - Missing connection | No | Flag for RTL fix |

### 3.3 SPG_DFT Issues

| Issue Type | Auto-Fixable? | Fix Action |
|------------|---------------|------------|
| **DFT rule violation** - Waivable | Yes | Add SPG waiver |
| **DFT rule violation** - Structural | No | Flag for DFT fix |
| **Scan chain issue** | No | Flag for DFT review |

---

## 4. Fix Generation Rules

### 4.1 CDC Waiver Templates

**`config/fix_templates/cdc_waivers.yaml`**

```yaml
cdc_waiver_templates:

  # Pattern: Single-bit no_sync on static configuration register
  static_config_no_sync:
    pattern:
      type: "no_sync"
      signal_match: ".*[Cc]fg.*|.*[Rr]eg.*|.*[Cc]ontrol.*"
      crossing: "slow_to_fast"
    conditions:
      - "Signal is configuration register (written once)"
      - "No timing requirement on crossing"
    fix:
      type: "waiver"
      template: |
        cdc report crossing -from {start_signal} -to {end_signal} \
          -comment "Static configuration register, written once during init" \
          -status waived
    confidence: "high"
    auto_apply: true

  # Pattern: Reset synchronizer flagged as async_reset_no_sync
  reset_sync_false_positive:
    pattern:
      type: "async_reset_no_sync"
      signal_match: ".*[Rr]eset.*[Ss]ync.*|.*sync.*reset.*"
      has_synchronizer: true
    conditions:
      - "Reset goes through recognized sync cell"
    fix:
      type: "waiver"
      template: |
        cdc report crossing -id {violation_id} \
          -comment "Reset properly synchronized through {sync_cell}" \
          -status waived
    confidence: "high"
    auto_apply: true

  # Pattern: Multi-bit bus with gray encoding
  gray_coded_bus:
    pattern:
      type: "multi_bits"
      signal_match: ".*[Gg]ray.*|.*[Pp]tr.*"
    conditions:
      - "Bus uses gray code encoding"
      - "Only 1 bit changes per cycle"
    fix:
      type: "constraint"
      template: |
        netlist port {signal_name} -clock_domain {clock} \
          -comment "Gray coded bus, 1-bit change per cycle"
    confidence: "medium"
    auto_apply: false  # Needs verification

  # Pattern: Known safe async crossing (from historical fixes)
  known_safe_crossing:
    pattern:
      type: "no_sync"
      historical_match: true  # Check against previous waivers
    fix:
      type: "waiver"
      copy_from: "historical"
    confidence: "high"
    auto_apply: true

  # Pattern: Inferred clock that should be declared
  inferred_clock_fix:
    pattern:
      type: "inferred"
      category: "clock"
    fix:
      type: "constraint"
      template: |
        netlist clock {signal_name} -period {period} \
          -comment "Declare inferred clock"
    confidence: "medium"
    auto_apply: false  # Needs period verification
```

### 4.2 Lint Waiver Templates

**`config/fix_templates/lint_waivers.yaml`**

```yaml
lint_waiver_templates:

  # Unused DFT signals
  unused_dft_signal:
    pattern:
      rule: "W287|W240"  # Unused signal rules
      signal_match: ".*[Ss]can.*|.*[Dd]ft.*|.*[Tt]est.*"
    fix:
      type: "waiver"
      template: |
        error: W287
        filename: {file}
        line: .*
        code: unused.*{signal}
        msg: Signal '{signal}' is used for DFT purposes
        reason: DFT signal, connected during scan insertion
        author: genie_agent
    confidence: "high"
    auto_apply: true

  # Intentional width truncation
  safe_truncation:
    pattern:
      rule: "W116"  # Width mismatch
      context: "assign.*\[.*:0\]"  # Explicit bit select
    fix:
      type: "waiver"
      template: |
        error: W116
        filename: {file}
        line: {line}
        msg: Intentional truncation
        reason: Upper bits not needed in this context
        author: genie_agent
    confidence: "medium"
    auto_apply: false
```

---

## 5. Self-Debug Flow Detail

### 5.1 Iteration 1: Initial Run + Analysis

```
┌─────────────────────────────────────────────────────────────────┐
│ ITERATION 1: Initial Run                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ 1. EXECUTOR runs CDC/RDC check                                  │
│    └─▶ Completes with: 9138 violations, 10 inferred clocks     │
│                                                                 │
│ 2. ANALYZER parses cdc_report.rpt                               │
│    └─▶ Classifies:                                              │
│        ├─ 6043 no_sync violations                               │
│        │   ├─ 2100 match "static_config" pattern → AUTO-FIX    │
│        │   ├─ 1500 match "historical" pattern → AUTO-FIX       │
│        │   └─ 2443 unknown → NEEDS HUMAN REVIEW                │
│        ├─ 3091 multi_bits violations                            │
│        │   ├─ 500 match "gray_coded" pattern → VERIFY THEN FIX │
│        │   └─ 2591 unknown → NEEDS HUMAN REVIEW                │
│        ├─ 2 async_reset_no_sync                                 │
│        │   └─ 2 match "reset_sync" pattern → AUTO-FIX          │
│        └─ 10 inferred clocks                                    │
│            └─ Need clock constraints → GENERATE                 │
│                                                                 │
│ 3. ANALYZER reports to LEAD:                                    │
│    "Found 9138 violations. 3602 auto-fixable, 10 need          │
│     verification, 5034 need human review."                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Iteration 2: Apply Auto-Fixes + Rerun

```
┌─────────────────────────────────────────────────────────────────┐
│ ITERATION 2: Auto-Fix + Rerun                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ 1. LEAD decides: "Apply 3602 auto-fixes, rerun"                │
│                                                                 │
│ 2. FIXER generates waivers:                                     │
│    └─▶ Creates waiver file with 3602 entries                   │
│    └─▶ Adds to: src/meta/tools/cdc0in/waivers/auto_waivers.tcl │
│                                                                 │
│ 3. FIXER generates constraints for inferred clocks:            │
│    └─▶ Creates: inferred_clocks.sdc with 10 clock declarations │
│                                                                 │
│ 4. EXECUTOR reruns CDC/RDC with new waivers/constraints        │
│    └─▶ Completes with: 5536 violations (3602 waived)           │
│                        8 inferred clocks (2 resolved)           │
│                                                                 │
│ 5. ANALYZER re-parses:                                          │
│    └─▶ 5536 remaining violations need human review             │
│    └─▶ 8 inferred clocks still need attention                  │
│                                                                 │
│ 6. LEAD reports:                                                │
│    "Iteration 2 complete. Reduced from 9138 to 5536 violations │
│     (39% reduction). Remaining issues need human review."       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 Iteration 3: Verify Fixes + Generate Report

```
┌─────────────────────────────────────────────────────────────────┐
│ ITERATION 3: Verification + Final Report                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ 1. ANALYZER verifies applied waivers are effective             │
│    └─▶ All 3602 waivers applied correctly ✓                    │
│                                                                 │
│ 2. LEAD generates summary report:                               │
│                                                                 │
│    ┌─────────────────────────────────────────────────────────┐ │
│    │ CDC/RDC SELF-DEBUG SUMMARY                              │ │
│    │ ════════════════════════════════════════════════════════│ │
│    │ Initial violations:     9138                            │ │
│    │ Auto-fixed:             3602 (39.4%)                    │ │
│    │ Remaining:              5536                            │ │
│    │                                                         │ │
│    │ Fixes Applied:                                          │ │
│    │ ├─ Static config waivers:    2100                       │ │
│    │ ├─ Historical pattern match: 1500                       │ │
│    │ └─ Reset sync waivers:          2                       │ │
│    │                                                         │ │
│    │ New Constraints Added:                                  │ │
│    │ └─ Clock declarations:         10                       │ │
│    │                                                         │ │
│    │ NEEDS HUMAN REVIEW:                                     │ │
│    │ ├─ Unknown no_sync:          2443                       │ │
│    │ ├─ Unknown multi_bits:       2591                       │ │
│    │ └─ Inferred clocks:             8                       │ │
│    │                                                         │ │
│    │ Files Modified:                                         │ │
│    │ ├─ waivers/auto_waivers.tcl (NEW)                      │ │
│    │ └─ constraints/inferred_clocks.sdc (NEW)               │ │
│    └─────────────────────────────────────────────────────────┘ │
│                                                                 │
│ 3. LEAD notifies human for remaining review                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Human Approval Gates

### 6.1 When to Ask Human

```yaml
human_approval_required:

  # Always ask for these
  always:
    - "Constraint changes affecting timing"
    - "Waivers for security-critical paths"
    - "RTL modification suggestions"
    - "First-time pattern (no historical match)"

  # Ask based on confidence
  confidence_threshold:
    high: false      # Auto-apply
    medium: true     # Ask human
    low: true        # Ask human

  # Ask based on count
  count_threshold:
    single_fix: false           # Apply directly
    batch_under_100: false      # Apply directly
    batch_over_100: true        # Ask human first
    batch_over_500: true        # Require explicit approval
```

### 6.2 Approval Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ HUMAN APPROVAL FLOW                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ FIXER generates fix proposal:                                   │
│ "I want to add 150 waivers for static config registers.        │
│  Pattern: *Cfg*, *Reg*, *Control*                              │
│  Confidence: HIGH                                               │
│  Sample waivers: [shows 5 examples]"                           │
│                                                                 │
│ LEAD asks human (via AskUserQuestion):                         │
│ ┌─────────────────────────────────────────────────────────────┐│
│ │ The Fixer wants to apply 150 auto-waivers.                  ││
│ │ Pattern: Static config registers (*Cfg*, *Reg*)             ││
│ │                                                             ││
│ │ Options:                                                    ││
│ │ [1] Approve all 150 waivers                                 ││
│ │ [2] Review samples first (show 10 more)                     ││
│ │ [3] Apply only HIGH confidence (120 waivers)                ││
│ │ [4] Reject - I'll review manually                           ││
│ └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│ Human selects → FIXER proceeds accordingly                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Knowledge Base: Learning from History

### 7.1 Historical Fix Database

**`config/historical_fixes.yaml`**

```yaml
# Automatically updated after each successful fix
historical_fixes:

  - id: "fix_001"
    date: "2026-03-15"
    ip: "umc17_0"
    violation_type: "no_sync"
    signal_pattern: "rsmu_sms_fuse_next_addr"
    fix_applied: "waiver"
    waiver_text: "cdc report crossing -from ... -status waived"
    result: "success"
    reusable: true

  - id: "fix_002"
    date: "2026-03-14"
    ip: "gmc13_1a"
    violation_type: "multi_bits"
    signal_pattern: "gray_ptr"
    fix_applied: "constraint"
    constraint_text: "netlist port gray_ptr -clock_domain ..."
    result: "success"
    reusable: true
```

### 7.2 Pattern Learning

```
┌─────────────────────────────────────────────────────────────────┐
│ PATTERN LEARNING                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ When human manually fixes a violation:                          │
│                                                                 │
│ 1. ANALYZER detects: "New waiver added for signal X"           │
│                                                                 │
│ 2. ANALYZER asks human:                                         │
│    "I see you waived signal 'rsmu_fuse_data'.                  │
│     Should I apply similar waivers for:                        │
│     - rsmu_fuse_addr (same pattern)?                           │
│     - rsmu_fuse_ctrl (same pattern)?                           │
│     [Yes to all] [Yes to selected] [No, this was special]"     │
│                                                                 │
│ 3. If human says Yes:                                           │
│    └─▶ ANALYZER extracts pattern                                │
│    └─▶ Adds to historical_fixes.yaml                           │
│    └─▶ Future runs will auto-apply                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Configuration

### 8.1 Self-Debug Settings

**`config/self_debug_config.yaml`**

```yaml
self_debug:
  enabled: true

  iterations:
    max: 3
    stop_on_no_progress: true

  auto_fix:
    enabled: true
    confidence_threshold: "high"  # Only auto-apply HIGH confidence
    max_fixes_per_iteration: 500

  human_approval:
    required_for_medium_confidence: true
    required_for_batch_over: 100
    required_for_rtl_changes: always

  notifications:
    on_iteration_complete: true
    on_human_approval_needed: true
    on_max_iterations_reached: true

  file_modifications:
    waiver_directory: "src/meta/tools/cdc0in/waivers"
    constraint_directory: "src/meta/tools/cdc0in/constraints"
    backup_before_modify: true

  reporting:
    generate_summary: true
    include_fix_details: true
    track_fix_effectiveness: true
```

---

## 9. Example: Full Self-Debug Session

```
User: "Run cdc_rdc for umc17_0 at /proj/xxx with self-debug enabled"

TEAM LEAD:
├─▶ "Starting CDC/RDC with self-debug. Max 3 iterations."
├─▶ Spawns: EXECUTOR, ANALYZER, FIXER teammates
│
├─▶ ITERATION 1:
│   ├─▶ EXECUTOR: Runs CDC/RDC check
│   │   └─▶ "Check complete. 9138 violations found."
│   │
│   ├─▶ ANALYZER: Parses report
│   │   └─▶ "Classified: 3600 auto-fixable, 5538 need review"
│   │
│   ├─▶ FIXER: Generates 3600 waivers
│   │   └─▶ "Waivers ready. Confidence: HIGH for all."
│   │
│   └─▶ LEAD: "Applying 3600 auto-fixes. Rerunning..."
│
├─▶ ITERATION 2:
│   ├─▶ EXECUTOR: Reruns with waivers
│   │   └─▶ "Check complete. 5538 violations remaining."
│   │
│   ├─▶ ANALYZER: Re-parses
│   │   └─▶ "500 more match patterns. 5038 still need review."
│   │
│   ├─▶ FIXER: Generates 500 more waivers
│   │   └─▶ "Confidence: MEDIUM. Requesting approval."
│   │
│   └─▶ LEAD asks human: "Apply 500 medium-confidence waivers?"
│       └─▶ Human: "Yes, apply all"
│
├─▶ ITERATION 3:
│   ├─▶ EXECUTOR: Final rerun
│   │   └─▶ "Check complete. 5038 violations remaining."
│   │
│   ├─▶ ANALYZER: "No more auto-fixable patterns found."
│   │
│   └─▶ LEAD: "Self-debug complete after 3 iterations."
│
└─▶ FINAL REPORT:
    ┌────────────────────────────────────────────────────────┐
    │ SELF-DEBUG COMPLETE                                    │
    │ ═══════════════════════════════════════════════════════│
    │ Initial:    9138 violations                            │
    │ Fixed:      4100 (44.9%)                               │
    │ Remaining:  5038 (need human review)                   │
    │                                                        │
    │ Iterations: 3                                          │
    │ Waivers added: 4100                                    │
    │ Files modified:                                        │
    │   └─ waivers/auto_gen_20260316.tcl                    │
    │                                                        │
    │ Top remaining issues:                                  │
    │   1. no_sync on datapath signals (2500)               │
    │   2. multi_bits on address buses (2000)               │
    │   3. Inferred clocks (8)                              │
    └────────────────────────────────────────────────────────┘
```

---

## 10. Implementation Phases

### Phase 1: Basic Self-Debug (Week 1-2)

| Task | Description |
|------|-------------|
| Create fix templates | Define waiver patterns for common issues |
| Implement Analyzer teammate | Parse reports, classify issues |
| Implement basic Fixer | Generate waivers from templates |
| Test on single IP | UMC CDC/RDC |

### Phase 2: Learning + History (Week 3-4)

| Task | Description |
|------|-------------|
| Implement historical_fixes.yaml | Track successful fixes |
| Add pattern learning | Extract patterns from human fixes |
| Implement confidence scoring | HIGH/MEDIUM/LOW classification |

### Phase 3: Human Approval Flow (Week 5-6)

| Task | Description |
|------|-------------|
| Implement approval gates | AskUserQuestion for medium confidence |
| Add batch approval | Approve groups of similar fixes |
| Implement rollback | Undo fixes if rerun fails |

### Phase 4: Multi-Check Support (Week 7-8)

| Task | Description |
|------|-------------|
| Add lint self-debug | Lint waiver generation |
| Add SPG_DFT self-debug | DFT waiver generation |
| Cross-check integration | Fix in one check, verify in others |

---

## 11. Benefits Summary

| Aspect | Manual Debug | Self-Debug Agent |
|--------|--------------|------------------|
| **Time to first fix** | Hours (human analysis) | Minutes (auto-pattern match) |
| **Consistency** | Varies by engineer | Same patterns every time |
| **Learning** | Knowledge in heads | Knowledge in database |
| **Scalability** | 1 human = 1 check | N teammates = N checks parallel |
| **Documentation** | Often missing | Auto-generated reports |
| **Repetitive fixes** | Re-do each time | Apply from history |

---

## 12. Next Steps

1. [ ] Define fix templates for top 20 violation types
2. [ ] Create historical_fixes.yaml from existing waivers
3. [ ] Implement Analyzer teammate prompt
4. [ ] Implement Fixer teammate prompt
5. [ ] Test on recent UMC CDC/RDC run
6. [ ] Measure fix rate and accuracy

**Would you like me to start creating the fix templates or implement the Analyzer/Fixer teammate prompts?**
