#!/usr/bin/env python3
import subprocess

whitelist = {"bash", "sleep", "sshd", "systemd", "ps", "kworker"}

try:
    ps_output = subprocess.check_output(['ps', '-eo', 'pid,comm', '--no-headers'], text=True)
    authorized = 0
    unauthorized = 0
    for line in ps_output.strip().split('\n'):
        parts = line.strip().split(None, 1)
        if len(parts) == 2:
            pid, name = parts
            if name in whitelist or name.startswith("kworker"):
                print(f"AUTHORIZED PROCESS: {name} (PID: {pid})")
                authorized += 1
            else:
                print(f"UNAUTHORIZED PROCESS: {name} (PID: {pid})")
                unauthorized += 1
    print(f"TOTAL AUTHORIZED: {authorized}")
    print(f"TOTAL UNAUTHORIZED: {unauthorized}")
except Exception as e:
    print(f"Error: {e}")
