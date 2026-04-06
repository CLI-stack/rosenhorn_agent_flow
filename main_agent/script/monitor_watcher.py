#!/usr/bin/env python3
"""
Monitor Watcher - Automatically re-invokes genie_cli monitor if it dies
while the TileBuilder target is still running.
Stops once the target reaches PASSED or WARNING status.

Config file format (key=value):
    tag=<current_monitor_tag>
    instruction=<genie_cli instruction>
    email_to=<email address>
    display=<DISPLAY value, e.g. :92.0>
    marker=<unique string used in cron comment>
    done=false

Usage:
    python3 script/monitor_watcher.py data/watcher_<name>.cfg
"""

import os
import sys
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GENIE_CLI = os.path.join(BASE_DIR, "script/genie_cli.py")


def read_config(cfg_file):
    config = {}
    with open(cfg_file) as f:
        for line in f:
            line = line.strip()
            if '=' in line and not line.startswith('#'):
                k, v = line.split('=', 1)
                config[k.strip()] = v.strip()
    return config


def write_config(cfg_file, config):
    with open(cfg_file, 'w') as f:
        for k, v in config.items():
            f.write(f"{k}={v}\n")


def is_process_alive(tag):
    """Check if the monitor process is still running via PID file."""
    pid_file = os.path.join(BASE_DIR, f"data/{tag}_pid")
    if not os.path.exists(pid_file):
        return False
    try:
        with open(pid_file) as f:
            pid = int(f.read().strip())
        os.kill(pid, 0)
        return True
    except (OSError, ValueError, ProcessLookupError):
        return False


def get_fxsynth_status(tag):
    """
    Read the monitor log file and determine FxSynthesize status.
    Returns: 'WARNING', 'PASSED', 'FAILED', 'STILL_RUNNING', or 'UNKNOWN'
    """
    log_file = os.path.join(BASE_DIR, f"runs/{tag}.log")
    if not os.path.exists(log_file):
        return "UNKNOWN"

    with open(log_file) as f:
        content = f.read()

    # Check for successful completion (WARNING or PASSED)
    if "SUCCESS: Target" in content:
        if "WARNING" in content:
            return "WARNING"
        if "PASSED" in content:
            return "PASSED"

    # Check for failure
    if "ERROR: Target" in content and "FAILED" in content:
        return "FAILED"

    # Check for monitor timeout (max runtime reached, target still running)
    if "MAXIMUM RUNTIME LIMIT" in content or "STILL_RUNNING" in content:
        return "STILL_RUNNING"

    return "UNKNOWN"


def reinvoke_monitor(instruction, email_to, display=None):
    """Re-invoke the monitor in background mode (no DISPLAY needed)."""
    cmd = [
        "python3", GENIE_CLI,
        "-i", instruction,
        "--execute", "--email",
        "--to", email_to
    ]
    result = subprocess.run(cmd, capture_output=True, text=True,
                            cwd=BASE_DIR)
    print(result.stdout)
    if result.stderr:
        print(result.stderr)

    for line in result.stdout.split('\n'):
        if line.strip().startswith("Tag:"):
            return line.split(":", 1)[1].strip()
    return None


def remove_cron(marker):
    """Remove cron entry containing the marker string."""
    os.system(f"(crontab -l 2>/dev/null | grep -v '{marker}') | crontab -")
    print(f"[Watcher] Cron entry '{marker}' removed.")


def main():
    if len(sys.argv) < 2:
        print("Usage: monitor_watcher.py <config_file>")
        sys.exit(1)

    cfg_file = sys.argv[1]
    if not os.path.isabs(cfg_file):
        cfg_file = os.path.join(BASE_DIR, cfg_file)

    if not os.path.exists(cfg_file):
        print(f"[Watcher] ERROR: Config file not found: {cfg_file}")
        sys.exit(1)

    config = read_config(cfg_file)
    tag         = config.get('tag', '')
    instruction = config.get('instruction', '')
    email_to    = config.get('email_to', '')
    display     = config.get('display', ':0')
    marker      = config.get('marker', '')

    print(f"[Watcher] Config: {cfg_file}")
    print(f"[Watcher] Current tag: {tag}")

    # Already done?
    if config.get('done', 'false') == 'true':
        print("[Watcher] Already marked done. Exiting.")
        sys.exit(0)

    # Check if monitor process is alive
    if is_process_alive(tag):
        print(f"[Watcher] Monitor {tag} is still alive. Nothing to do.")
        sys.exit(0)

    # Process is dead — check FxSynthesize status in log
    status = get_fxsynth_status(tag)
    print(f"[Watcher] Monitor {tag} is dead. FxSynthesize log status: {status}")

    # Done if PASSED or WARNING
    if status in ("WARNING", "PASSED"):
        print(f"[Watcher] FxSynthesize {status}. Marking done and removing cron.")
        config['done'] = 'true'
        write_config(cfg_file, config)
        if marker:
            remove_cron(marker)
        sys.exit(0)

    # Otherwise re-invoke monitor
    print(f"[Watcher] Re-invoking monitor in background (status was: {status})...")
    new_tag = reinvoke_monitor(instruction, email_to)

    if new_tag:
        config['tag'] = new_tag
        write_config(cfg_file, config)
        print(f"[Watcher] New monitor tag: {new_tag}")
    else:
        print("[Watcher] ERROR: Failed to extract new tag. Check genie_cli output above.")
        sys.exit(1)


if __name__ == '__main__':
    main()
