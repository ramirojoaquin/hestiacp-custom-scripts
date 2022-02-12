#!/bin/bash
# This script will replace a web template with another web template

USAGE="change-web-templates-all.sh OLDTEMPLATE NEWTEMPLATE"
if [ -z $1 ]; then
  echo "No old template entered"
  echo $USAGE
  exit 1
fi

if [ -z $2 ]; then
  echo "No new template entered"
  echo $USAGE
  exit 1
fi

OLD_TEMPLATE=$1
NEW_TEMPLATE=$2

# Loop over users and domains
while read USER ; do
  while read DOMAIN ; do
    CURRENT_TEMPLATE="$(v-list-web-domain $USER $DOMAIN | grep '^TEMPLATE*' | awk {'print $2'})"
    if [ $CURRENT_TEMPLATE = $OLD_TEMPLATE ]; then
      v-change-web-domain-tpl $USER $DOMAIN $NEW_TEMPLATE
    fi
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')


