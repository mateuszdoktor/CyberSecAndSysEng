#!/bin/bash
for file in ../logs/*.log; do
    errors=$(grep -c "ERROR" "$file")
    if [ "$errors" -eq 0 ]; then
        echo "$(basename "$file")"
    fi
done
