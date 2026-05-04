#!/usr/bin/env python3
import datetime
import subprocess
import os
import glob

CPU_THRESHOLD = 50
ERROR_THRESHOLD_PER_LOG = 10
whitelist = {"bash", "sleep", "sshd", "systemd", "ps", "python3", "kworker"}

now = datetime.datetime.now()
timestamp = now.strftime("%Y-%m-%d_%H-%M-%S")
report_file = f"../reports/mission_runtime_security_report_{timestamp}.txt"

try:
    ps_all = subprocess.check_output(['ps', '-eo', 'pcpu,pid,comm', '--no-headers'], text=True).strip().split('\n')
    active_procs = len(ps_all)
except:
    ps_all, active_procs = [], 0

try:
    ps_top = subprocess.check_output(['ps', '-eo', 'pcpu,pid,comm', '--no-headers', '--sort=-pcpu'], text=True).strip().split('\n')[0]
    top_parts = ps_top.strip().split(None, 2)
    top_cpu, top_pid, top_name = float(top_parts[0]), top_parts[1], top_parts[2]
except:
    top_cpu, top_name = 0.0, "unknown"

unauth_count = 0
high_cpu_count = 0
for line in ps_all:
    if not line.strip(): continue
    parts = line.strip().split(None, 2)
    if len(parts) == 3:
        cpu = float(parts[0])
        name = parts[2]
        if cpu > CPU_THRESHOLD: high_cpu_count += 1
        if name not in whitelist and not name.startswith("kworker"):
            unauth_count += 1

log_files = glob.glob("../logs/*.log")
total_errors = 0
max_errors = -1
most_unstable = "none"
log_anomaly_val = 0

for log_file in log_files:
    fname = os.path.basename(log_file)
    err_cnt = 0
    try:
        with open(log_file, 'r') as f:
            err_cnt = sum(1 for line in f if "ERROR" in line)
    except: pass
    total_errors += err_cnt
    if err_cnt > ERROR_THRESHOLD_PER_LOG: log_anomaly_val = 1
    if err_cnt > max_errors:
        max_errors = err_cnt
        most_unstable = fname

indicators = 0
if top_cpu > CPU_THRESHOLD: indicators += 1
if unauth_count > 0: indicators += 1
if log_anomaly_val == 1: indicators += 1

if indicators == 0: classification = "NORMAL"
elif indicators == 1: classification = "WARNING"
else: classification = "CRITICAL"

report = f"""MISSION RUNTIME SECURITY REPORT
Generated at: {timestamp}
Processed log files: {len(log_files)}
Active processes: {active_procs}
Unauthorized processes: {unauth_count}
High CPU processes: {high_cpu_count}
ERROR entries: {total_errors}
Most unstable log: {most_unstable}
Top CPU process: {top_name}
Incident classification: {classification}
"""

with open(report_file, 'w') as f:
    f.write(report)

print(report)
