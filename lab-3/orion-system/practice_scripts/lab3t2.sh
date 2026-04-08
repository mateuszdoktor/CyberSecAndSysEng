#!/bin/bash
if [ -z "$1" ]
then
 echo "Missing arg1"
fi

if [ -z "$2" ]
then
 echo "Missing arg2"
fi

grep $1 $2*.log | wc -l
