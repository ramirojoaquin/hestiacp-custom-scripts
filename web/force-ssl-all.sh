#!/bin/bash
# This script will force all web domains to use HTTPS

# Looop over users and domains
while read USER ; do
  while read DOMAIN ; do
    SSL="$(v-list-web-domain $USER $DOMAIN | grep '^SSL\:*' | awk {'print $2'})"
    if [[ "$SSL" == "yes" ]]; then
      echo "$USER - $DOMAIN"
      v-add-web-domain-ssl-force $USER $DOMAIN
    fi
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')