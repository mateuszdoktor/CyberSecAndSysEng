#!/bin/bash
for file in ../logs/*.log; do
    echo "$(grep -c "ERROR" "$file") $(basename "$file" .log)"
done | sort -nr | head -n 1 | awk '{print $2}'
