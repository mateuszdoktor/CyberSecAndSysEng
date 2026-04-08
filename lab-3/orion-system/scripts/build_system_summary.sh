#!/bin/bash

echo "Total number of log entries: $(cat ../logs/*.log | wc -l)" > ../reports/system_summary.txt
echo "Total number of ERROR events: $(grep ERROR ../logs/*.log | wc -l)" >> ../reports/system_summary.txt
echo "Total number of WARN events: $(grep WARN ../logs/*.log | wc -l)" >> ../reports/system_summary.txt
echo "Total number of INFO events: $(grep INFO ../logs/*.log | wc -l)" >> ../reports/system_summary.txt
