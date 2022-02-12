#!/bin/bash
# This script will loop over all web domains and replace a given IP with a new IP

USAGE="replace-ip-all-domains.sh OLDIP NEWIP"
if [ -z $1 ]; then
  echo "No old IP entered"
  echo $USAGE
  exit 1
fi

if [ -z $2 ]; then
  echo "No new IP entered"
  echo $USAGE
  exit 1
fi

OLD_IP=$1
NEW_IP=$2

HESTIA_USERS_DATA_DIR=/usr/local/hestia/data/users

echo "--- Procesamos usuarios"
for USER_DATA_DIR in $HESTIA_USERS_DATA_DIR/*
do
  if test -d "$USER_DATA_DIR" 
  then
    USER=$(basename $USER_DATA_DIR)
    echo $USER
    if [[ $USER != "admin" ]]; then
      HESTIA_USER_DATA_DIR=$HESTIA_USERS_DATA_DIR/$USER
      echo "------------------------------------------------------------- Procesando $USER"
      find $HESTIA_USER_DATA_DIR/dns -type f -print0 | xargs -0 sed -i "s/$OLD_IP/$NEW_IP/g"
      sed -i "s/$OLD_IP/$NEW_IP/g" $HESTIA_USER_DATA_DIR/dns.conf
      sed -i "s/$OLD_IP/$NEW_IP/g" $HESTIA_USER_DATA_DIR/web.conf
    fi
    v-rebuild-user $USER
  fi
done

echo "-------------------------------------- Todo listo"

