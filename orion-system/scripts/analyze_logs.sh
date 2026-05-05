#!/bin/bash

# Task 6: Organizing Scripts with Functions
count_info() {
    grep -sh "INFO" ../logs/*.log | wc -l | tr -d ' '
}

count_warn() {
    grep -sh "WARN" ../logs/*.log | wc -l | tr -d ' '
}

count_error() {
    grep -sh "ERROR" ../logs/*.log | wc -l | tr -d ' '
}

TOTAL=$(cat ../logs/*.log | wc -l | tr -d ' ')
INFO_COUNT=$(count_info)
WARN_COUNT=$(count_warn)
ERROR_COUNT=$(count_error)

LSTABLE=$(./identify_less_stable_satellite.sh)

# Task 7: Generating Dynamic Reports
echo "ORION LOG SUMMARY" > ../reports/log_summary.txt
echo "Total log entries: $TOTAL" >> ../reports/log_summary.txt
echo "INFO events: $INFO_COUNT" >> ../reports/log_summary.txt
echo "WARN events: $WARN_COUNT" >> ../reports/log_summary.txt
echo "ERROR events: $ERROR_COUNT" >> ../reports/log_summary.txt
echo "Less stable satellite: $LSTABLE" >> ../reports/log_summary.txt
