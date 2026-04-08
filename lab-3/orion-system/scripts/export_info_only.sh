#!/bin/bash
grep INFO ../logs/*.log | cut -d ' ' -f 4- > ../reports/info_only.txt 
