#!/bin/bash
count_warn_error_logs(){
 grep -e "WARN" -e "ERROR" $1 | wc -l
}

compute_all_satellites(){
for file in ../logs/*.log
do
 echo "$file: $(count_warn_error_logs $file)"
done
}

compute_all_satellites | sort -k2 -rn
