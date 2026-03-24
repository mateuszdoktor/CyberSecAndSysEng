#!/bin/bash
grep ERROR ./../logs/*.log > ./../reports/log_summary.txt
grep WARN ./../logs/*.log >> ./../reports/log_summary.txt
