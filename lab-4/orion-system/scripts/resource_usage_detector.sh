#!/bin/bash

CPU_LIMIT=$1
MEM_LIMIT=$2

ps -eo pcpu,pmem,pid,comm --no-headers | while read -r cpu mem pid name; do
    if (( $(echo "$cpu > $CPU_LIMIT" | bc -l) )); then
        echo "WARNING: suspicious CPU usage: $name (PID: $pid)"
    fi

    if (( $(echo "$mem > $MEM_LIMIT" | bc -l) )); then
        echo "WARNING: suspicious memory usage: $name (PID: $pid)"
    fi
done

