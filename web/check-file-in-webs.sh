#!/bin/bash
# This script will list web domains containing a specific file path
USAGE="check-file-in-webs.sh FILEPATH"

if [ -z $1 ]; then
  echo "No file path entered"
  echo $USAGE
  exit 1
fi

FILE=$1

# Arrays setting
FOUND=()
NOT_FOUND=()

# Loop over users and domains
while read USER ; do
  while read DOMAIN ; do
    cd /home/$USER/web/$DOMAIN/public_html
      if [[ -f "$FILE" ]]; then
        FOUND+=("$USER | $DOMAIN")
      else
        NOT_FOUND+=("$USER | $DOMAIN")
      fi
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

printf '\n'
echo "-----------------------------------"
echo "${#FOUND[@]} web domains WITH file $FILE:"
echo "-----------------------------------"
printf '%s\n' "${FOUND[@]}"
printf '\n'
echo "-----------------------------------"
echo "${#NOT_FOUND[@]} web domains WITHOUT file $FILE:"
echo "-----------------------------------"
printf '%s\n' "${NOT_FOUND[@]}"
printf '\n'
echo "-----------------------------------"

