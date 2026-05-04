#!/usr/bin/env python3
import time
import subprocess
import re

def get_snapshot():
    output = subprocess.check_output(['./runtime_snapshot.py'], text=True)
    top_cpu = re.search(r'Top CPU process: PID=\d+ PROC=(\S+)', output).group(1)
    unauth = re.search(r'Unauthorized processes: (\d+)', output).group(1)
    status = re.search(r'Incident classification: (\w+)', output).group(1)
    return top_cpu, int(unauth), status

print("Taking first snapshot...")
top1, unauth1, status1 = get_snapshot()

print("Waiting 5 seconds...")
time.sleep(5)

print("Taking second snapshot...")
top2, unauth2, status2 = get_snapshot()

print("\nSTATE CHANGE DETECTED:")
if top1 == top2:
    print("Top CPU process changed: NO")
else:
    print(f"Top CPU process changed: YES ({top1} -> {top2})")

if unauth1 == unauth2:
    print("Unauthorized process count changed: NO")
else:
    print(f"Unauthorized process count changed: YES ({unauth1} -> {unauth2})")

if status1 == status2:
    print("Incident classification changed: NO")
else:
    print(f"Incident classification changed: YES ({status1} -> {status2})")
