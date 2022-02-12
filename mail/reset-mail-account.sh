#!/bin/bash -l
# This script will reset email account password with a random string
if [ -z $1 ]; then
  echo "No email address entered"
  exit 1
fi

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

# Build emails array
IFS=',' read -a EMAILS_ARRAY <<< "$HOST_ALERTS_EMAILS"

echo -e "\n"

# Address to reset

ACCOUNT=$1
PASS=$(openssl rand -base64 16 | cut -c1-10)
DOMAIN=${ACCOUNT#*@}
ACCOUNT_NAME=${ACCOUNT%@*}
USER="$(v-search-domain-owner $DOMAIN)"

ACCOUNT_EXIST="$(v-list-mail-accounts $USER $DOMAIN | grep $ACCOUNT_NAME)"

BODY="Address $ACCOUNT from user $USER sent too many emails, and password has been reseted to protect the server.\nReview the case and communicate with the client.\n\nNew login data:\n\nUser: $USER\nAddress: $ACCOUNT\nPassword: $PASS\n"
if [[ $ACCOUNT_EXIST == *"$ACCOUNT_NAME"* ]]; then
  v-change-mail-account-password $USER $DOMAIN $ACCOUNT_NAME $PASS
  echo "Password reset success for $ACCOUNT"
  # Send alerts to each email
  for EMAIL in "${EMAILS_ARRAY[@]}"
  do
      echo $EMAIL
      echo -e $BODY | mail -s "Address sending too many emails - $ACCOUNT" -a "Content-Type: text/plain; charset=UTF-8" $EMAIL
  done
  echo "$(date +'%F %T') - $USER / $ACCOUNT / $PASS" >> /var/log/scripts/reset-mail-account.log
else
  echo "Error reseting password for $ACCOUNT"
fi
