#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ERROR_THRESHOLD>"
    exit 1
fi

THRESHOLD=$1
MAX_ERRORS=-1
MOST_UNSTABLE_FILE=""

echo "Processing log files..."

for log_file in ../logs/*.log; do
    [ -e "$log_file" ] || continue

    file_name=$(basename "$log_file")

    error_count=$(grep -c "ERROR" "$log_file" | awk '{print $1}')

    echo "$file_name: $error_count ERROR entries"

    if [ "$error_count" -gt "$THRESHOLD" ]; then
        echo "ALERT: log anomaly detected in $file_name"
    fi

    if [ "$error_count" -gt "$MAX_ERRORS" ]; then
        MAX_ERRORS=$error_count
        MOST_UNSTABLE_FILE=$file_name
    fi
done

if [ "$MAX_ERRORS" -ge 0 ] && [ -n "$MOST_UNSTABLE_FILE" ]; then
    echo "Most unstable log file: $MOST_UNSTABLE_FILE ($MAX_ERRORS ERROR entries)"
fi
