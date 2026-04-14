#!/bin/bash

CPU_THRESHOLD=10
ERROR_THRESHOLD=5
WHITELIST=("bash" "sleep" "sshd" "systemd" "ps" "runtime_monitor" "awk" "grep" "bc")
INTERVAL=5

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="../reports/runtime_monitor_$TIMESTAMP.txt"

echo "Starting monitoring loop..."
echo "Interval: ${INTERVAL}s"
echo "Output: $REPORT_FILE"
echo "Press Ctrl+C to stop."

echo "===== Monitoring started: $(date +"%Y-%m-%d %H:%M:%S") =====" > "$REPORT_FILE"

while true; do
    CUR_DATE=$(date +"%Y-%m-%d %H:%M:%S")
    TOP_PROC_INFO=$(ps -eo comm,pid,pcpu --sort=-pcpu --no-headers | head -n 1)
    TOP_NAME=$(echo $TOP_PROC_INFO | awk '{print $1}')
    TOP_PID=$(echo $TOP_PROC_INFO | awk '{print $2}')
    TOP_CPU=$(echo $TOP_PROC_INFO | awk '{print $3}')

    UNAUTH_COUNT=0
    while read -r name; do
        [ -z "$name" ] && continue
        MATCH=0
        for authorized in "${WHITELIST[@]}"; do
            if [[ "$name" == "$authorized" ]]; then
                MATCH=1
                break
            fi
        done
        [ "$MATCH" -eq 0 ] && ((UNAUTH_COUNT++))
    done < <(ps -u $USER -o comm --no-headers)

    LOG_ANOMALY="NO"
    if ls ../logs/*.log >/dev/null 2>&1; then
        for log_file in ../logs/*.log; do
            error_count=$(grep -c "ERROR" "$log_file" | awk '{print $1}')
            if [ "$error_count" -gt "$ERROR_THRESHOLD" ]; then
                LOG_ANOMALY="YES"
                break
            fi
        done
    fi

    INDICATORS=0
    (( $(echo "$TOP_CPU > $CPU_THRESHOLD" | bc -l) )) && ((INDICATORS++))
    [ "$UNAUTH_COUNT" -gt 0 ] && ((INDICATORS++))
    [ "$LOG_ANOMALY" == "YES" ] && ((INDICATORS++))

    if [ "$INDICATORS" -eq 0 ]; then STATUS="NORMAL";
    elif [ "$INDICATORS" -eq 1 ]; then STATUS="WARNING";
    else STATUS="CRITICAL"; fi

    ENTRY="[$CUR_DATE] TOP_CPU: $TOP_NAME (PID=$TOP_PID, CPU=$TOP_CPU%) | UNAUTHORIZED: $UNAUTH_COUNT | LOG_ANOMALY: $LOG_ANOMALY | STATUS: $STATUS"
    echo "$ENTRY"
    echo "$ENTRY" >> "$REPORT_FILE"

    sleep $INTERVAL
done
