#!/bin/bash
echo "sat-001.log number of WARN events"
grep WARN ./../logs/sat-001.log | wc -l

echo "sat-002.log number of WARN events"
grep WARN ./../logs/sat-002.log | wc -l
