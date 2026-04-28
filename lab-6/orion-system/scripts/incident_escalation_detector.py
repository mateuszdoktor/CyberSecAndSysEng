#!/usr/bin/env python3
import time
import subprocess
import datetime
import re

rank = {"NORMAL": 0, "WARNING": 1, "CRITICAL": 2}

def get_status():
    output = subprocess.check_output(['./incident_classifier.py', '50', '10'], text=True)
    return output.strip()

previous = get_status()

print("Monitoring for escalation...")
try:
    while True:
        time.sleep(2)
        current = get_status()
        
        if rank.get(current, 0) > rank.get(previous, 0):
            print("ESCALATION DETECTED:")
            now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"Time: {now}")
            print(f"From: {previous}")
            print(f"To: {current}")
            break
            
        previous = current
except KeyboardInterrupt:
    print("\nStopped.")
