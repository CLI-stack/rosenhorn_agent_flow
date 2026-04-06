# Quick Session Context - Start Here

## What to tell Claude in your next session:

```
Please read these files to understand the agent system:
1. /proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/AGENT_SYSTEM_KNOWLEDGE.md
2. /proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/SESSION_CONTEXT.md

We are working on an AMD RTG email-driven automation agent system.
```

---

## Last Session Summary (2026-01-28)

### What We Accomplished:

1. **Analyzed complete agent flow** - Email → Execution → Progressive Notifications → Final Email
2. **Improved SpyglassDFT filtering** in static_check_summary.pl to match spg_dft_error_extract.pl
3. **Identified CRITICAL bug:** TileBuilder monitoring gets terminated during long runs
4. **Studied all major scripts:**
   - sendMail.py (email sender)
   - signature_quote.csh (email formatter)
   - static_check_command.csh (UMC orchestrator)
   - make_tilebuilder_run.csh (Supra orchestrator)
   - send_static_check_notification.csh (progressive notifications)
   - spg_dft_error_extract.pl (error analysis)

### Current Status:

✅ **Working:**
- Progressive notifications for UMC static checks (Lint, CDC/RDC, SpyglassDFT)
- Email threading with original message
- Recipient management (sender + debuggers + managers)
- SpyglassDFT filtering in summary tables

❌ **Critical Issue Identified:**
- TileBuilder monitoring loop can terminate mid-execution
- Causes: SSH timeout, LSF limits, parent process death
- Impact: TileBuilder keeps running but final email never sent
- Status: Solutions proposed, NOT YET IMPLEMENTED

### What Needs to be Done Next:

**URGENT:** Fix TileBuilder monitoring termination

**Recommended approach:** LSF Batch Job (Option 2)
1. Split make_tilebuilder_run.csh into:
   - setup_tilebuilder.csh (quick - setup and launch)
   - monitor_tilebuilder.csh (long - monitoring loop)
2. Submit monitor as LSF job with 24-hour runtime
3. LSF ensures monitoring survives disconnections

**File to modify:**
```
/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/script/rtg_oss_feint/supra/make_tilebuilder_run.csh
```

---

## Key Files Modified in Last Session:

### static_check_summary.pl
**Location:** `script/rtg_oss_feint/umc/static_check_summary.pl`

**Changes:**
- Added 3rd parameter: error_filter file path
- Updated check_dft() function to filter errors
- SpyglassDFT table now shows: Total_Errors, Filtered_rsmu_dft, Unfiltered_rsmu_dft
- Removed Warnings, Waived columns from SpyglassDFT

**Usage:**
```bash
perl static_check_summary.pl \
  /path/to/workspace \
  umc_top \
  /path/to/spg_dft_error_filter.txt
```

### Files Already Modified (Previous Sessions):
- send_static_check_notification.csh (progressive notifications)
- static_check_command.csh (full_static_check flow)
- run_lint.csh (umc9_3 waiver workaround)

---

## System Architecture Quick Reference:

```
Email → checkInstruction.py → tasksModel.csv
    ↓
vtoExecution.py (generates script)
    ↓
work_script.csh (static_check.csh OR make_tilebuilder_run.csh)
    ├─ Does work
    ├─ Progressive notifications (background)
    ├─ Writes to data/${tag}_spec
    └─ Calls updateTask.csh
    ↓
signature_quote.csh (auto-added by vtoExecution.py)
    ├─ Adds signature
    ├─ Appends original email
    ├─ Converts spec → HTML
    └─ Calls sendMail.py
    ↓
Email sent to sender + debuggers + managers
```

---

## Quick Commands:

**Test UMC summary:**
```bash
cd /proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent
perl script/rtg_oss_feint/umc/static_check_summary.pl \
  /proj/rtg_oss_er_feint1/abinbaba/umc_rosenhorn_Jan19091817 \
  umc_top \
  script/rtg_oss_feint/umc/spg_dft_error_filter.txt
```

**Check agent logs:**
```bash
tail -f /proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/data/*_spec
```

**Find recent tasks:**
```bash
tail -20 tasksModel.csv
```

---

## Important Paths:

**Agent root:**
```
/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/
```

**UMC scripts:**
```
script/rtg_oss_feint/umc/
```

**Supra scripts:**
```
script/rtg_oss_feint/supra/
```

**Test workspace:**
```
/proj/rtg_oss_er_feint1/abinbaba/umc_rosenhorn_Jan19091817
```

---

## Questions to Ask in Next Session:

If you want to continue from where we left off:

1. "Should we implement the LSF batch job solution for TileBuilder monitoring?"
2. "Can you show me how to split make_tilebuilder_run.csh?"
3. "Let's test the monitoring fix with a real TileBuilder run"

Or if you have new work:

Just describe what you need help with!

---

## Important Notes:

- All timestamps use Asia/Kuala_Lumpur timezone
- Email system only accepts @amd.com addresses
- Progressive notifications run in background (&)
- SpyglassDFT filtering now matches extract script
- TileBuilder monitoring termination is CRITICAL and UNFIXED
