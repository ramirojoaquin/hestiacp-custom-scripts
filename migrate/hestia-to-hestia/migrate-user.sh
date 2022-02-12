#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will migrate a single user from the remote server

USAGE="migrate-user.sh user [no]"

##### Validations #####

if [[ -z $1 ]]; then
  echo "!!!!! This script needs at least 1 argument: username"
  echo "---"
  echo "Usage:"
  echo $USAGE
  exit 1
fi

##### Script #####

RESTART=yes
if [[ $2 == "no" ]]; then
  RESTART=no
fi

USER=$1
HESTIA_USER_DIR=$HESTIA_USERS_DIR/$USER

echo "-------------------- Processing $USER"
echo "--- Synchronizing user config"
mkdir -p $HESTIA_USER_DIR
rsync -za --delete --info=progress2 $SOURCE_DATA_HESTIA_USERS_DIR/$USER/ $HESTIA_USER_DIR/
if ! test -f "$HESTIA_USER_DIR/user.conf"
then
  echo "!!!!! User $USER is not present in the old server. Aborting..."
  if test -d "$HESTIA_USER_DIR"
  then
    rm -rf $HESTIA_USER_DIR
  fi
  exit 1
fi

echo "- Replacing IPs and server name"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_IP_1/$IP_1/g"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_IP_2/$IP_2/g"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_IP_3/$IP_1/g"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_IP_4/$IP_1/g"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_IP_5/$IP_1/g"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_DNS_PRIMARY/$NEW_DNS_PRIMARY/g"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_DNS_SECONDARY/$NEW_DNS_SECONDARY/g"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_SERVER_HOST/$NEW_SERVER_HOST/g"
find $HESTIA_USER_DIR -type f -print0 | xargs -0 sed -i "s/$OLD_SERVER_DOMAIN/$NEW_SERVER_DOMAIN/g"

if [[ $RESTART == "yes" ]]; then
  echo "--- Rebuilding user and restarting services"
  v-rebuild-user $USER
else
  echo "--- Rebuilding user"
  v-rebuild-user $USER no
fi

# Sync home directory
echo "--- Synchronizing home dir"
echo "/home/$USER/web/"
rsync -za --delete --info=progress2 $SOURCE_DATA_HOME_DIR/$USER/web/ /home/$USER/web/
echo "/home/$USER/mail/"
rsync -za --delete --info=progress2 $SOURCE_DATA_HOME_DIR/$USER/mail/ /home/$USER/mail/
echo "/home/$USER/db_dump/"
mkdir -p /home/$USER/db_dump/
rsync -za --delete --info=progress2 $SOURCE_DATA_HOME_DIR/$USER/db_dump/ /home/$USER/db_dump/

echo "- Fixing permissions"
chown -R $USER:$USER /home/$USER/web
chown -R $USER:mail /home/$USER/mail/*
chown -R $USER:$USER /home/$USER/tmp
chmod -R 1777 /home/$USER/tmp

echo "--- Importing databases if exist"
v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}' | while read DB ; do
  DB_DIR=/home/$USER/db_dump
  DB_FILE=$DB_DIR/$DB.sql.gz
  if test -f "$DB_FILE"
  then
    mysqladmin -f drop $DB
    echo "- Creating $DB"
    mysql -e "CREATE DATABASE IF NOT EXISTS $DB"
    echo "- Importing $DB"
    gunzip < $DB_FILE | mysql $DB
  else
    echo "$DB_FILE not found in $DB_DIR"
  fi
done

echo -e "-------------------- $USER migrated

"