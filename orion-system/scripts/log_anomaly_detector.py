#!/usr/bin/env python3
import sys
import glob
import os

if len(sys.argv) < 2:
    print(f"Usage: {sys.argv[0]} <ERROR_THRESHOLD>")
    sys.exit(1)

threshold = int(sys.argv[1])
max_errors = -1
most_unstable = ""

log_files = glob.glob("../logs/*.log")
if not log_files:
    print("No log files found.")
    sys.exit(0)

print("Processing log files...")
for log_file in log_files:
    file_name = os.path.basename(log_file)
    error_count = 0
    try:
        with open(log_file, 'r') as f:
            for line in f:
                if "ERROR" in line:
                    error_count += 1
    except Exception as e:
        continue
    
    print(f"{file_name}: {error_count} ERROR entries")
    if error_count > threshold:
        print(f"ALERT: log anomaly detected in {file_name}")
        
    if error_count > max_errors:
        max_errors = error_count
        most_unstable = file_name

if max_errors >= 0 and most_unstable:
    print(f"Most unstable log file: {most_unstable} ({max_errors} ERROR entries)")
