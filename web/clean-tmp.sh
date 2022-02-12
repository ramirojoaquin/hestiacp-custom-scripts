#!/bin/bash -l
# This script will remove tmp dir in all users and create it again, setting correct permissions

# Loop over users and domains
while read USER ; do
  if [[ -d /home/$USER/tmp ]]; then
    echo $USER
    rm -rf /home/$USER/tmp
    mkdir -p /home/$USER/tmp
    chown -R $USER:$USER /home/$USER/tmp
    chmod -R 1777 /home/$USER/tmp
  fi
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')
