#!/bin/bash

cut -d ' ' -f3 ./../logs/*.log | sort | uniq -c > ./../reports/level_summary.txt
