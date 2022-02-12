#!/bin/bash
# This script will rebuild all users

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# User list and rebuild
v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}' | while read USER ; do
  v-rebuild-user $USER no
  echo $USER
done

# Fix public_html premissions
chmod 755 /home/*/web/*/public_html

# Restart services
$CURRENT_DIR/restart-services.sh