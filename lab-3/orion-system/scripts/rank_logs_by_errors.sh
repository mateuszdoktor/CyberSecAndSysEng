#!/bin/bash
error_logs(){
 grep ERROR $1 | wc -l
}

compute_all_files(){
for file in ../logs/*.log
do
 echo "$file $(error_logs $file)"
done
}

compute_all_files | sort -k2 -rn
