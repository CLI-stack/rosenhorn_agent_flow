# Agent System - Complete Knowledge Base
**Last Updated:** 2026-01-28
**Session Context:** Complete analysis of RTG OSS FEINT Agent System

## System Overview

This is an email-driven automation agent for AMD RTG (Radeon Technology Group) that:
- Receives instructions via email
- Executes hardware verification and physical design tasks
- Sends progressive email notifications during execution
- Returns results via email with threading

**Key Projects:**
- UMC: Static checks (Lint, CDC/RDC, Spyglass DFT)
- Supra: Physical design (TileBuilder runs for synthesis, P&R)

---

## Complete Agent Flow

```
User Email
    ↓
checkInstruction.py → Creates task in tasksModel.csv
    ↓
vtoExecution.py → Generates execution script dynamically:
    source greeting.csh
    source <work_script>  (static_check.csh OR make_tilebuilder_run.csh)
    source signature_quote.csh  (auto-added)
    ↓
Work Script Execution:
    - Does actual work
    - Sends progressive notifications (background)
    - Writes results to data/${tag}_spec
    - Calls updateTask.csh (updates CSV)
    ↓
signature_quote.csh:
    - Appends signature
    - Appends original email (threading)
    - Converts spec → HTML (spec2Html.py)
    - Calls sendMail.py
    ↓
sendMail.py:
    - Builds recipient list (sender + debuggers + managers)
    - Sends HTML email via formail + sendmail
    - Subject: "Re: <original subject>"
```

---

## Critical Files & Locations

### Main Agent Directory
```
/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/
```

### Key Scripts

**Email Processing:**
- `py/checkInstruction.py` - Email parser, creates tasks
- `py/vtoExecution.py` - Orchestrates execution, generates scripts
- `py/sendMail.py` - Final email sender
- `csh/signature_quote.csh` - Email formatter (adds signature + quote)
- `csh/updateTask.csh` - Updates tasksModel.csv

**UMC Static Checks:**
- `script/rtg_oss_feint/static_check_unified.csh` - Entry point
- `script/rtg_oss_feint/umc/static_check.csh` - UMC orchestrator
- `script/rtg_oss_feint/umc/static_check_command.csh` - Main execution
- `script/rtg_oss_feint/umc/static_check_analysis.csh` - Analysis router
- `script/rtg_oss_feint/umc/send_static_check_notification.csh` - Progressive notifications
- `script/rtg_oss_feint/umc/static_check_summary.pl` - Final summary generation

**UMC Check Commands:**
- `script/rtg_oss_feint/umc/command/run_lint.csh`
- `script/rtg_oss_feint/umc/command/run_cdc_rdc.csh`
- `script/rtg_oss_feint/umc/command/run_spg_dft.csh`

**Analysis Scripts:**
- `script/rtg_oss_feint/umc/spg_dft_error_extract.pl` - SpyglassDFT error extraction
- `script/rtg_oss_feint/umc/spg_dft_error_filter.txt` - Error filter patterns

**Supra Physical Design:**
- `script/rtg_oss_feint/supra/make_tilebuilder_run.csh` - TileBuilder orchestrator
- `script/rtg_oss_feint/supra/send_skip_notification.csh` - Waived task notifications
- `script/rtg_oss_feint/supra/send_timing_pass_notification.csh` - Timing report notifications
- `script/rtg_oss_feint/supra/supra_task_skip.txt` - Waiver file

**Utilities:**
- `py/spec2Html.py` - Converts spec format to HTML
- `py/readTask.py` - Reads from tasksModel.csv
- `script/rtg_oss_feint/finishing_task.csh` - Error cleanup
- `script/rtg_oss_feint/lsf.csh` - LSF environment setup

---

## UMC Static Check - Full Flow

### full_static_check Execution

**Phase 1: Lint (Sequential)**
```tcsh
source run_lint.csh
    ↓
Analyze lint results
    ↓
send_static_check_notification.csh (Email #1: Lint results)
```

