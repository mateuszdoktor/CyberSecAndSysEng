#!/bin/bash
count_info_all(){
 grep INFO $1*.log | wc -l
}

count_info(){
 grep INFO $1 | wc -l
}

count_warn(){
 grep WARN $1 | wc -l
}

count_error(){
 grep ERROR $1 | wc -l
}

echo "" > ../reports/lab3t7.txt

for file in $1*.log
do
 echo "$file:  $(grep ERROR $file | wc -l)" >> ../reports/lab3t7.txt
 echo "$file WARN: $(count_warn $file)" >> ../reports/lab3t7.txt
 echo "$file ERROR: $(count_error $file)" >> ../reports/lab3t7.txt
 echo "$file INFO: $(count_info $file)" >> ../reports/lab3t7.txt
 echo "" >> ../reports/lab3t7.txt
done

echo "Total number of INFO: $(count_info_all $1)" >> ../reports/lab3t7.txt
