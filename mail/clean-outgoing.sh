#!/bin/bash -l
# Clean outgoing email copyes older than X days

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

# Loop over admin emails domains and perform cleaning
while read DOMAIN ; do
  if [[ -d /home/admin/mail/$DOMAIN/outgoing/cur/ ]]; then
    /usr/bin/find /home/admin/mail/$DOMAIN/outgoing/cur/ -mtime +$OUTGOING_EMAILS_DAYS -exec rm {} \;
  fi
  if [[ -d /home/admin/mail/$DOMAIN/outgoing/new/ ]]; then
    /usr/bin/find /home/admin/mail/$DOMAIN/outgoing/new/ -mtime +$OUTGOING_EMAILS_DAYS -exec rm {} \;
  fi
done < <(v-list-web-domains admin | cut -d " " -f1 | awk '{if(NR>2)print}')