#!/bin/bash
file_logs(){
 echo "$1: $(grep $2 $1 | wc -l)"
}

echo "PATTERN REPORT: $1"

for file in ../logs/*.log
do
 file_logs $file $1
done
