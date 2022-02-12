#!/bin/bash -l
# This script will visit all web domains - multithreaded

URI=$1
THREADS=20

# Loop over user and domains
while read USER ; do
  while read DOMAIN ; do
    echo "$DOMAIN/$URI"
    curl -ILs -m $THREADS $DOMAIN/$URI &
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

