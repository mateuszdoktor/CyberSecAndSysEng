#!/bin/bash
for file in ../logs/*.log; do
    count=$(grep -c -E "WARN|ERROR" "$file")
    echo "$count $(basename "$file" .log)"
done | sort -nr | head -n 1
