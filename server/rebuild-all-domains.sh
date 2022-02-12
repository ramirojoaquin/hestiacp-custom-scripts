#!/bin/bash
# This script will rebuild all web and mail domains

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# User list and rebuild all domains
v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}' | while read USER ; do
  echo $USER
  v-rebuild-web-domains $USER no
  v-rebuild-mail-domains $USER no
done

# Fix public_html premissions
chmod 755 /home/*/web/*/public_html

# Restart services
$CURRENT_DIR/restart-services.sh