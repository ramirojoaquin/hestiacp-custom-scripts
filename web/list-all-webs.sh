#!/bin/bash
# This script will list all web domains

while read USER ; do
  while read DOMAIN ; do
    echo $USER - $DOMAIN
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')
