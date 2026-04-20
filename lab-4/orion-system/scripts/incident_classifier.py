#!/usr/bin/env python3
import sys
import subprocess
import glob

if len(sys.argv) < 3:
    print(f"Usage: {sys.argv[0]} <CPU_THRESHOLD> <ERROR_THRESHOLD>")
    sys.exit(1)

cpu_limit = float(sys.argv[1])
error_limit = int(sys.argv[2])
whitelist = {"bash", "sleep", "sshd", "systemd", "ps", "python3", "awk", "grep", "bc", "kworker"}

indicators = 0

try:
    ps_cpu = subprocess.check_output(['ps', '-eo', 'pcpu', '--no-headers'], text=True)
    for cpu in ps_cpu.strip().split('\n'):
        if cpu.strip() and float(cpu.strip()) > cpu_limit:
            indicators += 1
            break
except Exception:
    pass

try:
    ps_comm = subprocess.check_output(['ps', '-eo', 'comm', '--no-headers'], text=True)
    for name in ps_comm.strip().split('\n'):
        name = name.strip()
        if name and name not in whitelist and not name.startswith("kworker"):
            indicators += 1
            break
except Exception:
    pass

log_files = glob.glob("../logs/*.log")
log_found = False
for file in log_files:
    try:
        with open(file, 'r') as f:
            err_count = sum(1 for line in f if "ERROR" in line)
            if err_count > error_limit:
                log_found = True
                break
    except:
        pass
if log_found:
    indicators += 1

if indicators == 0:
    print("NORMAL")
elif indicators == 1:
    print("WARNING")
else:
    print("CRITICAL")
