#!/usr/bin/env python3
import subprocess
import os
import sys
import datetime
from collections import Counter

def main():
    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    reports_dir = os.path.join(os.path.dirname(scripts_dir), 'reports')
    os.makedirs(reports_dir, exist_ok=True)
    
    time_str = datetime.datetime.now().strftime("%y-%m-%d-%H-%M-%S")
    report_file = os.path.join(reports_dir, f"mission_network_security_report-{time_str}.txt")

    listen_script = os.path.join(scripts_dir, 'listening_service_audit.py')
    estab_script = os.path.join(scripts_dir, 'established_connection_audit.py')
    exposed_script = os.path.join(scripts_dir, 'external_port_exposure_audit.py')
    susp_script = os.path.join(scripts_dir, 'suspicious_remote_connection_audit.py')
    cpu_script = os.path.join(scripts_dir, 'resource_usage_detector.py')
    log_script = os.path.join(scripts_dir, 'log_anomaly_detector.py')
    class_script = os.path.join(scripts_dir, 'network_incident_classifier.py')

    def get_lines(script_cmd, keyword):
        try:
            output = subprocess.check_output(script_cmd, stderr=subprocess.STDOUT, text=True)
            return [line for line in output.splitlines() if keyword in line]
        except Exception:
            return []

    listen_lines = get_lines([sys.executable, listen_script], "LISTENING SERVICE:")
    estab_lines = get_lines([sys.executable, estab_script], "ESTABLISHED CONNECTION:")
    exposed_lines = get_lines([sys.executable, exposed_script], "EXPOSED PORT:")
    susp_lines = get_lines([sys.executable, susp_script], "SUSPICIOUS CONNECTION:")
    
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

    cpu_lines = get_lines([sys.executable, cpu_script, '50', '50'], "WARNING: suspicious CPU usage")
    
    total_errors = 0
    try:
        log_out = subprocess.check_output([sys.executable, log_script, '0'], stderr=subprocess.STDOUT, text=True)
        for line in log_out.splitlines():
            if "ERROR entries" in line and ":" in line:
                try:
                    count = int(line.split(":")[1].strip().split()[0])
                    total_errors += count
                except ValueError:
                    pass
    except Exception:
        pass

    classification = "UNKNOWN"
    try:
        class_out = subprocess.check_output([sys.executable, class_script], stderr=subprocess.STDOUT, text=True)
        for line in class_out.splitlines():
            if line.startswith("CLASSIFICATION:"):
                classification = line.split()[-1]
    except Exception:
        pass

    report_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    report_content = f"""=== MISSION NETWORK SECURITY REPORT ===
TIME: {report_time}

[NETWORK STATE]
LISTENING SERVICES: {len(listen_lines)}
"""
    if len(estab_lines) == 0:
        report_content += "ESTABLISHED CONNECTIONS: 0 (NO ESTABLISHED CONNECTIONS PRESENT)\n"
    else:
        report_content += f"ESTABLISHED CONNECTIONS: {len(estab_lines)}\n"

    report_content += f"""UNEXPECTED EXPOSED PORTS: {len(exposed_lines)}
SUSPICIOUS REMOTE CONNECTIONS: {len(susp_lines)}
TOP PROCESS BY ESTABLISHED CONNECTIONS: {top_process}

[RUNTIME AND LOGS]
HIGH CPU PROCESSES: {len(cpu_lines)}
TOTAL LOG ERRORS: {total_errors}

[CLASSIFICATION]
FINAL CLASSIFICATION: {classification}

[COMPARISON]
No simulation: NORMAL expected (low metrics, expected ports).
Network simulation active: Exposed ports increase, suspicious outbound connections appear, resulting in elevated risk.
Load simulation active: High CPU processes appear, log errors might spike.
Both active: CRITICAL classification with all indicators showing anomalous activity.
"""

    print(report_content)
    
    with open(report_file, 'w') as f:
        f.write(report_content)
    
    print(f"Report saved to: {os.path.relpath(report_file, start=os.getcwd())}")

if __name__ == "__main__":
    main()