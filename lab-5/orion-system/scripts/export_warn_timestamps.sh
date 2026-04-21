#!/bin/bash
grep WARN ./../logs/*.log | cut -d ' ' -f2 > ./../reports/warn_timestamps.txt
