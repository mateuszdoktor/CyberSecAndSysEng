#!/bin/bash
cat ../logs/*.log | grep -v "INFO" > ../reports/non_info.txt
count=$(wc -l < ../reports/non_info.txt)
echo "Total non-INFO entries: $count"
