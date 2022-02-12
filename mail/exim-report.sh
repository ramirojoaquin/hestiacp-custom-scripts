#!/bin/bash -l
# This script will give a human readable report of email sent and received by the server
# By default it checks exim current log, but a log path can be given as first argument

CURRENT_DIR=`dirname $0`
if [[ $1 ]]; then
  EXIM_LOG=$1
else
  EXIM_LOG=/var/log/exim4/mainlog
fi


OUT_MAIL=`cat $EXIM_LOG | grep "=>" | grep "remote_smtp"`
OUT_MAIL_USERS=`echo "$OUT_MAIL" | sed -n 's/.*F=\([-_+=<>@a-zA-Z0-9.]*\)\(.*\)/\1/p' | sort -u`
OUT_MAIL_DOMAINS=`echo "$OUT_MAIL_USERS" | sed -n 's/.*@\([-_+=a-zA-Z0-9.]*\)\(.*\)/\1/p' | sort -u`

OUT_MAIL_COUNT=0
OUT_USER_COUNT=0
OUT_DOMAIN_COUNT=0

OUT_MAIL_USERS_RESULTS=()
OUT_MAIL_DOMAIN_RESULTS=()

while read -r USER; do
    let OUT_USER_COUNT++
    USER_OUT_MAIL=`echo "$OUT_MAIL" | grep "$USER"`
    #MAIL_TO=$(echo "$line" | awk -F " " '{print $5}')
    USER_MAIL_COUNT=0
    while read -r MAIL; do
      let USER_MAIL_COUNT++
      let OUT_MAIL_COUNT++
    done <<< "$USER_OUT_MAIL"
    OUT_MAIL_USERS_RESULTS+=("$USER_MAIL_COUNT - $USER")
done <<< "$OUT_MAIL_USERS"

while read -r DOMAIN; do
    let OUT_DOMAIN_COUNT++
    DOMAIN_OUT_MAIL=`echo "$OUT_MAIL" | grep "$DOMAIN"`          
    DOMAIN_MAIL_COUNT=0
    while read -r MAIL; do
      let DOMAIN_MAIL_COUNT++
    done <<< "$DOMAIN_OUT_MAIL"
    OUT_MAIL_DOMAIN_RESULTS+=("$DOMAIN_MAIL_COUNT - $DOMAIN")     
done <<< "$OUT_MAIL_DOMAINS" 

echo "----------------------------------------------------------"
echo "Total outgoing domains: $OUT_DOMAIN_COUNT"
echo "Total outgoing addresses: $OUT_USER_COUNT"
echo "Total outgoing emails: $OUT_MAIL_COUNT"
echo "----------------------------------------------------------"
echo "----------------------------------------------------------"
echo "----- Outgoing emails quantity per domain:"
echo "----------------------------------------------------------"
printf '%s\n' "${OUT_MAIL_DOMAIN_RESULTS[@]}" | sort -n -r
echo "----------------------------------------------------------"
echo "----- Outgoing emails quantity per address:"
echo "----------------------------------------------------------"
printf '%s\n' "${OUT_MAIL_USERS_RESULTS[@]}" | sort -n -r
echo "----------------------------------------------------------"
