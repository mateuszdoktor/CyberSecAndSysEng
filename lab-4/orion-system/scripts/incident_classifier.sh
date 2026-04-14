#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <CPU_THRESHOLD> <ERROR_THRESHOLD>"
    exit 1
fi

CPU_LIMIT=$1
ERROR_LIMIT=$2
WHITELIST=("bash" "sleep" "sshd" "systemd" "ps" "incident_classi" "awk" "grep" "bc" "kworker")

INDICATORS_COUNT=0

CPU_FOUND=0
while read -r cpu; do
    if (( $(echo "$cpu > $CPU_LIMIT" | bc -l) )); then
        CPU_FOUND=1
        break
    fi
done < <(ps -eo pcpu --no-headers)

[ "$CPU_FOUND" -eq 1 ] && ((INDICATORS_COUNT++))

UNAUTH_FOUND=0
while read -r name; do
    [ -z "$name" ] && continue
    MATCH=0
    for authorized in "${WHITELIST[@]}"; do
        if [[ "$name" == "$authorized" ]]; then
            MATCH=1
            break
        fi
    done
    if [ "$MATCH" -eq 0 ]; then
        UNAUTH_FOUND=1
        break
    fi
done < <(ps -u $USER -o comm --no-headers)

[ "$UNAUTH_FOUND" -eq 1 ] && ((INDICATORS_COUNT++))

LOG_FOUND=0
if ls ../logs/*.log >/dev/null 2>&1; then
    for log_file in ../logs/*.log; do
        error_count=$(grep -c "ERROR" "$log_file" | awk '{print $1}')
        if [ "$error_count" -gt "$ERROR_LIMIT" ]; then
            LOG_FOUND=1
            break
        fi
    done
fi

[ "$LOG_FOUND" -eq 1 ] && ((INDICATORS_COUNT++))

if [ "$INDICATORS_COUNT" -eq 0 ]; then
    echo "NORMAL"
elif [ "$INDICATORS_COUNT" -eq 1 ]; then
    echo "WARNING"
else
    echo "CRITICAL"
fi
