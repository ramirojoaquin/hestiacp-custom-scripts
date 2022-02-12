#!/bin/bash
# This script will correct permissions for public_html on all web domains

while read USER ; do
  while read DOMAIN ; do
    echo $USER - $DOMAIN
    chown -R $USER:$USER /home/$USER/web/$DOMAIN/public_html
    chmod 755 /home/$USER/web/$DOMAIN/public_html
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')


