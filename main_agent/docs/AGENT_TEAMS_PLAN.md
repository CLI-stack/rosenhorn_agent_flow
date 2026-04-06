# Agent Teams Integration Plan for Genie Agent Flow

## Document Information
- **Created**: 2026-03-16
- **Author**: Claude Code Analysis
- **Status**: Planning Phase

---

## 1. Executive Summary

This document analyzes the feasibility of integrating Claude Code Agent Teams with the existing Genie Agent Flow for static checks and supra/TileBuilder tasks.

### Current State
- **Genie Agent**: Python/CSH-based system using one-hot encoding for instruction matching
- **Execution Model**: Sequential script execution with background monitoring
- **Architecture**: Single-agent with script delegation

### Proposed State
- **Agent Teams**: Multiple Claude Code instances coordinating through shared task lists
- **Execution Model**: Parallel processing with inter-agent communication
- **Architecture**: Lead agent + specialized teammates

---

## 2. Current Genie Agent Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GENIE AGENT FLOW                            │
├─────────────────────────────────────────────────────────────────┤
│  User Input (Natural Language)                                  │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────┐                                           │
│  │ genie_cli.py    │ ◄── One-hot encoding + instruction match  │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ CSH Script      │ ◄── Execute in background                 │
│  │ Execution       │                                           │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Monitor & Log   │ ◄── Wait for completion                   │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Email Results   │ ◄── Send notification                     │
│  └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Current Task Categories

| Category | Tasks | Current Behavior |
|----------|-------|------------------|
| **Static Checks** | CDC/RDC, lint, SPG_DFT, build_rtl | Sequential or single parallel |
| **Supra/TileBuilder** | FxSynthesize, FxPlace, FxRoute | Sequential with monitoring |
| **Analysis** | Summarize, report timing, cross-check | Immediate inline execution |
| **P4 Operations** | Sync tree, submit files | Sequential |

---

## 3. Agent Teams Compatibility Analysis

### 3.1 Strengths for Agent Teams

| Use Case | Benefit | Agent Teams Approach |
|----------|---------|---------------------|
| **Multi-tile Static Checks** | Run CDC on tile1, lint on tile2 simultaneously | Separate teammate per tile/check |
| **Parallel Debugging** | Investigate multiple failure hypotheses | Competing hypothesis teammates |
| **Cross-check Verification** | Verify spec vs report (like we just did) | Verifier teammates compare data |
| **Multi-run Monitoring** | Watch umccmd and umcdat regressions together | Monitor teammate per tile |
| **Result Analysis** | Analyze CDC, lint, timing reports in parallel | Specialist teammates per domain |

### 3.2 Challenges

| Challenge | Description | Mitigation |
|-----------|-------------|------------|
| **Token Cost** | Each teammate has separate context | Use for high-value parallel tasks only |
| **Script Execution** | CSH scripts run outside Claude Code | Teammates can still execute/monitor scripts |
| **Coordination Overhead** | More complexity for simple tasks | Reserve for multi-faceted tasks |
| **Context Loss** | Teammates don't share conversation history | Detailed spawn prompts with context |
| **Experimental Status** | Feature is disabled by default | Controlled rollout, fallback to current system |

### 3.3 Compatibility Score

| Task Type | Agent Teams Fit | Recommendation |
|-----------|-----------------|----------------|
| Single tile static check | Low | Keep current flow |
| Multi-tile parallel checks | **High** | Good candidate |
| Single supra regression | Low | Keep current flow |
| Multi-tile supra monitoring | **High** | Good candidate |
| Result analysis/summary | **Medium** | Case-by-case |
| Waiver addition | Low | Keep current flow |
| Cross-verification | **High** | Excellent candidate |
| Debug investigation | **High** | Excellent candidate |

---

## 4. Proposed Integration Architecture

### 4.1 Hybrid Model

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGENT TEAMS + GENIE AGENT HYBRID                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      TEAM LEAD (Claude Code)                     │   │
│  │  - Receives user request                                         │   │
│  │  - Decides: simple task → Genie Agent, complex → Agent Teams    │   │
│  │  - Coordinates teammates and synthesizes results                 │   │
│  └──────────────────────────┬──────────────────────────────────────┘   │
│                             │                                           │
│         ┌───────────────────┼───────────────────┐                      │
│         │                   │                   │                      │
│         ▼                   ▼                   ▼                      │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐               │
│  │  TEAMMATE 1  │   │  TEAMMATE 2  │   │  TEAMMATE 3  │               │
│  │  Static Check│   │  Supra       │   │  Analysis    │               │
│  │  Specialist  │   │  Specialist  │   │  Specialist  │               │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘               │
│         │                   │                   │                      │
│         ▼                   ▼                   ▼                      │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │                    GENIE AGENT (Script Layer)                 │     │
│  │  - CSH script execution                                       │     │
│  │  - LSF job submission                                         │     │
│  │  - File operations                                            │     │
│  │  - Email notifications                                        │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │                    SHARED TASK LIST                           │     │
│  │  - Task ownership                                             │     │
│  │  - Dependencies                                               │     │
│  │  - Status tracking                                            │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Teammate Specializations

