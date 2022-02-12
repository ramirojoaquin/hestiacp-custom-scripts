#!/bin/bash -l
# This script check all email domains and report if any of them doesn't have DKIM, AntiVirus Filrer or ANTISPAM filter enabled

# Arrays setting
DKIM_ERROR=()
ANTIVIRUS_ERROR=()
ANTISPAM_ERROR=()

# Users and domains loop
while read USER ; do
  while read DOMAIN ; do
    echo "Checking email configuration in $DOMAIN"
    DKIM="$(v-list-mail-domain $USER $DOMAIN | grep '^DKIM*' | awk {'print $2'})"
    ANTIVIRUS="$(v-list-mail-domain $USER $DOMAIN | grep '^ANTIVIRUS*' | awk {'print $2'})"
    ANTISPAM="$(v-list-mail-domain $USER $DOMAIN | grep '^ANTISPAM*' | awk {'print $2'})"
    if [ $DKIM = "no" ]; then
      DKIM_ERROR+=("$USER | $DOMAIN") 
    fi
    if [ $ANTIVIRUS = "no" ]; then                     
      ANTIVIRUS_ERROR+=("$USER | $DOMAIN") 
    fi
    if [ $ANTISPAM = "no" ]; then                     
      ANTISPAM_ERROR+=("$USER | $DOMAIN") 
    fi
  done < <(v-list-mail-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

printf '\n'
echo "-----------------------------------"
echo "${#DKIM_ERROR[@]} domains without DKIM:"
echo "-----------------------------------"
printf '%s\n' "${DKIM_ERROR[@]}"
printf '\n'
echo "-----------------------------------"
echo "${#ANTIVIRUS_ERROR[@]} domains without ANTIVIRUS:"
echo "-----------------------------------"
printf '%s\n' "${ANTIVIRUS_ERROR[@]}"
printf '\n'
echo "-----------------------------------"
echo "${#ANTISPAM_ERROR[@]} domains without ANTISPAM:"
echo "-----------------------------------"
printf '%s\n' "${ANTISPAM_ERROR[@]}"
printf '\n'
