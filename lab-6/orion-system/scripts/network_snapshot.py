#!/usr/bin/env python3
import subprocess
import os
import datetime
from collections import Counter

def main():
    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    
    listening_script = os.path.join(scripts_dir, 'listening_service_audit.py')
    established_script = os.path.join(scripts_dir, 'established_connection_audit.py')
    exposed_script = os.path.join(scripts_dir, 'external_port_exposure_audit.py')
    suspicious_script = os.path.join(scripts_dir, 'suspicious_remote_connection_audit.py')
    classifier_script = os.path.join(scripts_dir, 'network_incident_classifier.py')

    import sys
    def get_lines(script_path, keyword):
        try:
            output = subprocess.check_output([sys.executable, script_path], stderr=subprocess.STDOUT, text=True)
            return [line for line in output.splitlines() if keyword in line]
        except Exception:
            return []

    listen_lines = get_lines(listening_script, "LISTENING SERVICE:")
    estab_lines = get_lines(established_script, "ESTABLISHED CONNECTION:")
    exposed_lines = get_lines(exposed_script, "EXPOSED PORT:")
    susp_lines = get_lines(suspicious_script, "SUSPICIOUS CONNECTION:")

    processes = []
    for line in estab_lines:
        parts = line.split()
        if len(parts) >= 6:
            pid = parts[-1]
            proc = parts[-2]
            processes.append(f"{proc}/{pid}")
    
    top_process = "NONE"
    if processes:
        counter = Counter(processes)
        most_common = counter.most_common(1)[0]
        top_process = f"{most_common[0]} ({most_common[1]})"

    classification = "UNKNOWN"
    try:
        output = subprocess.check_output([sys.executable, classifier_script], stderr=subprocess.STDOUT, text=True)
        for line in output.splitlines():
            if line.startswith("CLASSIFICATION:"):
                classification = line.split()[-1]
    except Exception:
        pass

    print("=== NETWORK SNAPSHOT ===")
    print(f"TIME: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"LISTENING SERVICES: {len(listen_lines)}")
    if len(estab_lines) == 0:
        print("ESTABLISHED CONNECTIONS: 0 (NO ESTABLISHED CONNECTIONS PRESENT)")
    else:
        print(f"ESTABLISHED CONNECTIONS: {len(estab_lines)}")
    print(f"UNEXPECTED EXPOSED PORTS: {len(exposed_lines)}")
    print(f"SUSPICIOUS REMOTE CONNECTIONS: {len(susp_lines)}")
    print(f"TOP PROCESS BY ESTABLISHED CONNECTIONS: {top_process}")
    print(f"CLASSIFICATION: {classification}")

if __name__ == "__main__":
    main()
