#!/usr/bin/env python3
import subprocess
import os

def main():
    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    
    exposed_script = os.path.join(scripts_dir, 'external_port_exposure_audit.py')
    suspicious_script = os.path.join(scripts_dir, 'suspicious_remote_connection_audit.py')
    cpu_script = os.path.join(scripts_dir, 'resource_usage_detector.py')
    log_anomaly_script = os.path.join(scripts_dir, 'log_anomaly_detector.py')

    import sys
    def check_active(cmd, keyword):
        full_cmd = [sys.executable] + cmd
        try:
            output = subprocess.check_output(full_cmd, stderr=subprocess.STDOUT, text=True)
            return "ACTIVE" if keyword in output else "INACTIVE"
        except Exception as e:
            return "INACTIVE"

    exposed_status = check_active([exposed_script], "EXPOSED PORT:")
    suspicious_status = check_active([suspicious_script], "SUSPICIOUS CONNECTION:")

    cpu_status = check_active([cpu_script, '50', '50'], "WARNING: suspicious CPU usage")
    log_status = check_active([log_anomaly_script, '3'], "ALERT: log anomaly")

    indicators = {
        "Unexpected Exposed Ports": exposed_status,
        "Suspicious Remote Connections": suspicious_status,
        "High CPU Process": cpu_status,
        "Log Anomaly": log_status
    }

    active_count = sum(1 for status in indicators.values() if status == "ACTIVE")

    if active_count == 0:
        classification = "NORMAL"
    elif active_count == 1:
        classification = "WARNING"
    else:
        classification = "CRITICAL"

    print("=== INCIDENT CLASSIFICATION ===")
    for name, status in indicators.items():
        print(f"{name}: {status}")
    print(f"Total Active Indicators: {active_count}")
    print(f"CLASSIFICATION: {classification}")

if __name__ == "__main__":
    main()
