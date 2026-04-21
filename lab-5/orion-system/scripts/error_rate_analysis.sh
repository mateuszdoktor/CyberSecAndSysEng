#!/bin/bash
for file in ../logs/*.log; do
    total=$(wc -l < "$file")
    errors=$(grep -c "ERROR" "$file")
    if [ "$total" -gt 0 ]; then
        awk -v t="$total" -v e="$errors" -v f="$(basename "$file" .log)" 'BEGIN { printf "%f %s\n", (e/t), f }'
    fi
done | sort -nr | head -n 1 | awk '{print "Highest error rate: " $2 " (" $1 ")"}'
