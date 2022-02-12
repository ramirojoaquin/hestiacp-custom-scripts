#!/bin/bash -l
# This script will show current nginx connections

for run in {1..1000}
do
  netstat -an | grep -E ":80|:443" | grep ESTABLISHED | wc -l
  sleep 0.2s
done
