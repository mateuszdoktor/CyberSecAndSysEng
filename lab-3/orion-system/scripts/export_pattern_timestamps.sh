#!/bin/bash

if [ -z "$1" ]; then
    echo "Missing argument: search pattern is required"
    exit 1
fi

PATTERN=$1
grep -h "$PATTERN" ../logs/*.log | cut -d " " -f1,2 > ../reports/pattern_timestamps.txt
