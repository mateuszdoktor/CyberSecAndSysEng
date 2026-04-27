#!/bin/bash

if [ -z "$1" ]; then
    echo "Missing argument: file pattern is required"
    exit 1
fi

OUTPUT="../reports/mission_report.txt"

files_count=0
entries_count=0
info_count=0
warn_count=0
error_count=0
highest_errors=-1
unstable_log=""

for file in $@; do
    if [ -f "$file" ]; then
        files_count=$((files_count + 1))
        
        lines=$(wc -l < "$file")
        entries_count=$((entries_count + lines))
        
        info=$(grep -c "INFO" "$file")
        warn=$(grep -c "WARN" "$file")
        error=$(grep -c "ERROR" "$file")
        
        info_count=$((info_count + info))
        warn_count=$((warn_count + warn))
        error_count=$((error_count + error))
        
        if [ "$error" -gt "$highest_errors" ]; then
            highest_errors=$error
            unstable_log=$(basename "$file")
        fi
    fi
done

> "$OUTPUT"
echo "MISSION REPORT" >> "$OUTPUT"
echo "Processed files: $files_count" >> "$OUTPUT"
echo "Total entries: $entries_count" >> "$OUTPUT"
echo "INFO: $info_count" >> "$OUTPUT"
echo "WARN: $warn_count" >> "$OUTPUT"
echo "ERROR: $error_count" >> "$OUTPUT"
echo "Most unstable log: $unstable_log" >> "$OUTPUT"
