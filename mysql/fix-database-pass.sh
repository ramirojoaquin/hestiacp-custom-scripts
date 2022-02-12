#!/bin/bash
# This script will loop over all wordpress, and fix database credentials based on what is present in wp-config.php
# USE THIS UNDER YOUR OWN RESPONSABILITY

while read USER ; do
  while read DOMAIN ; do
    WP_CONFIG=/home/$USER/web/$DOMAIN/public_html/wp-config.php
    if [[ -f $WP_CONFIG ]]; then
      DBNAME=`cat $WP_CONFIG | grep DB_NAME | cut -d \' -f 4`
      DBUSER=`cat $WP_CONFIG | grep DB_USER | cut -d \' -f 4`
      DBPASS=`cat $WP_CONFIG | grep DB_PASSWORD | cut -d \' -f 4`
      DBUSER_FIX=${DBUSER#"$USER""_"}
      echo "$USER, $DBNAME, $DBUSER_FIX, $DBPASS"
      v-change-database-user $USER $DBNAME $DBUSER_FIX $DBPASS
    fi
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')
