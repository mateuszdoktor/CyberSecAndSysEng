#!/bin/bash

CPU_THRESHOLD=50
ERROR_THRESHOLD_PER_LOG=10
WHITELIST=("bash" "sleep" "sshd" "systemd" "ps" "runtime_snapsho" "awk" "grep" "bc" "ls" "wc" "sort" "head")

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="../reports/runtime_snapshot_$TIMESTAMP.txt"

CUR_DATE=$(date +"%Y-%m-%d %H:%M:%S")
TOTAL_PROC=$(ps -e --no-headers | wc -l)

TOP_PROC_INFO=$(ps -eo pid,comm,pcpu --sort=-pcpu --no-headers | head -n 1)
TOP_PID=$(echo $TOP_PROC_INFO | awk '{print $1}')
TOP_NAME=$(echo $TOP_PROC_INFO | awk '{print $2}')
TOP_CPU=$(echo $TOP_PROC_INFO | awk '{print $3}')

UNAUTH_COUNT=0
UNAUTH_DETAILS=""
while read -r pid name; do
    [ -z "$name" ] && continue
    MATCH=0
    for authorized in "${WHITELIST[@]}"; do
        if [[ "$name" == "$authorized" ]]; then
            MATCH=1
            break
        fi
    done
    if [ "$MATCH" -eq 0 ]; then
        ((UNAUTH_COUNT++))
        UNAUTH_DETAILS+="- PID=$pid PROC=$name\n"
    fi
done < <(ps -u $USER -o pid,comm --no-headers)

TOTAL_ERRORS=0
MAX_ERRORS=-1
MOST_UNSTABLE=""
LOG_DETAILS=""
LOG_ANOMALY="NO"

if ls ../logs/*.log >/dev/null 2>&1; then
    for log_file in ../logs/*.log; do
        file_name=$(basename "$log_file")
        error_count=$(grep -c "ERROR" "$log_file" | awk '{print $1}')
        TOTAL_ERRORS=$((TOTAL_ERRORS + error_count))
        LOG_DETAILS+="- $file_name: $error_count ERROR entries\n"

       if [ "$error_count" -gt "$ERROR_THRESHOLD_PER_LOG" ]; then
            LOG_ANOMALY="YES"
        fi

        if [ "$error_count" -gt "$MAX_ERRORS" ]; then
            MAX_ERRORS=$error_count
            MOST_UNSTABLE="$file_name"
        fi
    done
fi

INDICATORS_COUNT=0
TRIGGERED_TEXT=""

if (( $(echo "$TOP_CPU > $CPU_THRESHOLD" | bc -l) )); then
    ((INDICATORS_COUNT++))
    TRIGGERED_TEXT+="- high CPU: top process $TOP_NAME (PID=$TOP_PID) uses $TOP_CPU% > threshold $CPU_THRESHOLD%\n"
fi

if [ "$UNAUTH_COUNT" -gt 0 ]; then
    ((INDICATORS_COUNT++))
    TRIGGERED_TEXT+="- unauthorized processes detected: $UNAUTH_COUNT\n"
fi

if [ "$LOG_ANOMALY" == "YES" ]; then
    ((INDICATORS_COUNT++))
    TRIGGERED_TEXT+="- log anomaly: at least one mission log exceeds ERROR threshold $ERROR_THRESHOLD_PER_LOG\n"
fi

if [ "$INDICATORS_COUNT" -eq 0 ]; then
    STATUS="NORMAL"
    SUMMARY="no suspicious indicators are present"
elif [ "$INDICATORS_COUNT" -eq 1 ]; then
    STATUS="WARNING"
    SUMMARY="exactly one suspicious indicator is present"
else
    STATUS="CRITICAL"
    SUMMARY="at least two suspicious indicators were observed simultaneously"
fi

{
echo "========================================"
echo "Runtime Security Snapshot"
echo "========================================"
echo "Date and time: $CUR_DATE"
echo "Total active processes: $TOTAL_PROC"
echo "Top CPU process: PID=$TOP_PID PROC=$TOP_NAME CPU=$TOP_CPU%"
echo "Unauthorized processes: $UNAUTH_COUNT"
echo "Total ERROR entries across all logs: $TOTAL_ERRORS"
echo "Incident classification: $STATUS"
echo "Classification summary: $SUMMARY"
echo "----------------------------------------"
echo "Thresholds:"
echo "- CPU threshold: $CPU_THRESHOLD%"
echo "- ERROR threshold per log: $ERROR_THRESHOLD_PER_LOG"
echo "----------------------------------------"
echo "Triggered indicators:"
[ -z "$TRIGGERED_TEXT" ] && echo "None" || echo -e -n "$TRIGGERED_TEXT"
echo "----------------------------------------"
echo "Log summary:"
echo -e -n "$LOG_DETAILS"
echo "Most unstable log: $MOST_UNSTABLE ($MAX_ERRORS ERROR entries)"
echo "----------------------------------------"
echo "Unauthorized process details:"
[ -z "$UNAUTH_DETAILS" ] && echo "None" || echo -e -n "$UNAUTH_DETAILS"
} | tee "$REPORT_FILE"
