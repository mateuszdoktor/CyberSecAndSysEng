#!/bin/bash

WHITELIST=("bash" "sleep" "systemd", "Isolated Web Co")

AUTHORIZED_COUNT=0
UNAUTHORIZED_COUNT=0

is_whitelisted() {
    local proc_name=$1
    for authorized in "${WHITELIST[@]}"; do
        if [[ "$proc_name" == "$authorized" ]]; then
            return 0
        fi
    done
    return 1
}

while read -r pid name; do
    [ -z "$name" ] && continue

    if is_whitelisted "$name"; then
        echo "AUTHORIZED PROCESS: $name (PID: $pid)"
        ((AUTHORIZED_COUNT++))
    else
        echo "UNAUTHORIZED PROCESS: $name (PID: $pid)"
        ((UNAUTHORIZED_COUNT++))
    fi

done < <(ps -eo pid,comm --no-headers)

echo "TOTAL AUTHORIZED: $AUTHORIZED_COUNT"
echo "TOTAL UNAUTHORIZED: $UNAUTHORIZED_COUNT"
