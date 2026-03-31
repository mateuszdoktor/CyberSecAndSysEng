#!/bin/bash
extract_timestamps(){
 grep $1 ../logs/*.log | cut -d " " -f2 > ../reports/pattern_timestamps.txt
}

for file in ../logs/*.log
do
 extract_timestamps $1
done
