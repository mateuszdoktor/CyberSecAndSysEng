#!/bin/bash
grep -c ERROR ./../logs/*.log | tail -1 |  xargs basename | cut -d '.' -f1
