#!/bin/bash -l
# This script list all emails redirects

for ALIASES_FILE in /home/*/conf/mail/*/aliases; do
  USER=$(echo $ALIASES_FILE | awk -F/ '{print $3}')
  DOMAIN=$(echo $ALIASES_FILE | awk -F/ '{print $6}')
  ALIASES_CONTENT=$(cat $ALIASES_FILE)
  if [[ -s $ALIASES_FILE ]]; then
    ACCOUNT_ALIASES=()
    while read -r LINE; do
      ACCOUNT=$(echo $LINE | awk -F: '{print $1}')
      ALIAS=$(echo $LINE | awk -F: '{print $2}')
      if [[ $ALIAS != '' ]]; then
        ACCOUNT_ALIASES+=("$ACCOUNT: $ALIAS")
      fi
    done <<< "$ALIASES_CONTENT"
    if [[ ! ${#ACCOUNT_ALIASES[@]} -eq 0 ]]; then
      echo "---------- $USER ($DOMAIN)"
      printf '%s\n' "${ACCOUNT_ALIASES[@]}"
      printf '\n'
    fi
  fi
done

echo "-----------------------------------"
printf '\n'