| Teammate Role | Responsibilities | Tools/Skills |
|---------------|------------------|--------------|
| **Static Check Specialist** | Run CDC/RDC, lint, SPG_DFT | Execute static_check.csh, analyze reports |
| **Supra Specialist** | TileBuilder operations, monitoring | Execute make_tilebuilder_run.csh, monitor status |
| **Analysis Specialist** | Parse reports, cross-verify, summarize | Read files, grep patterns, generate summaries |
| **P4 Specialist** | Version control operations | Sync trees, check changelists, submit files |
| **Debug Investigator** | Root cause analysis | Read logs, trace errors, propose fixes |

---

## 5. Use Case Scenarios

### 5.1 Scenario: Full Static Check on Multiple Tiles

**Current Flow (Sequential):**
```
User: "Run full static check for umc9_3 at /proj/xxx"
→ Run build_rtl → Wait
→ Run cdc_rdc → Wait
→ Run lint → Wait
→ Run spg_dft → Wait
→ Email results
Total: ~4 hours (sequential)
```

**Agent Teams Flow (Parallel):**
```
User: "Run full static check for umc9_3 at /proj/xxx"
Lead creates team with 4 teammates:
  ├── Teammate 1: Run build_rtl → Monitor → Report
  ├── Teammate 2: Run cdc_rdc → Monitor → Report
  ├── Teammate 3: Run lint → Monitor → Report
  └── Teammate 4: Run spg_dft → Monitor → Report

Teammates communicate findings:
  - "build_rtl passed, RTL ready"
  - "CDC found 9138 violations, analyzing..."
  - "Lint found 0 errors, 201 unused waivers"
  - "SPG_DFT passed"

Lead synthesizes: Combined summary + email
Total: ~1.5 hours (parallel) + analysis time
```

### 5.2 Scenario: Multi-Tile Supra Regression

**Current Flow:**
```
User: "Run supra for umccmd and umcdat"
→ Run umccmd FxSynthesize → Monitor for hours
→ Run umcdat FxSynthesize → Monitor for hours
→ Results separated by time
```

**Agent Teams Flow:**
```
User: "Run supra for umccmd and umcdat"
Lead creates team with 2 monitor teammates:
  ├── Teammate 1: Launch umccmd → Monitor → Report timing
  └── Teammate 2: Launch umcdat → Monitor → Report timing

Teammates share progress:
  - "umccmd at FxSynthesize QUEUED"
  - "umcdat at FxSynthesize RUNNING"
  - "umccmd FxSynthesize completed - WNS: -0.05"
  - "umcdat FxSynthesize completed - WNS: -0.02"

Lead: Compare results, identify which tile is better
```

### 5.3 Scenario: Debug Investigation

**Current Flow:**
```
User: "Why did my supra run fail?"
→ Read logs manually
→ Search for errors
→ Hypothesize cause
→ Iterate
```

**Agent Teams Flow:**
```
User: "Why did my umccmd supra run fail?"
Lead creates debug team:
  ├── Teammate 1: Check TileBuilder logs for task failures
  ├── Teammate 2: Check RTL availability (GetRTL issue?)
  ├── Teammate 3: Check params configuration
  └── Teammate 4: Check disk space and permissions

Teammates debate:
  - T1: "GetRTL FAILED at line 103"
  - T2: "SYN_VF_FILE path invalid - file doesn't exist"
  - T3: "Params NICKNAME correct"
  - T4: "Disk space OK"

Lead: Root cause = Invalid SYN_VF_FILE path
```

### 5.4 Scenario: Cross-Verification (Like We Just Did)

**Agent Teams Flow:**
```
User: "Verify spec 20260316023009 matches CDC report"
Lead creates verification team:
  ├── Teammate 1: Read spec file, extract key metrics
  └── Teammate 2: Read CDC report, extract same metrics

Teammates compare:
  - T1: "Spec shows 9138 violations"
  - T2: "Report shows 9138 violations - MATCH"
  - T1: "Spec has ID async_reset_no_sync_9669"
  - T2: "Report line 17085 has same ID - MATCH"

Lead: All metrics verified ✓
```

---

## 6. Implementation Phases

### Phase 1: Enable and Test (Week 1-2)

| Task | Description | Owner |
|------|-------------|-------|
| Enable feature flag | Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to settings.json | Admin |
| Test basic team creation | Create simple 2-teammate team | Developer |
| Test in-process mode | Verify Shift+Down navigation | Developer |
| Test with tmux | Verify split-pane mode | Developer |
| Document limitations | Note any issues with current environment | Developer |

### Phase 2: Simple Integration (Week 3-4)

