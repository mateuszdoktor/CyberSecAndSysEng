#!/usr/bin/env python3
import sys
import time
import datetime
import subprocess
import glob
import os
import signal

INTERVAL = 5
CPU_THRESHOLD = 50
ERROR_THRESHOLD = 10
whitelist = {"bash", "sleep", "sshd", "systemd", "ps", "python3", "kworker"}
stop_requested = False

def handle_stop(signum, frame):
    global stop_requested
    stop_requested = True

signal.signal(signal.SIGINT, handle_stop)
signal.signal(signal.SIGTERM, handle_stop)

print("Starting monitoring loop...")
print(f"Interval: {INTERVAL}s")
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
report_file = f"../reports/runtime_monitor_{timestamp}.txt"
print(f"Output: {report_file}")
print("Press Ctrl+C to stop.")
print("-" * 40)

init_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
init_msg = f"===== Monitoring started: {init_time} ====="
print(init_msg)

with open(report_file, 'w') as f:
    f.write(init_msg + "\n")

try:
    while True:
        cur_date_full = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        try:
            ps_out = subprocess.check_output(['ps', '-eo', 'pcpu,pid,comm', '--no-headers', '--sort=-pcpu'], text=True)
            top_line = ps_out.strip().split('\n')[0].strip().split(None, 2)
            top_cpu, top_pid, top_name = float(top_line[0]), top_line[1], top_line[2]
        except:
            top_cpu, top_pid, top_name = 0.0, "0", "unknown"
        
        unauth_count = 0
        try:
            ps_comm = subprocess.check_output(['ps', '-eo', 'comm', '--no-headers'], text=True)
            for name in ps_comm.strip().split('\n'):
                name = name.strip()
                if name and name not in whitelist and not name.startswith("kworker"):
                    unauth_count += 1
        except:
            pass

        log_anomaly = "NO"
        log_anomaly_val = 0
        for file in glob.glob("../logs/*.log"):
            try:
                with open(file, 'r') as f:
                    err_count = sum(1 for line in f if "ERROR" in line)
                    if err_count > ERROR_THRESHOLD:
                        log_anomaly = "YES"
                        log_anomaly_val = 1
                        break
            except:
                pass

        indicators = 0
        if top_cpu > CPU_THRESHOLD: indicators += 1
        if unauth_count > 0: indicators += 1
        if log_anomaly_val == 1: indicators += 1

        if indicators == 0: status = "NORMAL"
        elif indicators == 1: status = "WARNING"
        else: status = "CRITICAL"

        entry = f"[{cur_date_full}] TOP_CPU: {top_name} (PID={top_pid}, CPU={top_cpu}%) | UNAUTHORIZED: {unauth_count} | LOG_ANOMALY: {log_anomaly} | STATUS: {status}"
        print(entry)
        with open(report_file, 'a') as f:
            f.write(entry + "\n")
            
        time.sleep(INTERVAL)
        if stop_requested:
            break
except KeyboardInterrupt:
    pass
finally:
    print("\nMonitoring stopped.")