**Phase 2: CDC/RDC + SpyglassDFT (Parallel)**
```tcsh
xterm -e "run_cdc_rdc.csh" &
xterm -e "run_spg_dft.csh" &
    ↓
Wait for both xterm windows to complete
```

**Phase 3: Analysis & Notifications (Sequential)**
```tcsh
Analyze CDC/RDC → send_static_check_notification.csh (Email #2)
Analyze SpyglassDFT → send_static_check_notification.csh (Email #3)
Generate summary → static_check_summary.pl → data/${tag}_spec
```

**Phase 4: Final Email**
```tcsh
updateTask.csh (updates CSV)
signature_quote.csh → sendMail.py (Email #4: Final summary)
```

### Summary Script Analysis (static_check_summary.pl)

**Updated to include SpyglassDFT filtering:**
- Input: base_dir, tile_name, error_filter_file
- Outputs:
  - Lint table: Errors, Warnings, Waived, Unresolved_Modules
  - CDC/RDC table: Errors, Inferred, Warnings, Waived, Filtered_rsmu_dft, Unfiltered_rsmu_dft
  - SpyglassDFT table: Total_Errors, Filtered_rsmu_dft, Unfiltered_rsmu_dft

**Key improvement:** SpyglassDFT now uses same filtering logic as spg_dft_error_extract.pl

---

## Progressive Notification System

### send_static_check_notification.csh

**Purpose:** Send email as each check completes (Lint, CDC/RDC, SpyglassDFT)

**Flow:**
```tcsh
1. Read temp analysis file (from static_check_command.csh)
2. Create notify_spec with analysis results
3. Add signature
4. Add "-----Original Message-----"
5. Append original email body
6. Convert to HTML
7. Send via formail + sendmail
8. Cleanup temp files
```

**Recipients:** sender + all debuggers + all managers (from assignment.csv)

**Email Format:**
- To: Unique list of all recipients
- From: VTO (PD Agent)
- Subject: RE: <original subject>
- Content-Type: text/html

---

## TileBuilder System - make_tilebuilder_run.csh

### Overview
Sophisticated physical design automation with:
- Automatic parameter/tune file management
- Intelligent failure recovery with waiver system
- Progressive notifications (skip alerts, timing reports)
- 3-phase monitoring (setup, tune copy, target execution)

### Key Features

**1. Directory Management**
- Auto-creates timestamped directories (Malaysia timezone)
- Supports both tiles directory and specific tile directory paths

**2. Parameter Hierarchy**
```
params_centre/${tile}/override.params
    ↓ copy
tile_dir/override.params
    ↓ merge
data/${tag}.params (tag-specific overrides)
    ↓ auto-update
NICKNAME = directory_name
```

**3. Three-Phase Monitoring**

**Phase 1: Setup (lines 325-352)**
- Waits for UpdateTunable.log.gz
- Timeout: 20 minutes
- Indicates parameter generation complete

