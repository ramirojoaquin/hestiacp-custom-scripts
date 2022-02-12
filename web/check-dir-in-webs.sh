#!/bin/bash
# This script will list web domains containing a specific directory
USAGE="check-dir-in-webs.sh DIRECTORY"

if [ -z $1 ]; then
  echo "No directory entered"
  echo $USAGE
  exit 1
fi

DIR=$1

# Arrays setting
FOUND=()
NOT_FOUND=()

# Loop over users and domains
while read USER ; do
  while read DOMAIN ; do
    cd /home/$USER/web/$DOMAIN/public_html
      if [[ -d "$DIR" ]]; then
        FOUND+=("$USER | $DOMAIN")
      else
        NOT_FOUND+=("$USER | $DOMAIN")
      fi
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

printf '\n'
echo "-----------------------------------"
echo "${#FOUND[@]} web domains WITH directory $DIR:"
echo "-----------------------------------"
printf '%s\n' "${FOUND[@]}"
printf '\n'
echo "-----------------------------------"
echo "${#NOT_FOUND[@]} web domains WITHOUT directory $DIR:"
echo "-----------------------------------"
printf '%s\n' "${NOT_FOUND[@]}"
printf '\n'
echo "-----------------------------------"

