#!/usr/bin/env python3
import subprocess

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

    import re

    count = 0
    for line in data_lines:
        if not line.strip() or line.startswith('ss:'):
            continue
        parts = line.split()
        if len(parts) >= 5:
            local_endpoint = parts[3]
            remote_endpoint = parts[4]
            
            process = "unknown"
            pid = "unknown"
            
            match = re.search(r'users:\(\("([^"]+)",pid=([0-9]+)', line)
            if match:
                process = match.group(1)
                pid = match.group(2)

            print(f"ESTABLISHED CONNECTION: {local_endpoint} -> {remote_endpoint} {process} {pid}")
            count += 1

    if count == 0:
        print("NO ESTABLISHED CONNECTIONS DETECTED")
    else:
        print(f"\nTotal established connections: {count}")

if __name__ == "__main__":
    main()
