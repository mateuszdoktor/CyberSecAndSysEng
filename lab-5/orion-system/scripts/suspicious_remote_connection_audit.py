#!/usr/bin/env python3
import subprocess
import re

def main():
    try:
        output = subprocess.check_output(
            ['ss', '-tunp', 'state', 'established'],
            stderr=subprocess.STDOUT, 
            text=True
        )
    except FileNotFoundError:
        print("ss command not found")
        return
    except subprocess.CalledProcessError as e:
        output = e.output

    lines = output.strip().splitlines()
    data_lines = lines[1:] if len(lines) > 0 and 'Recv-Q' in lines[0] else lines

    count = 0
    for line in data_lines:
        if not line.strip() or line.startswith('ss:'):
            continue
        parts = line.split()
        if len(parts) >= 5:
            remote_endpoint = parts[4]
            
            remote_ip = remote_endpoint.rsplit(':', 1)[0]
            remote_ip = remote_ip.strip('[]')
            
            if remote_ip not in ('127.0.0.1', '::1', '*', '0.0.0.0', '192.168.64.1'): 
                pass

    count = 0
    for line in data_lines:
        if not line.strip() or line.startswith('ss:'):
            continue
        parts = line.split()
        if len(parts) >= 5:
            remote_endpoint = parts[4]
            
            remote_ip = remote_endpoint.rsplit(':', 1)[0]
            remote_ip = remote_ip.strip('[]')
            
            if remote_ip not in ('127.0.0.1', '::1'):
                
                process = "unknown"
                pid = "unknown"
                
                match = re.search(r'users:\(\("([^"]+)",pid=([0-9]+)', line)
                if match:
                    process = match.group(1)
                    pid = match.group(2)

                print(f"SUSPICIOUS CONNECTION: {process} {pid} -> {remote_endpoint}")
                count += 1

    if count == 0:
        print("NO SUSPICIOUS REMOTE CONNECTIONS DETECTED")
    else:
        print(f"\nTotal suspicious connections: {count}")

if __name__ == "__main__":
    main()
