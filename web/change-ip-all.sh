#!/bin/bash
# This script will move all domains to an IP

if [ -z $1 ]; then
  echo "No IP entered"
  exit 1
fi

IP=$1

# Loop over users and domains
while read USER ; do
  while read DOMAIN ; do
    v-change-web-domain-ip $USER $DOMAIN $IP no
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')


