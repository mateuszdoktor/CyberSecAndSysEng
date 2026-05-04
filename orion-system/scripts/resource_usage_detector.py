#!/usr/bin/env python3
import sys
import subprocess

if len(sys.argv) < 3:
    print(f"Usage: {sys.argv[0]} <CPU_THRESHOLD> <MEMORY_THRESHOLD>")
    sys.exit(1)

cpu_limit = float(sys.argv[1])
mem_limit = float(sys.argv[2])

ps_output = subprocess.check_output(['ps', '-eo', 'pcpu,pmem,pid,comm', '--no-headers'], text=True)
for line in ps_output.strip().split('\n'):
    parts = line.split(None, 3)
    if len(parts) >= 4:
        cpu = float(parts[0])
        mem = float(parts[1])
        pid = parts[2]
        name = parts[3]
        
        if cpu > cpu_limit:
            print(f"WARNING: suspicious CPU usage: {name} (PID: {pid})")
        if mem > mem_limit:
            print(f"WARNING: suspicious memory usage: {name} (PID: {pid})")
