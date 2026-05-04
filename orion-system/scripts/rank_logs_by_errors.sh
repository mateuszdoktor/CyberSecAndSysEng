#!/bin/bash
for file in ../logs/*.log; do
    count=$(grep -c "ERROR" "$file")
    echo "$file: $count"
done | sort -t: -k2 -nr
