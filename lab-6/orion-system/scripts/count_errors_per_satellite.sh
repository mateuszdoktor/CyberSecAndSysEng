#!/bin/bash
echo "sat-001.log number of ERROR logs"
grep ERROR ./../logs/sat-001.log | wc -l

echo "sat-002.log number of ERROR logs"
grep ERROR ./../logs/sat-002.log | wc -l