| Task | Description | Owner |
|------|-------------|-------|
| Create analysis teammate template | Spawn prompt for report analysis | Developer |
| Create monitor teammate template | Spawn prompt for run monitoring | Developer |
| Test cross-verification workflow | Spec vs report comparison | Developer |
| Test parallel monitoring | Two tiles simultaneously | Developer |

### Phase 3: Full Integration (Week 5-8)

| Task | Description | Owner |
|------|-------------|-------|
| Integrate with genie_cli.py | Add --agent-team flag | Developer |
| Create specialized teammate prompts | Per-task-type prompts | Developer |
| Implement task list integration | Shared tasks across teammates | Developer |
| Test full static check parallel | 4-way parallel execution | Developer |
| Performance comparison | Token cost vs time savings | Developer |

### Phase 4: Production Rollout (Week 9+)

| Task | Description | Owner |
|------|-------------|-------|
| Document usage patterns | Update CLAUDE.md | Developer |
| Train users | Demo sessions | Team Lead |
| Monitor token costs | Track usage patterns | Admin |
| Gather feedback | Iterate on prompts | Developer |

---

## 7. Configuration Requirements

### 7.1 Enable Agent Teams

Add to `settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "auto"
}
```

### 7.2 Teammate Spawn Prompts

**Static Check Specialist:**
```
You are a Static Check Specialist teammate. Your responsibilities:
1. Execute static checks using genie_cli.py
2. Monitor check progress by reading log files
3. Parse results from spec files and reports
4. Report findings to the team lead

Available commands:
- python3 script/genie_cli.py -i "run cdc_rdc at <path> for <ip>" --execute
- Read files in data/<tag>_spec for results

Share findings with other teammates when you discover issues.
```

**Supra Monitor Specialist:**
```
You are a Supra/TileBuilder Monitor Specialist. Your responsibilities:
1. Launch supra regressions using genie_cli.py
2. Monitor TileBuilderShow status
3. Parse timing reports when runs complete
4. Report progress and timing results to team lead

Available commands:
- python3 script/genie_cli.py -i "run supra regression..." --execute
- python3 script/genie_cli.py -i "report timing and area at <path>"

Communicate with other tile monitors to compare results.
```

---

## 8. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| High token costs | High | Medium | Use for complex tasks only, monitor usage |
| Feature instability (experimental) | Medium | High | Fallback to current Genie Agent |
| Context window limits | Medium | Medium | Break tasks into smaller pieces |
| Coordination failures | Low | Medium | Clear task ownership, dependencies |
| Environment compatibility | Low | High | Test thoroughly before rollout |

---

## 9. Success Metrics

| Metric | Current Baseline | Target with Agent Teams |
|--------|------------------|------------------------|
| Multi-tile check time | 4 hours (sequential) | 1.5 hours (parallel) |
| Debug investigation time | 30 min (manual) | 10 min (parallel analysis) |
| Cross-verification accuracy | Manual spot-check | Comprehensive automated |
| User satisfaction | Good | Improved for complex tasks |
| Token cost per task | N/A | Track and optimize |

---

## 10. Recommendations

### Recommended Use Cases for Agent Teams

1. **Multi-tile parallel static checks** - High value, clear parallelism
2. **Debug investigation** - Competing hypotheses approach
3. **Cross-verification tasks** - Multiple data source comparison
4. **Multi-run monitoring** - Watch multiple supra runs together

### Keep Current Genie Agent For

1. **Single-tile operations** - Simple, low overhead
2. **Sequential tasks** - No parallelism benefit
3. **Quick queries** - Check status, list directories
4. **Waiver/update operations** - Sequential file edits

### Implementation Priority

1. **Start with analysis/verification** - Low risk, immediate value
2. **Add parallel monitoring** - Clear benefit, measurable
3. **Integrate parallel execution** - Higher complexity, higher value
4. **Full hybrid system** - Long-term goal

---

## 11. Next Steps

1. [ ] Review this plan with stakeholders
2. [ ] Enable Agent Teams feature flag in test environment
3. [ ] Run proof-of-concept with cross-verification task
4. [ ] Measure token costs and time savings
5. [ ] Iterate on teammate prompts based on results
6. [ ] Document lessons learned
7. [ ] Decide on Phase 2 scope

---

## Appendix A: Agent Teams Quick Reference

### Commands
```bash
# Enable in settings.json
"env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }

# Navigation (in-process mode)
Shift+Down    # Cycle through teammates
Ctrl+T        # Toggle task list
Escape        # Interrupt teammate turn
```

### Team Lifecycle
```
Create team → Spawn teammates → Assign tasks →
Teammates work → Share findings → Lead synthesizes →
Shut down teammates → Clean up team
```

### Token Cost Considerations
- Each teammate = separate context window
- 3-5 teammates recommended maximum
- 5-6 tasks per teammate optimal
- Monitor costs during pilot phase
