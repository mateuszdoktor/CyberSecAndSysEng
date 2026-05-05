#!/bin/bash
for file in ../logs/*.log; do
    cut -d ' ' -f 5- "$file" | sort -u
done | sort | uniq -d
