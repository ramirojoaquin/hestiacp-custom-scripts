#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script update all users emails from remote server

TOTAL_USERS=0

echo "------ Processing users"
for USER_DATA_DIR in $HESTIA_USERS_DIR/*
do
  if test -d "$USER_DATA_DIR" 
  then
    USER=$(basename $USER_DATA_DIR)
    $CURRENT_DIR/update-user-mails.sh $USER
    let "TOTAL_USERS=TOTAL_USERS+1"
  fi
done

echo "------ $TOTAL_USERS users processed"

