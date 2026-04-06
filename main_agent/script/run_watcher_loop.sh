#!/bin/bash
# Watcher loop - runs monitor_watcher.py every 30 minutes
# Exits automatically once target is done (config done=true)
# Usage: bash script/run_watcher_loop.sh <config_file> [interval_seconds]

CFG_FILE="$1"
INTERVAL="${2:-1800}"  # default 30 minutes

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$BASE_DIR/runs/watcher_$(basename "$CFG_FILE" .cfg).log"

cd "$BASE_DIR"

echo "[WatcherLoop] Started at $(date)" | tee -a "$LOG_FILE"
echo "[WatcherLoop] Config: $CFG_FILE" | tee -a "$LOG_FILE"
echo "[WatcherLoop] Interval: ${INTERVAL}s" | tee -a "$LOG_FILE"
echo "[WatcherLoop] Log: $LOG_FILE" | tee -a "$LOG_FILE"

while true; do
    echo "" | tee -a "$LOG_FILE"
    echo "========== $(date) ==========" | tee -a "$LOG_FILE"

    python3 script/monitor_watcher.py "$CFG_FILE" 2>&1 | tee -a "$LOG_FILE"

    # Check if done
    DONE=$(grep "^done=true" "$CFG_FILE" 2>/dev/null)
    if [ -n "$DONE" ]; then
        echo "[WatcherLoop] Target completed. Exiting loop." | tee -a "$LOG_FILE"
        exit 0
    fi

    echo "[WatcherLoop] Sleeping ${INTERVAL}s until next check..." | tee -a "$LOG_FILE"
    sleep "$INTERVAL"
done
