#!/bin/bash -l
# This script will send a lot of emails from a specific email to a specific email

USAGE="burn-mail-account.sh EMAILFROM PASSWORD EMAILTO"

#Validation
if [[ -z $3 ]]; then
  echo "!!!!! This script needs 3 arguments."
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

HOSTNAME=$(hostname)
EMAIL_FROM=$1
PASS=$2
EMAIL_TO=$3

for run in {1..70}
do
  sleep 0.2s
  swaks --to $EMAIL_TO --from $EMAIL_FROM --header "Subject: Test mail for testing" --body "This is a testing email, delete it" --server "$HOSTNAME" --port "587" --auth LOGIN --auth-user $EMAIL_FROM --auth-password $PASS -tls
done
