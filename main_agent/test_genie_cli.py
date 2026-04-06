#!/usr/bin/env python3
"""
Test script for genie_cli.py - Tests all major function categories
"""

import subprocess
import sys

# Test directory paths (using real paths for validation)
TEST_REF_DIR = "/proj/rtg_oss_er_feint1/abinbaba/umc_rosenhorn_Feb9082038"
TEST_TILE_DIR = "/proj/rtg_oss_er_feint2/abinbaba/ROSENHORN_DSO_v2/main/pd/tiles/umcdat_Feb10151353"

# Test cases organized by category
TEST_CASES = [
    # Category: Static Checks
    ("Static Check - run cdc_rdc",
     f"run cdc_rdc at {TEST_REF_DIR} for umc9_3",
     ["cdc_rdc", "static_check_unified", "refDir"]),

    ("Static Check - run lint",
     f"run lint at {TEST_REF_DIR} for umc9_3",
     ["lint", "static_check_unified", "refDir"]),

    ("Static Check - run spg_dft",
     f"run spg_dft at {TEST_REF_DIR} for umc9_3",
     ["spg_dft", "static_check_unified", "refDir"]),

    ("Static Check - run build_rtl",
     f"run build_rtl at {TEST_REF_DIR} for umc9_3",
     ["build_rtl", "static_check_unified", "refDir"]),

    ("Static Check - run full_static_check",
     f"run full_static_check at {TEST_REF_DIR} for umc9_3",
     ["full_static_check", "static_check_unified", "refDir"]),

    ("Static Check - summarize",
     f"summarize static check at {TEST_REF_DIR} for umc9_3",
     ["static_check_summary", "refDir"]),

    # Category: P4 Operations
    ("P4 - check changelist",
     f"check changelist number at {TEST_REF_DIR} for umc9_3",
     ["check_cl", "refDir"]),

    ("P4 - sync tree",
     f"sync up new tree at {TEST_REF_DIR} for umc9_3",
     ["sync_tree", "refDir"]),

    ("P4 - submit files",
     f"submit files at {TEST_REF_DIR} src/meta/test.txt\nDescription: test submit",
     ["submit_p4_file", "refDir", "p4_file", "p4_description"]),

    # Category: CDC/RDC Updates
    ("CDC - add waiver",
     f"add cdc_rdc waiver at {TEST_REF_DIR} for umc9_3\ncdc report crossing from signal1 to signal2",
     ["update_cdc", "waiver", "refDir"]),

    ("CDC - add constraint",
     f"add cdc_rdc constraint at {TEST_REF_DIR} for umc9_3\nnetlist clock clk1 -period 10",
     ["update_cdc", "constraint", "refDir"]),

    ("CDC - update config",
     f"update cdc_rdc config at {TEST_REF_DIR} for umc9_3\nCDC_OPTION: value1",
     ["update_cdc", "config", "refDir"]),

    ("CDC - update version",
     f"update cdc_rdc version at {TEST_REF_DIR} for umc9_3\nCDC_Verif/1.2.3",
     ["update_cdc", "version", "refDir"]),

    # Category: Lint Updates
    ("Lint - add waiver",
     f"add lint waiver at {TEST_REF_DIR} for umc9_3\nerror: W123\nfilename: test.sv\nline: 100",
     ["update_lint", "waiver", "refDir"]),

    # Category: SPG_DFT Updates
    ("SPG_DFT - update params",
     f"update spg_dft parameters at {TEST_REF_DIR} for umc9_3\nSPGDFT_TEST_CLOCK = clk1 clk2",
     ["update_spg_dft", "refDir", "spg_dft_params"]),

    # Category: TileBuilder Operations
    ("TileBuilder - report timing",
     f"report timing and area at {TEST_TILE_DIR}",
     ["synthesis_timing", "refDir"]),

    ("TileBuilder - report utilization",
     f"report utilization at {TEST_TILE_DIR}",
     ["extract_utilization", "refDir"]),

    ("TileBuilder - list directories",
     f"list tilebuilder directories at {TEST_TILE_DIR}",
     ["list_tilebuilder_dirs", "refDir"]),

    ("TileBuilder - monitor run",
     f"monitor supra run at {TEST_TILE_DIR} for target FxSynthesize",
     ["monitor_tilebuilder", "refDir", "target"]),

    ("TileBuilder - branch from",
     f"branch from {TEST_TILE_DIR} for target FxSynthesize",
     ["tb_branch", "refDir", "target"]),

    ("TileBuilder - rerun target",
     f"rerun FxSynthesize at {TEST_TILE_DIR}",
     ["rerun_target", "refDir", "target"]),

    ("TileBuilder - stop run",
     f"stop run at {TEST_TILE_DIR}",
     ["stop_run", "refDir"]),

    # Category: Params/Tune Management
    ("Params - update params",
     f"update params at {TEST_TILE_DIR}\n<: PROJECT: test :>",
     ["update_params", "refDir"]),

    ("Params - update to center",
     f"update params to params center at {TEST_TILE_DIR}",
     ["update_params_to_center", "refDir"]),

    ("Params - update from center",
     f"update params from params center at {TEST_TILE_DIR}",
     ["update_params_from_center", "refDir"]),

    ("Tune - update to center",
     f"update tune to tune center at {TEST_TILE_DIR} for target FxSynthesize",
     ["update_tune_to_center", "refDir"]),

    ("Tune - update from center",
     f"update tune from tune center at {TEST_TILE_DIR} for target FxSynthesize",
     ["update_tune_from_center", "refDir"]),

    ("Tune - add command",
     f"add command to tune/FxSynthesize/opt.tcl at {TEST_TILE_DIR}\nset_app_var abc 123",
     ["add_command_to_tune", "refDir", "tune"]),

    # Category: Multi-line Instructions (testing the fix)
    ("Multi-line - with Description",
     f"submit files at {TEST_REF_DIR} src/test.txt\nDescription: test description\nAnother line",
     ["submit_p4_file", "p4_description"]),
]

