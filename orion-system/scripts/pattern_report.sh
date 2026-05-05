#!/bin/bash

if [ -z "$1" ]; then
    echo "Missing argument: search pattern is required"
    exit 1
fi

PATTERN=$1
OUTPUT="../reports/pattern_report.txt"
> "$OUTPUT"
echo "PATTERN REPORT: ${PATTERN}" >> "$OUTPUT"

for file in ../logs/*.log; do
    count=$(grep -c "$PATTERN" "$file")
    echo "$file: $count" >> "$OUTPUT"
done
