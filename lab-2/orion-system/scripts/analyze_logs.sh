#!/bin/bash
TOTAL=$(cat ../logs/*.log | wc -l)
INFO_COUNT=$(grep "INFO" ../logs/*.log | wc -l)
WARN_COUNT=$(grep "WARN" ../logs/*.log | wc -l)
ERROR_COUNT=$(grep "ERROR" ../logs/*.log | wc -l)

LSTABLE=$(./identify_less_stable_satellite.sh)

echo "ORION LOG SUMMARY" > ../reports/log_summary.txt
echo "Total log entries: $TOTAL" >> ../reports/log_summary.txt
echo "INFO events: $INFO_COUNT" >> ../reports/log_summary.txt
echo "WARN events: $WARN_COUNT" >> ../reports/log_summary.txt
echo "ERROR events: $ERROR_COUNT" >> ../reports/log_summary.txt
echo "Less stable satellite: $LSTABLE" >> ../reports/log_summary.txt
