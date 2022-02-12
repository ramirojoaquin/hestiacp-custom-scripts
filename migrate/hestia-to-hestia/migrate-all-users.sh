#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will migrate all user from remote server

TOTAL_USERS=0
USERS_ARRAY=()

echo -e "-------------------------------------- Processing users
"

while IFS= read -r USER_DIR_NAME
do
  if [[ "$USER_DIR_NAME" != "admin" ]]
  then
    USERS_ARRAY+=($USER_DIR_NAME)
  fi
done <<< "$USERS"

for USER in "${USERS_ARRAY[@]}"
do
  if [[ "$USER" != "admin" ]]
  then
    $CURRENT_DIR/migrate-user.sh $USER no
    let "TOTAL_USERS=TOTAL_USERS+1"
  fi
done

echo "--- Restarting services"
service nginx restart
service php5.6-fpm restart
service php7.0-fpm restart
service php7.1-fpm restart
service php7.2-fpm restart
service php7.3-fpm restart
service php7.4-fpm restart
service php8.0-fpm restart
service fail2ban restart
service vsftpd restart
service mysql restart
service exim4 restart
service dovecot restart

echo -e "-------------------------------------- $TOTAL_USERS migrated users
"

