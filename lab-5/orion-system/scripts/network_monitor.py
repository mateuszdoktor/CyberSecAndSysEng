#!/usr/bin/env python3
import subprocess
import os
import time
import datetime

def main():
    interval = 10 
    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    reports_dir = os.path.join(os.path.dirname(scripts_dir), 'reports')
    os.makedirs(reports_dir, exist_ok=True)
    report_file = os.path.join(reports_dir, f'network_monitoring_{time.strftime("%Y%m%d_%H%M%S")}.txt')

    print(f"Starting network monitor. Saving reports to {report_file}. Press Ctrl+C to stop.")
    
    listening_script = os.path.join(scripts_dir, 'listening_service_audit.py')
    established_script = os.path.join(scripts_dir, 'established_connection_audit.py')
    exposed_script = os.path.join(scripts_dir, 'external_port_exposure_audit.py')
    suspicious_script = os.path.join(scripts_dir, 'suspicious_remote_connection_audit.py')
    classifier_script = os.path.join(scripts_dir, 'network_incident_classifier.py')

    import sys
    def get_count(script_path, keyword):
        try:
            output = subprocess.check_output([sys.executable, script_path], stderr=subprocess.STDOUT, text=True)
            return sum(1 for line in output.splitlines() if keyword in line)
        except Exception:
            return 0

    def get_classification():
        try:
            output = subprocess.check_output([sys.executable, classifier_script], stderr=subprocess.STDOUT, text=True)
            for line in output.splitlines():
                if line.startswith("CLASSIFICATION:"):
                    return line.split()[-1]
        except Exception:
            return "UNKNOWN"

    try:
        with open(report_file, 'a') as f:
            while True:
                timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                listen_count = get_count(listening_script, "LISTENING SERVICE:")
                estab_count = get_count(established_script, "ESTABLISHED CONNECTION:")
                exposed_count = get_count(exposed_script, "EXPOSED PORT:")
                suspicious_count = get_count(suspicious_script, "SUSPICIOUS CONNECTION:")
                classification = get_classification()

                log_entry = f"{timestamp} LISTEN={listen_count} ESTAB={estab_count} EXPOSED={exposed_count} SUSPICIOUS={suspicious_count} CLASS={classification}"
                print(log_entry)
                f.write(log_entry + "\n")
                f.flush()
                time.sleep(interval)
    except KeyboardInterrupt:
        print("\nMonitoring stopped by user.")

if __name__ == "__main__":
    main()
