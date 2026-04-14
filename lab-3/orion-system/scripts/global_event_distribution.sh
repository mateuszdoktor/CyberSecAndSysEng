#!/bin/bash
cat ../logs/*.log | cut -d ' ' -f 3 | sort | uniq -c
