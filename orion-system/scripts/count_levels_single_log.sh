#!/bin/bash

cut -d ' ' -f3 ./../logs/sat-002.log | sort | uniq -c
