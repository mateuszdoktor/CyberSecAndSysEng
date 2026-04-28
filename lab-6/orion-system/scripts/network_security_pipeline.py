#!/usr/bin/env python3
import subprocess
import os
import sys
import time
import datetime
import argparse

def main():
    parser = argparse.ArgumentParser(description="Integrated Network Security Pipeline")
    parser.add_argument('mode', choices=['single', 'monitor', 'snapshot', 'report'], help="Execution mode")
    parser.add_argument('interval', nargs='?', type=int, default=10, help="Interval for monitor mode (seconds)")
    args = parser.parse_args()
    
    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    reports_dir = os.path.join(os.path.dirname(scripts_dir), 'reports')
    os.makedirs(reports_dir, exist_ok=True)
    
    required_scripts = [
        'external_port_exposure_audit.py',
        'listening_service_audit.py',
        'established_connection_audit.py',
        'suspicious_remote_connection_audit.py',
        'network_incident_classifier.py',
        'network_snapshot.py',
        'mission_network_security_report.py'
    ]
    
    for script in required_scripts:
        if not os.path.isfile(os.path.join(scripts_dir, script)):
            print(f"Error: Required script {script} not found in {scripts_dir}")
            sys.exit(1)
            
    def run_script(script_name, *script_args):
        script_path = os.path.join(scripts_dir, script_name)
        try:
            return subprocess.check_output([sys.executable, script_path] + list(script_args), stderr=subprocess.STDOUT, text=True)
        except subprocess.CalledProcessError as e:
            return e.output
        except FileNotFoundError:
            return f"Error: Command {sys.executable} {script_path} not found"
        except Exception as e:
            return f"Error executing script: {e}"

    if args.mode == 'single':
        print("=== NETWORK SECURITY PIPELINE (SINGLE RUN) ===")
        output_results = []
        
        output_results.append("=== 1. EXTERNAL PORT EXPOSURE AUDIT ===")
        output_results.append(run_script('external_port_exposure_audit.py'))
        output_results.append("=== 2. LISTENING SERVICE AUDIT ===")
        output_results.append(run_script('listening_service_audit.py'))
        output_results.append("=== 3. ESTABLISHED CONNECTION AUDIT ===")
        output_results.append(run_script('established_connection_audit.py'))
        output_results.append("=== 4. SUSPICIOUS REMOTE COMMUNICATION AUDIT ===")
        output_results.append(run_script('suspicious_remote_connection_audit.py'))
        output_results.append("=== 5. NETWORK INCIDENT CLASSIFICATION ===")
        output_results.append(run_script('network_incident_classifier.py'))
        
        full_res = "\n".join(output_results)
        print(full_res)
        
        time_str = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        report_file = os.path.join(reports_dir, f"pipeline_single_{time_str}.txt")
        try:
            with open(report_file, 'w') as f:
                f.write("=== NETWORK SECURITY PIPELINE CONFIGURATION: SINGLE RUN ===\n")
                f.write(full_res)
                f.write("\nPipeline execution completed successfully.\n")
            print(f"Aggregated results saved to {report_file}")
        except Exception as e:
            print(f"Skipped writing report: {e}")
            
    elif args.mode == 'monitor':
        print(f"Starting pipeline in monitor mode (interval: {args.interval}s). Press Ctrl+C to stop.")
        try:
            while True:
                time_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                print(f"\n[{time_str}] Running monitoring cycle...")
                
                cycle_res = run_script('network_snapshot.py')
                print(cycle_res)
                print("-" * 50)
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\nMonitoring stopped by user.")
            
    elif args.mode == 'snapshot':
        print(run_script('network_snapshot.py'))
        
    elif args.mode == 'report':
        print(run_script('mission_network_security_report.py'))
        
if __name__ == '__main__':
    main()
