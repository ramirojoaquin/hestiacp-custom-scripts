#!/bin/bash -l
# This script will clear cache directories of wordpress and drupal

# User and domains loop
while read USER ; do
  if [[ -d /home/$USER/web/*/public_html/wp-content/cache/ ]]; then
    echo $USER
    rm -rf /home/$USER/web/*/public_html/wp-content/cache/*
  fi
  if [[ -d /home/$USER/web/*/public_html/cache/ ]]; then
    echo $USER
    rm -rf /home/$USER/web/*/public_html/cache/*
  fi
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')
