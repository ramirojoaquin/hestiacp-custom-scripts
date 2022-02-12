#!/bin/bash
# This script will rebuild suspended users

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Listamos usuarios
v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}' | while read USER ; do
  SUSPENDED="$(v-list-user $USER | grep '^SUSPENDED*' | awk {'print $2'})"
  if [[ $SUSPENDED = "yes" ]]; then
    v-unsuspend-user $USER
    v-rebuild-user $USER no
    v-suspend-user $USER no
    echo $USER
  fi
done

# Restart services
$CURRENT_DIR/restart-services.sh