**Phase 2: Tune File Distribution (lines 354-390)**
- Copies from tune_centre/${tile}/${target}/*
- Destination: tile_dir/tune/${target}/
- Overrides default values

**Phase 3: Target Monitoring (lines 392-943)**
- Checks for target completion every 30 seconds
- Status checks every 5 minutes
- Failure detection and recovery

**4. Intelligent Waiver System**

**Multi-level validation:**
1. Check if ALL failed tasks in waiver file
2. Check for universal blocking patterns:
   - Missing output dependency files
   - License checkout failures
   - Segmentation faults
   - Fatal errors/aborts
3. Extract root cause errors from logs
4. Verify ALL root causes match expected pattern
5. If all pass → skip tasks and re-run

**Waiver file format (supra_task_skip.txt):**
```
task_name: expected_root_cause_regex_pattern
```

**5. Progressive Notifications**

**Skip Notification:**
- When: Tasks skipped due to waivers
- Script: send_skip_notification.csh
- Runs in background

**Timing Pass Notification:**
- When: Timing reports available (umccmd/umcdat tiles only)
- Checked: Every hour
- Tracks: pass_1, pass_2, pass_3
- Script: send_timing_pass_notification.csh

---

## Email System Architecture

### Email Threading

**Two methods:**
1. Subject: "Re: <original subject>" (email client recognition)
2. Quote inclusion: Original message appended to email body

**Issue identified:** signature_quote.csh only uses horizontal line (#line#), not clear "-----Original Message-----" label like progressive notifications

### sendMail.py Analysis

**Recipient Building:**
```python
toAddr = []
# Add debuggers from assignment.csv
for each debugger:
    toAddr.append(debugger.lower())
# Add managers from assignment.csv
for each manager:
    toAddr.append(manager.lower())
# Add original sender from tasksModel.csv
toAddr.append(sender.lower())
# Add extra addresses (if provided)
for each extra:
    toAddr.append(extra.lower())
# Remove duplicates
toAddr_unique = list(set(toAddr))
```

**Email Format:**
```bash
cat HTML_file | formail \
  -I "To: recipients" \
  -I "From: VTO" \
  -I "MIME-Version: 1.0" \
  -I "Content-type: text/html;charset=utf-8" \
  -I "Subject: Re: original_subject" \
  | /sbin/sendmail -oi recipients
```

**Security:** Only accepts @amd.com addresses

---

## Recent Modifications

### 1. SpyglassDFT Summary Filtering (Jan 28, 2026)

**Modified:** `static_check_summary.pl`

**Changes:**
- Added error_filter parameter (3rd argument)
- Updated check_dft() to match spg_dft_error_extract.pl logic
- SpyglassDFT table now shows: Total_Errors, Filtered_rsmu_dft, Unfiltered_rsmu_dft
- Removed Warnings and Waived columns from SpyglassDFT table

**Filter Logic:**
```perl
# Load patterns from spg_dft_error_filter.txt
foreach error_line:
    if (matches any filter pattern):
        filtered_errors++
    else:
        unfiltered_errors++
```

### 2. Progressive Notifications (Previous work)

**Created:** `send_static_check_notification.csh`

**Features:**
- Sends 3 emails during full_static_check (Lint, CDC/RDC, SpyglassDFT)
- Better email threading with "-----Original Message-----"
- Background execution (doesn't block main flow)
- Same recipient logic as final email

### 3. UMC9_3 Lint Waiver Workaround

**Modified:** `run_lint.csh`

**Logic:**
```tcsh
if ("$ip_name" == "umc9_3") then
    if (-f waiver_file) then
        skip copy (already exists)
    else
        mkdir -p waiver directory
        cp default waiver file
    endif
endif
```

---

## Known Issues

### CRITICAL: TileBuilder Monitor Termination

**Problem:**
- make_tilebuilder_run.csh monitoring loop runs for hours
- Parent shell can get terminated (SSH timeout, LSF limits, etc.)
- TileBuilder continues running but monitoring dies
- Final email never sent

**Current vulnerable code:**
```tcsh
TileBuilderTerm -x "$tb_cmd" &  # Background
while ($target_done == 0)       # Monitoring
    sleep 30
    check status
end
# If shell dies here, monitoring stops but TileBuilder keeps running
```

**Proposed Solutions:**

**Option 1: Detached Execution (Quick Fix)**
```tcsh
nohup make_tilebuilder_run.csh >& detached.log &
```

**Option 2: LSF Batch Job (Production)**
- Split into setup + monitor scripts
- Submit monitor as LSF job with 24-hour limit
- LSF manages lifecycle

**Option 3: State-Based Checkpointing (Most Robust)**
- Write checkpoint files
- Resumable monitoring
- Watchdog restarts if dies

**Option 4: Hybrid (Recommended Quick Fix)**
- Modify vtoExecution.py to use nohup for long tasks
- Minimal changes, immediate benefit

**Recommendation:** Use Option 2 (LSF) for production reliability

---

## Configuration Files

### assignment.csv
```csv
vto,AgentName
debugger,engineer1@amd.com
debugger,engineer2@amd.com
manager,manager@amd.com
disk,/proj/path/to/workspace
params,/proj/path/to/params_centre
tune,/proj/path/to/tune_centre
```

### tasksModel.csv
```csv
time,tag,sender,subject,mailBody,mailQuote,reply,instruction,runDir,status
timestamp,20260128024253,user@amd.com,Subject,Body text,Quote,replied,instruction,/path,finished
```

### project.list (UMC)
```csv
umc9_2,weisshorn
umc9_3,rosenhorn
```

### spg_dft_error_filter.txt
```
# Comment lines ignored
ati_sdff.v
umc_top.sgdc
RSMU_RDFT
RDFT_RSMU
```

---

## Spec File Format

**Markers for spec2Html.py:**
```
#text#          - Plain text paragraph
#table#         - Start CSV table
#table end#     - End table
#line#          - Horizontal line
#title#         - Title (colored)
#bold#          - Bold text
#list#          - Bulleted list
```

**Example:**
```
#text#
Changelist: 976609
Tree Path: /proj/path

#table#
Static_Check,Tile,Run_Status,Errors,Warnings
Lint,umc_top,Complete,0,0
#table end#

#line#
#text#
Thanks,
AgentAzman(PD Agent)

-----Original Message-----
From: user@amd.com
Subject: Please run static check
```

---

## Testing Paths

**UMC Test Directory:**
```
/proj/rtg_oss_er_feint1/abinbaba/umc_rosenhorn_Jan19091817
```

**Contains completed runs for:**
- Lint: leda_waiver.log (0 errors, 160 waived)
- CDC: 109 errors (93 filtered, 16 unfiltered)
- RDC: 0 errors
- SpyglassDFT: 13 errors (10 filtered, 3 unfiltered)

---

## Next Steps / TODO

1. **Fix TileBuilder monitoring termination** (CRITICAL)
   - Implement LSF batch job solution
   - Test with long-running jobs

2. **Improve email threading consistency**
   - Update signature_quote.csh to use "-----Original Message-----"
   - Match progressive notification format

3. **Add error handling to sendMail.py**
   - Check sendmail exit code
   - Retry on failure
   - Log delivery status

4. **Document waiver system**
   - Create guide for adding waiver patterns
   - Test pattern matching edge cases

5. **Monitoring improvements**
   - Add heartbeat mechanism
   - Implement recovery script
   - Better logging for debugging

---

## Quick Reference Commands

**Run static check summary:**
```bash
perl static_check_summary.pl \
  /path/to/workspace \
  umc_top \
  /path/to/spg_dft_error_filter.txt
```

**Test email spec conversion:**
```bash
python py/spec2Html.py \
  --spec data/tag_spec \
  --html data/tag_spec.html
```

**Send test email:**
```bash
python py/sendMail.py \
  --tag test_tag \
  --status finished \
  --reply "replied" \
  --source_dir $PWD \
  --html data/test.html \
  --tasksModelFile tasksModel.csv
```

**Check task status:**
```bash
python py/readTask.py \
  --tasksModelFile tasksModel.csv \
  --tag 20260128024253 \
  --item status
```

---

## Contact & Resources

**Agent Location:**
```
/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/
```

**Key Environment:**
- LSF for job submission
- Perforce (p4_mkwa) for workspace sync
- TileBuilder for physical design
- VCS for simulation
- Multiple EDA tools (Synopsys, Cadence, etc.)

**Timezone:** All timestamps use Asia/Kuala_Lumpur (Malaysia)

---

## Session History

This knowledge base was compiled from a comprehensive analysis session on 2026-01-28 covering:
- Complete agent flow architecture
- UMC static check implementation and improvements
- Email notification system deep dive
- TileBuilder execution flow analysis
- Critical bug identification (monitoring termination)
- Multiple script analyses and improvements

**Files analyzed:** 20+ scripts
**Issues identified:** 3 critical, 5 improvements
**Solutions proposed:** 4 architectural options for monitoring fix