def run_test(name, instruction, expected_matches):
    """Run a single test case"""
    cmd = [
        "python3",
        "/proj/rtg_oss_feint1/FEINT_AI_AGENT/abinbaba/rosenhorn_agent_flow/main_agent/script/genie_cli.py",
        "-i", instruction
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        output = result.stdout + result.stderr

        # Check for errors
        if "Error" in output and "Matched:" not in output:
            return False, f"Error in output: {output[:200]}"

        if "IndentationError" in output or "SyntaxError" in output:
            return False, f"Python error: {output[:200]}"

        # Check all expected matches are present
        missing = []
        for expected in expected_matches:
            if expected.lower() not in output.lower():
                missing.append(expected)

        if missing:
            return False, f"Missing expected: {missing}"

        # Check for successful match
        if "Matched:" not in output and "[DRY RUN]" not in output:
            return False, "No match found"

        return True, "OK"

    except subprocess.TimeoutExpired:
        return False, "Timeout"
    except Exception as e:
        return False, str(e)

def main():
    print("=" * 70)
    print("Genie CLI Function Test Suite")
    print("=" * 70)
    print()

    passed = 0
    failed = 0
    results = []

    for name, instruction, expected in TEST_CASES:
        success, message = run_test(name, instruction, expected)
        status = "PASS" if success else "FAIL"
        results.append((name, status, message))

        if success:
            passed += 1
            print(f"  [{status}] {name}")
        else:
            failed += 1
            print(f"  [{status}] {name}: {message}")

    print()
    print("=" * 70)
    print(f"Results: {passed} passed, {failed} failed, {len(TEST_CASES)} total")
    print("=" * 70)

    # Print failed tests summary
    if failed > 0:
        print("\nFailed Tests:")
        for name, status, message in results:
            if status == "FAIL":
                print(f"  - {name}: {message}")

    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
