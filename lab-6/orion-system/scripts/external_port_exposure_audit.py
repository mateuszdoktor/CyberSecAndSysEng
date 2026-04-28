#!/usr/bin/env python3
import subprocess
import re

EXPECTED_PORTS = {5000, 6000}

def main():
    try:
        output = subprocess.check_output(
            ['nmap', '-Pn', '-n', '--open', '-p-', '127.0.0.1'], 
            stderr=subprocess.STDOUT, 
            text=True
        )
    except FileNotFoundError:
        print("nmap command not found")
        return
    except subprocess.CalledProcessError as e:
        output = e.output

    unexpected_count = 0
    for line in output.splitlines():
        match = re.search(r'^(\d+)/tcp\s+open', line)
        if match:
            port = int(match.group(1))
            if port not in EXPECTED_PORTS:
                print(f"EXPOSED PORT: {port}")
                unexpected_count += 1
                
    if unexpected_count == 0:
        print("NO UNEXPECTED EXPOSED PORTS")
    else:
        print(f"\nTotal unexpected exposed ports: {unexpected_count}")

if __name__ == "__main__":
    main()
