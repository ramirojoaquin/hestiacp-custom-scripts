#!/bin/bash
# This script will list all web templates

# Loop over users and domains
while read USER ; do
  while read DOMAIN ; do
    CURRENT_TEMPLATE="$(v-list-web-domain $USER $DOMAIN | grep '^TEMPLATE*' | awk {'print $2'})"
    echo "$CURRENT_TEMPLATE --- $USER --- $DOMAIN"
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')
