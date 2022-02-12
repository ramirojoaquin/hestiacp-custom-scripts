#!/bin/bash -l
# This script will check a temp file where exim will store addresses sending too many emails, and then proceed to reset the password

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
ACCOUNTS_FILE=/tmp/reset-accounts

if [[ -f $ACCOUNTS_FILE ]]
then
  ACCOUNTS="$(cat $ACCOUNTS_FILE | sort -u)"
  for ACCOUNT in $ACCOUNTS
  do
    $CURRENT_DIR/reset-mail-account.sh $ACCOUNT
  done
sleep 20s
rm $ACCOUNTS_FILE
fi
