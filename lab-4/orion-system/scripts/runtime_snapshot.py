#!/usr/bin/env python3
import sys
import datetime
import subprocess
import glob
import os

CPU_THRESHOLD = 50
ERROR_THRESHOLD_PER_LOG = 10
whitelist = {"bash", "sleep", "sshd", "systemd", "ps", "python3", "kworker"}

try:
    ps_all = subprocess.check_output(['ps', '-eo', 'pcpu,pid,comm', '--no-headers'], text=True).strip().split('\n')
    total_procs = len(ps_all)
except:
    ps_all, total_procs = [], 0

try:
    ps_top = subprocess.check_output(['ps', '-eo', 'pcpu,pid,comm', '--no-headers', '--sort=-pcpu'], text=True).strip().split('\n')[0]
    top_parts = ps_top.strip().split(None, 2)
    top_cpu, top_pid, top_name = float(top_parts[0]), top_parts[1], top_parts[2]
except:
    top_cpu, top_pid, top_name = 0.0, "0", "unknown"

unauth_count = 0
unauth_details = ""
for line in ps_all:
    if not line.strip(): continue
    parts = line.strip().split(None, 2)
    if len(parts) == 3:
        pid, name = parts[1], parts[2]
        if name not in whitelist and not name.startswith("kworker"):
            unauth_count += 1
            unauth_details += f"- PID={pid} PROC={name}\n"

total_errors = 0
max_errors = -1
most_unstable = "none"
log_files = glob.glob("../logs/*.log")
log_anomaly_val = 0

log_details = ""
for log_file in log_files:
    err_cnt = 0
    fname = os.path.basename(log_file)
    try:
        with open(log_file, 'r') as f:
            err_cnt = sum(1 for line in f if "ERROR" in line)
    except: pass
    
    total_errors += err_cnt
    log_details += f"- {fname}: {err_cnt} ERROR entries\n"
    if err_cnt > ERROR_THRESHOLD_PER_LOG: log_anomaly_val = 1
    if err_cnt > max_errors:
        max_errors = err_cnt
        most_unstable = fname

indicators = 0
triggered = ""
if top_cpu > CPU_THRESHOLD:
    indicators += 1
    triggered += f"- high CPU: top process {top_name} (PID={top_pid}) uses {top_cpu}% > threshold {CPU_THRESHOLD}%\n"

if unauth_count > 0:
    indicators += 1
    triggered += f"- unauthorized processes detected: {unauth_count}\n"

if log_anomaly_val == 1:
    indicators += 1
    triggered += f"- log anomaly: at least one mission log exceeds ERROR threshold {ERROR_THRESHOLD_PER_LOG}\n"

if indicators == 0:
    status = "NORMAL"
    summary = "no suspicious indicators were observed"
elif indicators == 1:
    status = "WARNING"
    summary = "exactly one suspicious indicator was observed"
else:
    status = "CRITICAL"
    summary = "at least two suspicious indicators were observed simultaneously"

now = datetime.datetime.now()
timestamp_str = now.strftime("%Y-%m-%d_%H-%M-%S")
report_file = f"../reports/runtime_snapshot_{timestamp_str}.txt"

snapshot_text = f"""========================================
Runtime Security Snapshot
========================================
Date and time: {now.strftime('%Y-%m-%d %H:%M:%S')}
Total active processes: {total_procs}
Top CPU process: PID={top_pid} PROC={top_name} CPU={top_cpu}%
Unauthorized processes: {unauth_count}
Total ERROR entries across all logs: {total_errors}
Incident classification: {status}
Classification summary: {summary}
----------------------------------------
Thresholds:
- CPU threshold: {CPU_THRESHOLD}%
- ERROR threshold per log: {ERROR_THRESHOLD_PER_LOG}
----------------------------------------
Triggered indicators:
{triggered if triggered else "None\n"}----------------------------------------
Log summary:
{log_details}Most unstable log: {most_unstable} ({max_errors} ERROR entries)
----------------------------------------
Unauthorized process details:
{unauth_details if unauth_details else "None\n"}"""

print(snapshot_text)
with open(report_file, 'w') as f:
    f.write(snapshot_text)
